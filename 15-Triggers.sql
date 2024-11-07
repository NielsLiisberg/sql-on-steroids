-- Triggers - Advanced using "instead of"
-- https://www.ibm.com/docs/en/i/7.5?topic=statements-create-trigger

-- Remember this view? 
select * from sqlxxl.emp_full_name;

-- The update fails because the "FULL_NAME" is a composit column.
-- "instead of" triggers comes to rescue:

select empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm from sqlxxl.employee;

-- Here we do the magic and implemnts the I/O programtically
create or replace trigger sqlxxl.emp_full_name  
    instead of UPDATE or INSERT or DELETE on sqlxxl.emp_full_name 
    referencing  NEW AS new_row OLD as old_row
for each row mode DB2ROW
    set option output=*print, commit=*none, dbgview = *source --list
begin 
    
    -- Update only allows you to change the name:
    -- NOTE: old_row.empno is the original row found - you will update
    if UPDATING then 
        update sqlxxl.employee
        set  FIRSTNME = upper(sqlxxl.word(new_row.FULL_NAME , 1)) ,
             MIDINIT  = upper(sqlxxl.word(new_row.FULL_NAME , 2)) ,
             LASTNAME = upper(sqlxxl.word(new_row.FULL_NAME , 3)) 
        where empno  = old_row.empno;
           
    -- Update only allows you to chane the name: 
    elseif INSERTING then
        insert into sqlxxl.employee ( empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm)
        values (
            /* empno = */     trim (
                                    to_char(
                                        (
                                            select 1 + ifnull(int(max(empno)) ,0) 
                                            from sqlxxl.employee
                                        )
                                      , '000000'
                                    )
                               ), 
            /* firstnme = */  upper(sqlxxl.word(new_row.FULL_NAME , 1)) ,
            /* midinit  = */  upper(sqlxxl.word(new_row.FULL_NAME , 2)) ,
            /* lastname = */  upper(sqlxxl.word(new_row.FULL_NAME , 3)) ,
            /* workdept = */  new_row.workdept ,
            /* phoneno  = */  new_row.phoneno ,
            /* hiredate = */  new_row.hiredate ,
            /* job      = */  new_row.job,
            /* edlevel  = */  new_row.edlevel ,
            /* sex      = */  new_row.sex,
            /* birthdate= */  new_row.birthdate ,
            /* salary   = */  new_row.salary ,
            /* bonus    = */  new_row.bonus ,
            /* comm     = */  new_row.comm
        );

    -- Delete - dont actually delete the row, but set the workdept to null
    -- NOTE: old_row.empno is the original row found - you will update
    elseif DELETING then
        update sqlxxl.employee
        set    workdept = null
        where  empno  = old_row.empno;
    end if;
end;

-- Let VSCode produce a template :) 
sql: select * from sqlxxl.emp_full_name limit 1;

-- Like this:
insert into sqlxxl.emp_full_name (
  FULL_NAME, WORKDEPT, PHONENO, HIREDATE, JOB, EDLEVEL, SEX, BIRTHDATE, SALARY, BONUS, COMM
) values 
  ( 'Niels N Liisberg', 'A00', '3978', '01-01-19', 'PRES', 18, 'M', null, 52750, 1000, 4220);

-- Does it work?
select * from sqlxxl.emp_full_name order by 1 desc;
select * from sqlxxl.employee order by 1 desc;

select * from sqlxxl.emp_full_name order by 1 desc;
select * from sqlxxl.employee order by 1 desc;

-- The update? 
update sqlxxl.emp_full_name 
set 
    empno       = '232323', 
    full_name   = 'Niels B Liisberg', 
    workdept    = 'XXX', 
    phoneno     = '1234', 
    hiredate    = '01-01-19', 
    job         = '', 
    edlevel     = 0, 
    sex         = '', 
    birthdate   = '01-01-64', 
    salary      = 0, 
    bonus       = 0, 
    comm        = 0 
where empno = '200341' ;


-- What about the delete:
delete from sqlxxl.emp_full_name where empno = '200341';

-- Ofcause you can set it back by acccesing the table directly
update sqlxxl.employee
set    workdept = 'A00'
where  empno  =  '200341';

-- So now we can provide a complete REST-endpoint with all: GET,PUT,POST,DELETE 
-- With an endpoint like this:
comment on table  sqlxxl.emp_full_name         is 'Employees with full names @Endpoint=empFullName @Method=GET,PUT,POST,DELETE';
comment on column sqlxxl.emp_full_name.empno   is 'Find employee by employee number  @Location=PATH,1';

-- And decomission the first implementation - that were a little risky:
drop view sqlxxl.employee_view;



