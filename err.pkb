-- err.pkb
-- project: ora-exception-handler
/* Error Package Body
   Author: Richard Pascual
   Date: 08/17/2011
   
   Note: References to UTL_FILE do _not_ work for Oracle 11g R2 XE; please see
         special branch for XE implementations of this package.
   
*/   

CREATE OR REPLACE PACKAGE BODY err
IS
   g_target   PLS_INTEGER     := c_table;
   g_file     VARCHAR2 (2000) := 'err.log';
   g_dir      VARCHAR2 (2000) := NULL;
   g_detail   VARCHAR2 (20)   := 'NO DETAIL PROVIDED';
   g_info     VARCHAR2 (20)   := 'NONE';

   PROCEDURE handle (
      errcode   IN   PLS_INTEGER := NULL,
      errmsg    IN   VARCHAR2 := NULL,
      logerr    IN   BOOLEAN := TRUE,
      reraise   IN   BOOLEAN := FALSE,
      detail    IN   VARCHAR2 := NULL,
      info      IN   VARCHAR2 := NULL      
   )
   IS
   BEGIN
      IF logerr
      THEN
         log (errcode, errmsg, detail, info);
      END IF;

      IF reraise
      THEN
         err.raise (errcode, errmsg);
      END IF;
   END;

   PROCEDURE raise (
      errcode   IN   PLS_INTEGER := NULL,
      errmsg    IN   VARCHAR2 := NULL
   )
   IS
      l_errcode   PLS_INTEGER := NVL (errcode, SQLCODE);
      l_errmsg    VARCHAR2(1000) := NVL (errmsg, SQLERRM);
   BEGIN
      IF l_errcode BETWEEN -20999 AND -20000
      THEN
         raise_application_error (l_errcode, l_errmsg);
      /* Use positive error numbers -- lots to choose from! */
      ELSIF     l_errcode > 0
            AND l_errcode NOT IN (1, 100)
      THEN
         raise_application_error (-20000, l_errcode || '-' || l_errmsg);
      /* Can't EXCEPTION_INIT -1403 */
      ELSIF l_errcode IN (100, -1403)
      THEN
         RAISE NO_DATA_FOUND;
      /* Re-raise any other exception. */
      ELSIF l_errcode != 0
      THEN
         execute immediate ('DECLARE myexc EXCEPTION; ' ||
                          '   PRAGMA EXCEPTION_INIT (myexc, ' ||
                          TO_CHAR (l_errcode) ||
                          ');' ||
                          'BEGIN  RAISE myexc; END;'
         );
      END IF;
   END;

   PROCEDURE log (
      errcode   IN   PLS_INTEGER := NULL,
      errmsg    IN   VARCHAR2 := NULL,
      detail    IN   VARCHAR2 := NULL,
      info      IN   VARCHAR2 := NULL      
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      
      l_sqlcode pls_integer := NVL (errcode, SQLCODE);
      l_sqlerrm VARCHAR2(1000) := NVL (errmsg, SQLERRM);
      l_detail  VARCHAR2(250)  := NVL (detail, g_detail);
      l_info    VARCHAR2(4000) := NVL (info, g_info);
      l_sid pls_integer := sys_context('USERENV','SID');
      
   BEGIN
      IF g_target = c_table
      THEN
         INSERT INTO errlog
                     (session_id, short_detail, more_info, errcode, errmsg, 
                      created_on, created_by)
              VALUES (
                 l_sid,
                 l_detail,
                 l_info,
                 l_sqlcode,
                 l_sqlerrm,
                 SYSDATE,
                 USER
              );
      ELSIF g_target = c_file
      THEN
         DECLARE
            fid   UTL_FILE.file_type;
         BEGIN
            fid := UTL_FILE.fopen (g_dir, g_file, 'A');
            UTL_FILE.put_line (fid,
               'Error log by ' || USER || ' at  ' ||
                  TO_CHAR (SYSDATE, 'mm/dd/yyyy')
            );
            UTL_FILE.put_line (fid, NVL (errmsg, SQLERRM));
            UTL_FILE.fclose (fid);
         EXCEPTION
            WHEN OTHERS
            THEN
               UTL_FILE.fclose (fid);
         END;
      ELSIF g_target = c_screen
      THEN
         DBMS_OUTPUT.put_line ('Error log by ' || USER || ' at  ' ||
                                  TO_CHAR (SYSDATE, 'mm/dd/yyyy')
         );
         DBMS_OUTPUT.put_line (NVL (errmsg, SQLERRM));
      END IF;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
   END;

   PROCEDURE logto (
      target   IN   PLS_INTEGER,
      dir      IN   VARCHAR2 := NULL,
      file     IN   VARCHAR2 := NULL
   )
   IS
   BEGIN
      g_target := target;
      g_file := file;
      g_dir := dir;
   END;

   FUNCTION logging_to
      RETURN PLS_INTEGER
   IS
   BEGIN
      RETURN g_target;
   END;
END;
/
