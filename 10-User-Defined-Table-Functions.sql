-- https://www.ibm.com/docs/en/i/7.5?topic=statements-create-function-sql-table
-- Functions ( table functions) returns a resultset based on zero or more parameters:

-- remember this? 
values  sqlxxl.bash ('cd /home;ls'); 

-- lets make a table function, to return one row pr. line in stdout
create or replace function sqlxxl.bash_line(
    command varchar(32000)
)
returns table ( 
    line varchar(1024)
)
    specific BASHROWS    -- This i the service program name, when we debug it
    language sql
    no external action   -- Optimize the SQL and let i know we stay in SQL
    reads sql data       -- This is not a read only
    set option dbgview = *source , output=*print , commit=*none , datfmt=*iso

begin
    for 
        select element 
        from table(
            systools.split (
                sqlxxl.bash (command),
                x'25'
            )
        )
    do
        pipe ( element);
    end for;
    return;
end;

-- Does it work?
select line from table (sqlxxl.bash_line('cd /home;ls'));

-- Glue it together:
select 
    authorization_name, 
    home_directory,
    line
from qsys2.user_info, table(sqlxxl.bash_line ('cd ' || home_directory || ';ls -xla') )
where home_directory > ' ';

-- This is also cool :)
-- first:
-- yum install tree
select line from table (sqlxxl.bash_line('cd /home;/QOpenSys/pkgs/bin/tree -d'));

