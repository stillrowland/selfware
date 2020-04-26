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
	person_id integer not null references contacts.people(id) on delete cascade,
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


insert into rowland.people(name) values ('Rowland'), ('Cat');
insert into rowland.email_address(person_id, email, primary_email) values (1, 'rowland@stillclever.com', True), (1, 'test@gmail.com', False);

CREATE FUNCTION rowland.people_get(out status smallint, out js json) as $$
BEGIN 
	status := 200;
	js := coalesce((
			select json_agg(r) from (
				select id, name
				from rowland.people
				order by id
			) r
		), '[]');
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION rowland.contacts_get(out status smallint, out js json) AS $$
BEGIN
	status := 200;
	js := coalesce((
			SELECT json_agg(r) FROM (
				SELECT id, name, email
				FROM rowland.contacts
				ORDER BY id
			) r
		), '[]');
END;
$$ LANGUAGE plpgsql;

COMMIT;
