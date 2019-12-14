--Date modified  Modified By   Description 
-- 12/10/2019    Asha K       JOMSAT-134 setup gateway db container with just db, users and schema objects
--  sys user is gatewaydbsys
--and  db name is gwayregdb


\echo 'At beginning, The current database connected is '
select current_user;
SELECT current_catalog;
select current_database();


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;


-- Create admin user to manage all the roles in DB
create role gwayadmin LOGIN SUPERUSER INHERIT CREATEDB CREATEROLE REPLICATION  password 'gwayadmin';
-- create RO RW and itmcccop_admin schema admin roles with in this admin role 
\echo ' Created gwayadmin'

create role gway_ro nologin nosuperuser nocreaterole nocreatedb inherit;

create role gway_rw nologin nosuperuser nocreaterole nocreatedb inherit;
--user for schema administration , this owns the database gwayregDB and schema gwayorch
CREATE user gwayorch_admin LOGIN PASSWORD 'gwayorch_admin' inherit  ADMIN gwayadmin;
\echo ' Created gwayorch_admin'
grant gway_ro to gway_rw;
grant gway_rw to gwayadmin;
grant gway_rw to gwayorch_admin;


-- create application role: application connects as read write user and has rw role granted. schema privileges will be granted to rw role 
CREATE role gwayapp LOGIN password 'gwayapp' 
VALID UNTIL '2028-12-30 00:47:28-05';
grant gway_ro to gwayapp;

--Do we need a user that can login and has read only privileges , I think yes ?
CREATE role gwayuser LOGIN password 'gwayuser'
  VALID UNTIL '2028-12-30 00:47:28-05';
grant gway_ro to gwayuser;
  
--Asha commented as we create db admin user above CREATE USER gwayadmin WITH  LOGIN  SUPERUSER  INHERIT  CREATEDB  CREATEROLE  REPLICATION;

--create DB with owner gwayorch_admin
CREATE DATABASE gwayregdb WITH TEMPLATE = template0 ENCODING = 'UTF8' 
LC_COLLATE = 'en_US.utf8' LC_CTYPE = 'en_US.utf8' owner gwayorch_admin;
\echo ' Created  DATABASE gwayregdb'


GRANT ALL PRIVILEGES ON DATABASE gwayregdb TO gwayorch_admin, gwayadmin;
revoke all on database gwayregdb from public;
--grant all on database gwayregdb TO postgres;
--grant connect on database gwayregdb to gwayuser, gwayapp, gwayadmin, gatewaydbsys;
grant connect on database gwayregdb to gwayuser, gwayapp, gwayadmin, gatewaydbsys;
grant connect on database gwayregdb to gway_rw, gway_ro;


--------------------------------------------------------------------------------------
--connect to new db as admin user and create schemas
\echo '--------------------------------------------------------------------------------------'
select current_user;
select current_database();

\echo 'gwayregdb  created , connect to this DB '

\connect gwayregdb
set role gwayadmin;

--DB name is gwayregdb
--\echo 'Create schema now : -----------------------'
CREATE SCHEMA gwayorch authorization gwayorch_admin;
set search_path = gwayorch;
--\echo ' Created  SCHEMA gwayorch'

grant usage on schema gwayorch to gway_ro;
grant usage on schema gwayorch to gway_rw;
grant usage on schema gwayorch to gwayadmin;
GRANT CREATE ON SCHEMA gwayorch TO gwayorch_admin;

ALTER DEFAULT PRIVILEGES IN SCHEMA gwayorch GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO gwayapp;
ALTER DEFAULT PRIVILEGES IN SCHEMA gwayorch GRANT SELECT ON TABLES TO gwayuser;

alter default privileges for role gwayorch_admin in schema gwayorch grant all privileges on tables to gwayorch_admin;
alter default privileges for role gwayorch_admin in schema gwayorch grant all privileges on sequences to gwayorch_admin;
alter default privileges for role gwayorch_admin in schema gwayorch grant all privileges on functions to gwayorch_admin;

