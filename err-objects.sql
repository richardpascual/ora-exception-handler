-- ora-exception-handler (err-objects.sql)
/*
   -- Richard Paascual
   -- Project Tomosoft
   -- Oracle Exception Handler, Enhanced Update
   -- 11/11/2015

ora-exception-handler: a flexible package for Oracle PL/SQL exception handling Copyright ©2015 Richard G. Pascual
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.  You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.
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
    errinfo_id  INTEGER NOT NULL,
    errlog_id   INTEGER NOT NULL,
    stack   VARCHAR2(4000),
    backtrace  VARCHAR2(4000),
    full_stack CLOB,
    full_backtrace  CLOB,
       constraint errmore_pk primary key ( errinfo_id ) );
       


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

Prompt Foreign Key Constraints on Table ERRMORE;
ALTER TABLE ERRMORE ADD (
  CONSTRAINT FK_ERRMORE__ERRLOG 
  FOREIGN KEY (ERRLOG_ID) 
  REFERENCES ERRLOG (ERRLOG_ID)
  ENABLE VALIDATE);
/

/* The following is optional, which may be helpful in providing access to this
   procedure from a reusable perspective (i.e., multiple schemas).
   
   create or replace public synonym errlog for <your-error-schema>.errlog;
   create or replace public synonym errmore for <your-error-schema>.errmore;

   create or replace public synonym err for <your-error-schema>.err;
   
*/

  
