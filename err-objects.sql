-- ora-exception-handler (err-objects.sql)
/*
   -- Richard Paascual
   -- Project Tomosoft
   -- Oracle Exception Handler, Enhanced Update
   -- 11/11/2015
*/

ALTER SESSION SET CURRENT_SCHEMA = &1;

-- assuming you have DBA privileges or equivallent, the following call may be
-- useful initially:
-- grant execute on sys.util_file to &1;


CREATE TABLE ERRLOG (
    log_id   INTEGER NOT NULL,
    session_id INTEGER NOT NULL,
    short_detail VARCHAR2(250) NOT NULL,
    more_info VARCHAR2(4000) NOT NULL,
    errcode  INTEGER NOT NULL,
    errmsg   VARCHAR2(4000) NOT NULL,
    created_on  TIMESTAMP(6) NOT NULL,
    created_by  VARCHAR2(100) NOT NULL,
       constraint errlog_pk primary key ( log_id ) );



CREATE TABLE ERRMORE (
    errlog_id   INTEGER NOT NULL,
    stack   VARCHAR2(4000),
    backtrace  VARCHAR2(4000),
    full_backtrace  CLOB,
       constraint errmore_pk primary key ( errlog_id ) );
       


CREATE SEQUENCE ERRLOG_SEQ
  START WITH 1
  INCREMENT BY 1
  MAXVALUE 9999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  CACHE 20
  ORDER;


CREATE SEQUENCE ERRMORE_SEQ
  START WITH 20000
  INCREMENT BY 1
  MAXVALUE 9999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  CACHE 20
  ORDER;



DROP TRIGGER ERRLOG_TRBI;

CREATE TRIGGER ERRLOG_TRBI
   BEFORE INSERT ON errlog
   FOR EACH ROW
   DECLARE
       l_log_id pls_integer;
   BEGIN
       l_log_id := errlog_seq.nextval;
       :new.log_id := l_log_id;
END;
/



DROP TRIGGER ERRMORE_BIR;

CREATE OR REPLACE TRIGGER ERRMORE_BIR
   BEFORE INSERT
   ON ERRMORE
   FOR EACH ROW
DECLARE
   l_assigned_id   PLS_INTEGER;
BEGIN
   l_assigned_id := errmore_seq.NEXTVAL;
   :NEW.errinfo_id := l_assigned_id;
END;
/


/* The following is optional, which may be helpful in providing access to this
   procedure from a reusable perspective (i.e., multiple schemas).
   
   create or replace public synonym errlog for <your-error-schema>.errlog;
   create or replace public synonym errmore for <your-error-schema>.errmore;

   create or replace public synonym err for <your-error-schema>.err;
   
*/

  