--grant crud privileges to gway_rw and read only to gway_ro
alter default privileges for role gwayorch_admin in schema gwayorch grant select, insert, update, delete on tables to gway_rw;
alter default privileges for role gwayorch_admin in schema gwayorch  grant select on tables to gway_ro;
alter default privileges for role gwayorch_admin in schema gwayorch grant usage, select, update on sequences to gway_rw;



--DB admin role can also have access
alter default privileges for role gwayadmin in schema gwayorch grant select, insert, update, delete on tables to gwayadmin WITH GRANT OPTION;
alter default privileges for role gwayadmin in schema gwayorch grant usage, select on sequences to gwayadmin WITH GRANT OPTION;

--revoke permissions for postgres sys user  on gwayregdb
REVOKE ALL PRIVILEGES ON DATABASE gwayregdb from gatewaydbsys;

\echo 'List of users created '
\du+



select current_user;
SELECT current_catalog;


\echo 'List of schemas '
\dn+

\echo 'List of users created '
\du+
------------------------------------------------------------------------
--- done db and users 


\connect gwayregdb 

\echo 'Connect as schema admin user gwayorch_admin'
set role gwayorch_admin;
set search_path to gwayorch, public;

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--\conninfo
select current_user;
SELECT current_catalog;
select current_database();

SET default_tablespace = ''; SET default_with_oids = false;

CREATE TABLE gwayorch.event_type_catalog (
    event_desc character varying(100) NOT NULL,
    created_by character varying(45),
    created_timestamp timestamp without time zone,
    updated_timestamp timestamp without time zone,
    updated_by character varying(45)
);


CREATE TABLE gwayorch.gateway_message (
    msg_pk integer NOT NULL,
    msg_id character varying(36),
    msg_project character varying(25),
    msg_src_entity character varying(25),
    msg_src_lat double precision,
    msg_src_long double precision,
    msg_timestamp timestamp without time zone,
    msg_object_type character varying(30),
    msg_processed_ind character(1),
    msg_error_code character varying(3),
    msg_error_desc character varying(100),
    msg_data text,
    created_timstamp timestamp without time zone,
    created_by character varying(45),
    updated_timestamp timestamp without time zone,
    updated_by character varying(45),
    event_desc character varying(100) NOT NULL,
    msg_urgency character varying(15),
    gway_client_id character varying(30) NOT NULL
);
COMMENT ON TABLE gwayorch.gateway_message IS 'Persist the incoming message and then use the payload data to persist data in relational format';

COMMENT ON COLUMN gwayorch.gateway_message.msg_pk IS 'Primary autogenerated key';

COMMENT ON COLUMN gwayorch.gateway_message.msg_id IS 'Unique Message Identifier from origination source';

COMMENT ON COLUMN gwayorch.gateway_message.msg_project IS 'Project Identifier	';

COMMENT ON COLUMN gwayorch.gateway_message.msg_src_entity IS 'Source Entity generatin';

COMMENT ON COLUMN gwayorch.gateway_message.msg_src_lat IS 'Latitude  where the message was generated';

COMMENT ON COLUMN gwayorch.gateway_message.msg_src_long IS 'Longitude where the message was created';

COMMENT ON COLUMN gwayorch.gateway_message.msg_timestamp IS 'Date and time when the message was generated';

COMMENT ON COLUMN gwayorch.gateway_message.msg_object_type IS 'Object Type - Data, Software Patch, Software';

COMMENT ON COLUMN gwayorch.gateway_message.msg_processed_ind IS 'Indicator Y/N value to identified if the message paload was persisted';

COMMENT ON COLUMN gwayorch.gateway_message.msg_error_code IS '3-digit Error code for processing errors';

COMMENT ON COLUMN gwayorch.gateway_message.msg_error_desc IS 'Descrption of error';

COMMENT ON COLUMN gwayorch.gateway_message.msg_data IS 'Message Payload';



CREATE SEQUENCE gwayorch.gateway_message_msg_pk_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gwayorch.gateway_message_msg_pk_seq OWNED BY gwayorch.gateway_message.msg_pk;

CREATE TABLE gwayorch.gway_client_event_registry (
    gway_client_event_pk integer NOT NULL,
    curr_gway_client_id character varying(30) NOT NULL,
    event_desc character varying(100) NOT NULL,
    fwd_gway_client_id character varying(30) NOT NULL,
    fwd_gway_client_avail_flag character varying(30),
    created_by character varying(45),
    created_timestamp timestamp without time zone,
    updated_by character varying(45),
    updated_timestamp timestamp without time zone
);


