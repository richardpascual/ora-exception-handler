-- err.pks
-- project: ora-exception-handler
/* Error Package Specification
   Author: Richard Pascual
   Date: 08/17/2011
   
   Note: References to UTL_FILE do _not_ work for Oracle 11g R2 XE; please see
         special branch for XE implementations of this package.
*/   

CREATE OR REPLACE PACKAGE mauka.err
IS
   c_table    CONSTANT PLS_INTEGER := 1;                   -- Default
   c_file     CONSTANT PLS_INTEGER := 2;
   c_screen   CONSTANT PLS_INTEGER := 3;

   PROCEDURE handle (
      errcode   IN   PLS_INTEGER := NULL,
      errmsg    IN   VARCHAR2 := NULL,
      logerr    IN   BOOLEAN := TRUE,
      reraise   IN   BOOLEAN := FALSE,
      detail    IN   VARCHAR2 := NULL,
      info      IN   VARCHAR2 := NULL
   );

   PROCEDURE raise (
      errcode   IN   PLS_INTEGER := NULL,
      errmsg    IN   VARCHAR2 := NULL
   );

   PROCEDURE log (
      errcode   IN   PLS_INTEGER := NULL,
      errmsg    IN   VARCHAR2 := NULL,
      detail    IN   VARCHAR2 := NULL,
      info      IN   VARCHAR2 := NULL
   );

   PROCEDURE logto (
      target   IN   PLS_INTEGER,
      dir      IN   VARCHAR2 := NULL,
      file     IN   VARCHAR2 := NULL
   );

   FUNCTION logging_to
      RETURN PLS_INTEGER;
END;
/

