-- Stored procedures a "just" 
-- 1) compound statements with parameters
-- 2) are stored permanently in a database schema ( or a library .. don't) 

-- Remember this compund statement? 
begin   
    declare i int default 0;
    while i < 10 do
        set i = i + 1;
        call qcmdexc ('SBMJOB CMD(CRTDTAARA DTAARA(QTEMP/DUMMY) TYPE(*LGL)) JOB(SQLXXL) JOBQ(QSYSNOMAX) LOG(4 0 *MSG)');  
    end while;
end; 

-- .. Let's make the brilliant code into a procedure:
create or replace procedure sqlxxl.produce_some_joblogs (
    in number_of_joblogs int default 10
)
begin   
    declare i int default 0;
    while i < number_of_joblogs do
        set i = i + 1;
        call qcmdexc ('SBMJOB CMD(CRTDTAARA DTAARA(QTEMP/DUMMY) TYPE(*LGL)) JOB(SQLXXL) JOBQ(QSYSNOMAX) LOG(4 0 *MSG)');  
    end while;
end; 

-- Does it work ? 
-- Note: Named and unnamed paramter ALWAYS use named parameter
call sqlxxl.produce_some_joblogs (
    number_of_joblogs => 2
);


-- Perfect 2 joblogs:
select *
from qsys2.output_queue_entries_basic
where output_queue_name = 'QEZJOBLOG'
and user_data = 'SQLXXL';


-- Now let us make the "delete joblog" compund statement a little more clever as a procedure:
-- this is the magic !! Procedural loop based on a result set!! 
-- I love the "for" statement - why?
-- 1) It is structured:
-- 2) columns are scoped within the loop aka. you don't need to declare them
-- 3) Each row from the reultset is exposed in the loop to let you do what ever 
-- 4) Be careful with the selct * - only select the columns you need 
create or replace procedure sqlxxl.delete_joblogs  (
    in days_to_keep int default 7 
) 
    specific DLTJOBLOGS  -- this i the program name, when we debug it
    language sql
    external action      -- Optimize the SQL and let i know we using the OS
    modifies sql data    -- This is not a read only
    set option dbgview = *source , output=*print , commit=*none , datfmt=*iso
begin
    for
        select *
        from   qsys2.output_queue_entries_basic outq
        where  output_queue_name = 'QEZJOBLOG'
        and    create_timestamp < now() - days_to_keep days 
    do
        call qcmdexc('DLTSPLF FILE(' || spooled_file_name || ') JOB(' || job_name || ') SPLNBR(' ||  file_number || ')');
    end for;
end;

-- does it work
call sqlxxl.delete_joblogs  (
    days_to_keep => 14 
);
-- Also without parameters? does it work
call sqlxxl.delete_joblogs  ();