CREATE SEQUENCE gwayorch.gway_client_event_registry_gway_client_event_pk_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gwayorch.gway_client_event_registry_gway_client_event_pk_seq OWNED BY gwayorch.gway_client_event_registry.gway_client_event_pk;

CREATE TABLE gwayorch.gway_client_registry (
    gway_client_id character varying(30) NOT NULL,
    created_by character varying(45),
    created_timestamp timestamp without time zone,
    updated_by character varying(45),
    updated_timestamp timestamp without time zone,
    gway_client_name character varying(100),
    gway_client_url character varying(100),
    gway_client_user_id character varying(45),
    gway_client_password character varying(50),
    auth character varying(50),
    token character varying(100),
    http_method character varying(50),
    gway_client_type character varying(15)
);
ALTER TABLE ONLY gwayorch.gateway_message ALTER COLUMN msg_pk SET DEFAULT nextval('gwayorch.gateway_message_msg_pk_seq'::regclass);
ALTER TABLE ONLY gwayorch.gway_client_event_registry ALTER COLUMN gway_client_event_pk SET DEFAULT nextval('gwayorch.gway_client_event_registry_gway_client_event_pk_seq'::regclass);
ALTER TABLE ONLY gwayorch.event_type_catalog
    ADD CONSTRAINT event_type_catalog_pk PRIMARY KEY (event_desc);
ALTER TABLE ONLY gwayorch.gateway_message
    ADD CONSTRAINT gateway_message_pk PRIMARY KEY (msg_pk);
ALTER TABLE ONLY gwayorch.gway_client_event_registry
    ADD CONSTRAINT gway_client_event_registry_pk PRIMARY KEY (gway_client_event_pk);
ALTER TABLE ONLY gwayorch.gway_client_registry
    ADD CONSTRAINT gway_client_registry_pk PRIMARY KEY (gway_client_id);

ALTER TABLE ONLY gwayorch.gateway_message
    ADD CONSTRAINT gateway_message_event_type_catalog_fk FOREIGN KEY (event_desc) REFERENCES gwayorch.event_type_catalog(event_desc);


ALTER TABLE ONLY gwayorch.gateway_message
    ADD CONSTRAINT gateway_message_gway_client_registry_fk FOREIGN KEY (gway_client_id) REFERENCES gwayorch.gway_client_registry(gway_client_id);


ALTER TABLE ONLY gwayorch.gway_client_event_registry
    ADD CONSTRAINT gway_client_event_reg_fwd_gway_client_reg_fk FOREIGN KEY (fwd_gway_client_id) REFERENCES gwayorch.gway_client_registry(gway_client_id);


ALTER TABLE ONLY gwayorch.gway_client_event_registry
    ADD CONSTRAINT gway_client_event_registry_event_type_catalog_fk FOREIGN KEY (event_desc) REFERENCES gwayorch.event_type_catalog(event_desc);

ALTER TABLE ONLY gwayorch.gway_client_event_registry
    ADD CONSTRAINT gway_client_event_registry_gway_client_registry_fk FOREIGN KEY (curr_gway_client_id) REFERENCES gwayorch.gway_client_registry(gway_client_id);

GRANT ALL ON TABLE gwayorch.event_type_catalog TO gwayadmin WITH GRANT OPTION;

GRANT ALL ON TABLE gwayorch.gateway_message TO gwayadmin WITH GRANT OPTION;

GRANT ALL ON SEQUENCE gwayorch.gateway_message_msg_pk_seq TO gwayadmin WITH GRANT OPTION;

GRANT ALL ON TABLE gwayorch.gway_client_event_registry TO gwayadmin WITH GRANT OPTION;

GRANT ALL ON SEQUENCE gwayorch.gway_client_event_registry_gway_client_event_pk_seq TO gwayadmin WITH GRANT OPTION;

GRANT ALL ON TABLE gwayorch.gway_client_registry TO gwayadmin WITH GRANT OPTION;

