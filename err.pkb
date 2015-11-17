CREATE OR REPLACE PACKAGE BODY err
IS
/**
 *
 * ERR Package Body - An internal, universal database exception handling
 * utility
 *
 * Description:
 * This package tracks errors reported through database exception handling.
 * Errors can be reported through console output (dbms_output), table-based
 * logs, or written out to an OS level text file. VERBOSE output is available
 * to report backtrace and stack errors through a separate logging table
 * named: ERRMORE.
 *
 * Implementation:
 * GRANT select privileges to the two tables: ERRLOG and ERRMORE
 * GRANT execute on ERR to the user/schema which calls this package and
 * its procedure/function objects; a public synonym is created for these
 * objects as well, further simplifying access to the data and the package
 * functionality.
 *
 * ora-exception-handler: a flexible package for Oracle PL/SQL exception handling 
 * Copyright ©2015 Richard G. Pascual
 * This program is free software: you can redistribute it and/or modify it under 
 * the terms of the GNU General Public License as published by the Free Software 
 * Foundation, either version 3 of the License, or (at your option) any later 
 * version.  This program is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more 
 * details.  You should have received a copy of the GNU General Public License 
 * along with this program. If not, see http://www.gnu.org/licenses/.
 *
 * Author: Richard Pascual
 *
 */
   g_target     PLS_INTEGER     := c_table;
   g_file       VARCHAR2 (2000) := 'err.log';
   g_dir        VARCHAR2 (2000) := NULL;
   g_obj_name   VARCHAR2 (100)  := 'NOT DEFINED';

   TYPE t_session_data IS RECORD (
      module        v$session.module%TYPE,
      action        v$session.action%TYPE,
      client_info   v$session.client_info%TYPE
   );


   PROCEDURE handle (
      errcode   IN   PLS_INTEGER := NULL,
      errmsg    IN   VARCHAR2 := NULL,
      verbose   IN   BOOLEAN := FALSE,
      logerr    IN   BOOLEAN := TRUE,
      reraise   IN   BOOLEAN := FALSE
   )
   IS
      l_session_id   PLS_INTEGER;
      l_error_info   t_error_info;
      
   BEGIN
      l_session_id := SYS_CONTEXT ('USERENV', 'SID');

      IF verbose
      THEN
         l_error_info.full_stack := DBMS_UTILITY.format_error_stack;
         l_error_info.stack_message_length :=
                                 DBMS_LOB.getlength (l_error_info.full_stack);

         IF l_error_info.stack_message_length > 3900
         THEN
            l_error_info.stack :=
                  DBMS_LOB.SUBSTR (l_error_info.full_stack, 3900, 1)
               || '<< Error Stack Continues ... See FULL_STACK column for more detail >>';
         ELSE
            l_error_info.stack :=
               DBMS_LOB.SUBSTR (l_error_info.full_stack,
                                l_error_info.stack_message_length,
                                1
                               );
         END IF;

         l_error_info.full_backtrace := DBMS_UTILITY.format_error_backtrace;
         l_error_info.backtrace_message_length :=
                              DBMS_LOB.getlength (l_error_info.full_backtrace);

         IF l_error_info.backtrace_message_length > 3900
         THEN
            l_error_info.backtrace :=
                  DBMS_LOB.SUBSTR (l_error_info.full_backtrace, 3900, 1)
               || '<< Error Backtrace Continues ... See FULL_BACKTRACE column for more detail >>';
         ELSE
            l_error_info.backtrace :=
               DBMS_LOB.SUBSTR (l_error_info.full_backtrace,
                                l_error_info.backtrace_message_length,
                                1
                               );
         END IF;
      END IF;

      IF logerr
      THEN
         LOG (errcode, errmsg, l_session_id, l_error_info);
      END IF;

      IF reraise
      THEN
         err.RAISE (errcode, errmsg);
      END IF;
   END handle;

   PROCEDURE RAISE (errcode IN PLS_INTEGER := NULL, errmsg IN VARCHAR2 := NULL)
   IS
      l_errcode   PLS_INTEGER     := NVL (errcode, SQLCODE);
      l_errmsg    VARCHAR2 (1000) := NVL (errmsg, SQLERRM);
   BEGIN
      IF l_errcode BETWEEN -20999 AND -20000
      THEN
         raise_application_error (l_errcode, l_errmsg);
      /* Use positive error numbers -- lots to choose from! */
      ELSIF l_errcode > 0 AND l_errcode NOT IN (1, 100)
      THEN
         raise_application_error (-20000, l_errcode || '-' || l_errmsg);
      /* Can't EXCEPTION_INIT -1403 */
      ELSIF l_errcode IN (100, -1403)
      THEN
         RAISE NO_DATA_FOUND;
      /* Re-raise any other exception. */
      ELSIF l_errcode != 0
      THEN
         EXECUTE IMMEDIATE (   'DECLARE myexc EXCEPTION; '
                            || '   PRAGMA EXCEPTION_INIT (myexc, '
                            || TO_CHAR (l_errcode)
                            || ');'
                            || 'BEGIN  RAISE myexc; END;'
                           );
      END IF;
   END RAISE;

   PROCEDURE capture_session (
      session_data   OUT      t_session_data
   )
   IS
   BEGIN
      DBMS_APPLICATION_INFO.READ_CLIENT_INFO (client_info => session_data.client_info);
      DBMS_APPLICATION_INFO.READ_MODULE(module_name => session_data.module, 
         action_name => session_data.action);

   END capture_session;

   PROCEDURE LOG (
      errcode      IN   PLS_INTEGER := NULL,
      errmsg       IN   VARCHAR2 := NULL,
      session_id   IN   PLS_INTEGER := NULL,
      error_info   IN   t_error_info
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      l_session_data   t_session_data;
      l_verbosity      BOOLEAN         := FALSE;
      l_errlog_seq     PLS_INTEGER     := errlog_seq.NEXTVAL;
      l_sqlcode        PLS_INTEGER     := NVL (errcode, SQLCODE);
      l_session_id     PLS_INTEGER     := NVL (session_id, c_error_condition);
      l_sqlerrm        VARCHAR2 (1000) := NVL (errmsg, SQLERRM);
   BEGIN
      IF error_info.stack IS NOT NULL
      THEN
         l_verbosity := TRUE;
      END IF;

      capture_session (l_session_data);

      IF g_target = c_table
      THEN
         INSERT INTO errlog
                     (errlog_id, errcode, session_id,
                      module, action,
                      client_info, errmsg, created_on, created_by
                     )
              VALUES (l_errlog_seq, l_sqlcode, l_session_id,
                      l_session_data.module, l_session_data.action,
                      l_session_data.client_info, l_sqlerrm, SYSDATE, USER
                     );

         /* provision for verbose feedback/information */
         IF l_verbosity
         THEN
            INSERT INTO errmore
                        (errlog_id, stack,
                         backtrace, full_stack,
                         full_backtrace
                        )
                 VALUES (l_errlog_seq, error_info.stack,
                         error_info.backtrace, error_info.full_stack,
                         error_info.full_backtrace
                        );
         END IF;
      ELSIF g_target = c_file
      THEN
         DECLARE
            fid   UTL_FILE.file_type;
         BEGIN
            fid := UTL_FILE.fopen (g_dir, g_file, 'A');
            UTL_FILE.put_line (fid,
                                  'Error log by '
                               || USER
                               || ' at  '
                               || TO_CHAR (SYSDATE, 'mm/dd/yyyy')
                              );
            UTL_FILE.put_line (fid, NVL (errmsg, SQLERRM));

            /* provision for verbose error output */
            IF l_verbosity
            THEN
               UTL_FILE.put_line (fid, 'Error Stack: ');
               UTL_FILE.put_line (fid, TO_CHAR (error_info.full_stack));
               UTL_FILE.put_line (fid, 'Error Backtrace: ');
               UTL_FILE.put_line (fid, TO_CHAR (error_info.full_backtrace));
            END IF;

            UTL_FILE.fclose (fid);
         EXCEPTION
            WHEN OTHERS
            THEN
               UTL_FILE.fclose (fid);
         END;
      ELSIF g_target = c_screen
      THEN
         DBMS_OUTPUT.put_line (   'Error log by '
                               || USER
                               || ' at  '
                               || TO_CHAR (SYSDATE, 'mm/dd/yyyy')
                              );
         DBMS_OUTPUT.put_line (NVL (errmsg, SQLERRM));

         /* provision for detailed error output */
         IF l_verbosity
         THEN
            DBMS_OUTPUT.put_line ('Error Stack: ');
            DBMS_OUTPUT.put_line (TO_CHAR (error_info.full_stack));
            DBMS_OUTPUT.put_line ('Error Backtrace: ');
            DBMS_OUTPUT.put_line (TO_CHAR (error_info.full_backtrace));
         END IF;
      END IF;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
   END LOG;

   PROCEDURE logto (
      target   IN   PLS_INTEGER,
      dir      IN   VARCHAR2 := NULL,
      FILE     IN   VARCHAR2 := NULL
   )
   IS
   BEGIN
      g_target := target;
      g_file := FILE;
      g_dir := dir;
   END logto;

   FUNCTION logging_to
      RETURN PLS_INTEGER
   IS
   BEGIN
      RETURN g_target;
   END logging_to;
END err;
/
