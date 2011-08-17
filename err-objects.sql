-- ora-exception-handler (err-objects.sql)
/* Run this script first to drop and replace any existing objects created from
   previous versions or the ora-exception-handler project. Be sure to back up
   any data from errlog you wish to keep as this collection of schema objects
   are dropped completely before replacement.
   
   -- Richard Paascual
   -- Project Tomosoft
   -- Oracle Exception Handler
   -- 08/17/2011

*/   

DROP TABLE errlog;

CREATE TABLE errlog (
    errcode INTEGER,
    errmsg VARCHAR2(4000),
    created_on DATE,
    created_by VARCHAR2(100)
    );
