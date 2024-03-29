-- creating read/write role for application_db database

CREATE ROLE application_db_rw WITH
NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS CONNECTION LIMIT -1;
COMMENT ON ROLE application_db_rw IS 'Read / write role for application_db database';

-- application_db_rw role created

-- granting read/write privileges to application_db_rw role

GRANT CONNECT ON DATABASE application_db TO application_db_rw;
GRANT USAGE ON SCHEMA public TO application_db_rw;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO application_db_rw;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO application_db_rw;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO application_db_rw;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO application_db_rw;

-- application_db_rw privileges granted

-- creating user with read / write privileges for application_db database

CREATE ROLE application_db_rw_user WITH
LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT NOREPLICATION NOBYPASSRLS CONNECTION LIMIT -1 PASSWORD NULL
IN ROLE application_db_rw;
COMMENT ON ROLE application_db_rw_user IS 'User with read / write privileges for application_db database';

-- application_db_rw_user created

-- creating read only role for application_db database

CREATE ROLE application_db_ro WITH
NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS CONNECTION LIMIT -1;
COMMENT ON ROLE application_db_ro IS 'Read only role for application_db database';

-- application_db_ro role created

-- granting read only privileges to application_db_ro role

GRANT CONNECT ON DATABASE application_db TO application_db_ro;
GRANT USAGE ON SCHEMA public TO application_db_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO application_db_ro;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO application_db_ro;

-- application_db_rw privileges granted

-- creating user with read only privileges for application_db database

CREATE ROLE application_db_ro_user WITH
LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT NOREPLICATION NOBYPASSRLS CONNECTION LIMIT -1 PASSWORD NULL
IN ROLE application_db_ro;
COMMENT ON ROLE application_db_ro_user IS 'User with read only privileges for application_db database';

-- application_db_ro_user created
