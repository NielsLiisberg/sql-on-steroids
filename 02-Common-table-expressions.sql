-- https://www.ibm.com/docs/en/i/7.5?topic=queries-using-recursive-common-table-expressions-recursive-views

-- This is what we can work with:
select * from sqlxxl.systables where table_type = 'T';

select * from sqlxxl.employee;

-- Lets make a CTE that produce a full name from first, midt and last name.
with emp_full_name as (
    select 
        rtrim(firstnme) concat ' ' concat midinit concat ' ' concat  lastname as full_name,
        a.*
        from sqlxxl.employee a
)
select * from emp_full_name
where full_name like '%JOHN%';
