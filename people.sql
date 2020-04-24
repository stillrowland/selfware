begin;
set client_min_messages to error;
drop schema if exists contacts CASCADE;
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


insert into contacts.people(name) values ('Rowland'), ('Cat');
insert into contacts.email_address(person_id, email, primary_email) values (1, 'rowland@stillclever.com', True), (1, 'test@gmail.com', False);

COMMIT;
