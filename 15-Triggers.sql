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
    
    -- Update only allows you to chane the name: 
    if UPDATING then 
        update sqlxxl.employee
        set  FIRSTNME = upper(sqlxxl.word(new_row.FULL_NAME , 1)) ,
             MIDINIT  = upper(sqlxxl.word(new_row.FULL_NAME , 2)) ,
             LASTNAME = upper(sqlxxl.word(new_row.FULL_NAME , 3)) 
        where empno  = new_row.empno;
           
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
    elseif DELETING then
        update sqlxxl.employee
        set    workdept = null
        where  empno  = new_row.empno;
    end if;
end;

select * sqlxxl.emp_full_name limit 1;

delete from sqlxxl.employee where empno like '9%';

