CREATE OR REPLACE PACKAGE BODY err
IS
   g_target   PLS_INTEGER     := c_table;
   g_file     VARCHAR2 (2000) := 'err.log';
   g_dir      VARCHAR2 (2000) := NULL;

   PROCEDURE handle (
      errcode   IN   PLS_INTEGER := NULL,
      errmsg    IN   VARCHAR2 := NULL,
      logerr    IN   BOOLEAN := TRUE,
      reraise   IN   BOOLEAN := FALSE
   )
   IS
   BEGIN
      IF logerr
      THEN
         log (errcode, errmsg);
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
         PLVdyn.plsql ('DECLARE myexc EXCEPTION; ' ||
                          '   PRAGMA EXCEPTION_INIT (myexc, ' ||
                          TO_CHAR (l_errcode) ||
                          ');' ||
                          'BEGIN  RAISE myexc; END;'
         );
      END IF;
   END;

   PROCEDURE log (
      errcode   IN   PLS_INTEGER := NULL,
      errmsg    IN   VARCHAR2 := NULL
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      
      l_sqlcode pls_integer := NVL (errcode, SQLCODE);
      l_sqlerrm VARCHAR2(1000) := NVL (errmsg, SQLERRM);
   BEGIN
      IF g_target = c_table
      THEN
         INSERT INTO errlog
                     (errcode, errmsg, created_on, created_by)
              VALUES (
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
