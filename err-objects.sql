-- ora-exception-handler (err-objects.sql)
/* Run this script first to drop and replace any existing objects created from
   previous versions or the ora-exception-handler project. Be sure to back up
   any data from errlog you wish to keep as this collection of schema objects
   are dropped completely before replacement.
   
   To install these objects, run this script in SQL Plus with the following
   argument in position one: TARGET SCHEMA where you would like the supporting
   objects to be insalled.
   
   -- Richard Paascual
   -- Project Tomosoft
   -- Oracle Exception Handler
   -- 08/17/2011

*/   

ALTER SESSION SET CURRENT_SCHEMA = &1;

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
   procedure from a reusable perspective (i.e., multiple domains).
   
   create or replace public synonym errlog for mauka.err;
   create or replace public synonym err for mauka.err;
   
*/