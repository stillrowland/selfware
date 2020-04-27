begin;
set client_min_messages to error;
create schema contacts;

create table contacts.people (
	id serial primary key,
	name text not null constraint no_name check (length(name) > 0),
	how_to_address text,
	company text,
	city text,
	state text,
	country text,
	notes text,
	listype varchar(4),
	created_at date not null default current_date
);
create index on contacts.people(name);

create table contacts.email_address(
	id serial primary key,
	person_id integer not null references contacts.people(id) on delete cascade,
	email text unique constraint valid_email check (email ~ '\A\S+@\S+\.\S+\Z'),
	primary_email bool
);
create index on contacts.email_address(email);
create unique index idx_allow_only_one_true ON contacts.email_address(person_id, primary_email) WHERE primary_email;

CREATE VIEW contacts.contacts AS
	SELECT p.id, name, email
	FROM contacts.people p
	INNER JOIN contacts.email_address e
	ON p.id = e.person_id
	WHERE primary_email;

CREATE FUNCTION contacts.people_get(out status smallint, out js json) as $$
BEGIN 
	status := 200;
	js := coalesce((
			select json_agg(r) from (
				select id, name
				from contacts.people
				order by id
			) r
		), '[]');
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION contacts.contacts_get(out status smallint, out js json) AS $$
BEGIN
	status := 200;
	js := coalesce((
			SELECT json_agg(r) FROM (
				SELECT id, name, email
				FROM contacts.contacts
				ORDER BY id
			) r
		), '[]');
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION contacts.contact_get(integer, out status smallint, out js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT id, name, email
		FROM contacts.contacts
		WHERE id = $1
	) r;
	if js is null then
		status := 404;
		js := '{}';
	end if;
end;
$$ LANGUAGE plpgsql;

CREATE FUNCTION contacts.contact_add(text, text, out status smallint, out js json) AS $$
DECLARE
	person_id integer;
	e6 text; e7 text; e8 text; e9 text;
BEGIN
	INSERT INTO contacts.people (name)
	VALUES ($1)
	RETURNING id INTO person_id;
	INSERT INTO contacts.email_address (person_id, email, primary_email)
	VALUES (person_id, $2, True);
	SELECT x.status, x.js into status, js FROM contacts.contact_get(person_id) x;
EXCEPTION
	WHEN others THEN get stacked diagnostics e6=returned_sqlstate, e7=message_text, e8=pg_exception_detail, e9=pg_exception_context;
	js := json_build_object('code',e6,'message',e7,'detail',e8,'context',e9);
	status := 500;
END;
$$ LANGUAGE plpgsql;

COMMIT;
