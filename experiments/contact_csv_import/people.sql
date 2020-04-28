begin;
set client_min_messages to error;
drop schema if exists rowland CASCADE;
create schema rowland;

create table rowland.people (
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
create index on rowland.people(name);

create table rowland.email_address(
	id serial primary key,
	person_id integer not null references rowland.people(id) on delete cascade,
	email text unique constraint valid_email check (email ~ '\A\S+@\S+\.\S+\Z'),
	primary_email bool
);
create index on rowland.email_address(email);
create unique index idx_allow_only_one_true ON rowland.email_address(person_id, primary_email) WHERE primary_email;

CREATE VIEW rowland.contacts AS
	SELECT p.id, name, email
	FROM rowland.people p
	INNER JOIN rowland.email_address e
	ON p.id = e.person_id
	WHERE primary_email;


insert into rowland.people(name) values ('Rowland'), ('Cat'), ('Dog');
insert into rowland.email_address(person_id, email, primary_email) values (1, 'rowland@stillclever.com', True), (1, 'test@gmail.com', False);
insert into rowland.email_address(person_id, email, primary_email) values (3, 'test@test.com', True), (3, 'test@agmail.com', False);

CREATE FUNCTION rowland.contact_get(integer, out status smallint, out js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT id, name, email
		FROM rowland.contacts
		WHERE id = $1
	) r;
	if js is null then
		status := 404;
		js := '{}';
	end if;
end;
$$ LANGUAGE plpgsql;

CREATE FUNCTION rowland.contact_add(text, text, out status smallint, out js json) AS $$
DECLARE
	person_id integer;
	e6 text; e7 text; e8 text; e9 text;
BEGIN
	INSERT INTO rowland.people (name)
	VALUES ($1)
	RETURNING id INTO person_id;
	INSERT INTO rowland.email_address (person_id, email, primary_email)
	VALUES (person_id, $2, True);
	SELECT x.status, x.js into status, js FROM rowland.contact_get(person_id) x;
EXCEPTION
	WHEN others THEN get stacked diagnostics e6=returned_sqlstate, e7=message_text, e8=pg_exception_detail, e9=pg_exception_context;
	js := json_build_object('code',e6,'message',e7,'detail',e8,'context',e9);
	status := 500;
END;
$$ LANGUAGE plpgsql;

COMMIT;
