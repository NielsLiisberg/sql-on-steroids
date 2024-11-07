-- First build a schema to play with:
-- https://www.ibm.com/docs/en/i/7.5?topic=tables-sample

call qsys.create_sql_sample ('SQLXXL');

-- setting the schema, 
set schema sqlxxl;

-- Now you can use it qualified or unqualified
select * from sqlxxl.systables where table_type = 'T';
select * from systables        where table_type = 'T'; 


select * from employee;
select * from sqlxxl.employee;

select * from sqlxxl.org;

select * from sqlxxl.systables;
select * from sqlxxl.SYSREFCST;