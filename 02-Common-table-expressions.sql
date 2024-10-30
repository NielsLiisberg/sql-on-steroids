-- https://www.ibm.com/docs/en/i/7.5?topic=queries-using-recursive-common-table-expressions-recursive-views

-- This is what we can work with:
select * from sqlxxl.systables;
select * from sqlxxl.employee;

-- Lets make a CTE
with emp_full_name as (
    select 
        empno, 
        rtrim(firstnme) concat ' ' concat midinit concat ' ' concat  lastname as full_name
        from sqlxxl.employee
)
select * from emp_full_name
where full_name like '%JOHN%';
