-- ora-exception-handler (err-objects.sql)
/* 
   -- Richard Paascual
   -- Project Tomosoft
   -- Oracle Exception Handler, First Press
   -- 06/19/2015

*/   

ALTER SESSION SET CURRENT_SCHEMA = &1;

-- assuming you have DBA privileges or equivallent, the following call may be
-- useful initially:
-- grant execute on sys.util_file to &1;

-- DROP TABLE errlog;
-- DROP SEQUENCE errlog_seq;
-- DROP TRIGGER errlog_trbi;


CREATE TABLE errlog (
    log_id   INTEGER NOT NULL,
    session_id INTEGER NOT NULL,
    short_detail VARCHAR2(250) NOT NULL,
    more_info VARCHAR2(4000) NOT NULL,
    errcode  INTEGER NOT NULL,
    errmsg   VARCHAR2(4000) NOT NULL,
    created_on  TIMESTAMP(6) NOT NULL,
    created_by  VARCHAR2(100) NOT NULL,
       constraint errlog_pk primary key ( log_id ) );

CREATE SEQUENCE errlog_seq
   MINVALUE 1
   START WITH 1
   INCREMENT BY 1
   ORDER
   CACHE 20;
       
CREATE TRIGGER errlog_trbi
   BEFORE INSERT ON errlog
   FOR EACH ROW
   DECLARE
       l_log_id pls_integer;
   BEGIN
       l_log_id := errlog_seq.nextval;
       :new.log_id := l_log_id;
END;




/* The following is optional, which may be helpful in providing access to this
   procedure from a reusable perspective (i.e., multiple schemas).
   
   create or replace public synonym errlog for <your-error-schema>.errlog;
   create or replace public synonym err for <your-error-schema>.err;
   
*/



  

