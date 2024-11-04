-- https://www.ibm.com/docs/en/i/7.5?topic=tools-sql-error-logging-facility-self
-- This can be done individually in all programs and procedures:
-- Start monitoring sqlcode  -901 SQL-systemfejl.
set sysibmadm.selfcodes = sysibmadm.validate_self('-901'); -- SQL-systemfejl.

-- Now logging will occur in this table:
select * from qsys2.sql_error_log;

-- Can I use the general '*ERROR' on this version of the OS?
values sysibmadm.validate_self('*ERROR');

-- If it responds '*ERROR' it means the self-code is valid
-- so I can use this instead of the list
-- Now!! by setting this variable - it will be system-wide
create or replace variable sysibmadm.selfcodes varchar(256) default '*ERROR';

-- else I have to supply a list:
create or replace variable sysibmadm.selfcodes varchar(256) default '551, 552, -551, -552, 901, -901';
