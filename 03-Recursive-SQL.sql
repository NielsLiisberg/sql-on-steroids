-- This is what we can work with:
select * from sqlxxl.systables where table_type = 'T';
select * from sqlxxl.employee;
select * from sqlxxl.department;

-- First let's get the recurive list from administrative department and drill down

with 
dep as ( 
    select  
         -- "level" is a counter, Root will be 1. First "child" 2 etc
        level as dep_level , 
        -- top level: 
        connect_by_root deptno as dep_root, 
        -- The path all the way down: 
        sys_connect_by_path(trim(DEPTNO), ' -> ') dep_path, 
        deptno,	
        deptname, 
        mgrno, 
        admrdept
    from  sqlxxl.department a
    -- the "key" to the top - here "A00" - sometimes that is a NULL
    start with admrdept = 'A00'
    -- No cycle: 'A00' has 'A00' as parent so it would elisewise loop
    -- "prior" on left side it top-down.
    -- "prior" on right side it bottom-up.
    connect by nocycle  prior deptno =  admrdept
    -- Inside the node siblings order:
    order siblings by deptno 
)
select * from dep
-- We will see both direct and transitive connections. 
-- Therefor apply this:
-- where deptno = 'G22'
-- order by dep_level desc
-- limit 1
; 

-- Next up, the workers in each level:
with 
dep as ( 
    select  
        level as dep_level ,
        connect_by_root deptno as dep_root,
        sys_connect_by_path(trim(DEPTNO), ' -> ') dep_path,
        deptno,	
        deptname, 
        mgrno, 
        admrdept
    from  sqlxxl.department a
    start with admrdept = 'A00'
    connect by nocycle  prior deptno =  admrdept
    order siblings by deptno 
),
emp as (
    select 
        rtrim(firstnme) concat ' ' concat midinit concat ' ' concat  lastname as full_name,
        a.*
    from sqlxxl.employee a
)
select dep.* , emp.full_name, emp.salary
from dep 
left join emp on workdept = deptno; 

