CREATE OR REPLACE PACKAGE err
IS
/**
 *
 * ERR Package Spec - An internal, universal database exception handling
 * utility
 *
 * Description:
 * This package tracks errors reported through Oracle exception handling.
 * Errors can be reported through console output (dbms_output), table-based
 * logs, or written out to an OS level text file. VERBOSE output is available
 * to report backtrace and stack errors through a separate logging table
 * named: ERRMORE.
 *
 * Implementation:
 * GRANT select privileges to the two tables: ERRLOG and ERRMORE
 * GRANT execute on ERR to the user/schema which calls this package and
 * its procedure/function objects.
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
   c_table             CONSTANT PLS_INTEGER := 1;                  -- Default
   c_file              CONSTANT PLS_INTEGER := 2;
   c_screen            CONSTANT PLS_INTEGER := 3;
   c_error_condition   CONSTANT PLS_INTEGER := -1;

   TYPE t_error_info IS RECORD (
      full_stack                 errmore.full_stack%TYPE,
      full_backtrace             errmore.full_backtrace%TYPE,
      stack_message_length       INTEGER,
      backtrace_message_length   INTEGER,
      stack                      errmore.stack%TYPE,
      backtrace                  errmore.backtrace%TYPE
   );

   PROCEDURE handle (
      errcode   IN   PLS_INTEGER := NULL,
      errmsg    IN   VARCHAR2 := NULL,
      verbose   IN   BOOLEAN := FALSE,
      logerr    IN   BOOLEAN := TRUE,
      reraise   IN   BOOLEAN := FALSE
   );

   PROCEDURE RAISE (errcode IN PLS_INTEGER := NULL, errmsg IN VARCHAR2 := NULL);

   PROCEDURE LOG (
      errcode      IN   PLS_INTEGER := NULL,
      errmsg       IN   VARCHAR2 := NULL,
      session_id   IN   PLS_INTEGER := NULL,
      error_info   IN   t_error_info
   );

   PROCEDURE logto (
      target   IN   PLS_INTEGER,
      dir      IN   VARCHAR2 := NULL,
      FILE     IN   VARCHAR2 := NULL
   );

   FUNCTION logging_to
      RETURN PLS_INTEGER;
END;
/
