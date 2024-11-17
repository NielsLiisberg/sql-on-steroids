-- A sigle statment
call systools.lprintf ('Hello world');

-- This is a compund statement - a series of statements sourrounded by "begin" and "end";
begin
    call systools.lprintf ('Hello world');
end;

-- Note what happesn in the joblog....
select message_text 
from table (qsys2.joblog_info ('*')) 
order by ordinal_position desc;

-- a program in QTEMP is created :) 

-- Lets do something usefull - Clean up joblogs:
-- Lets first create a bunch of dummy joblogs:
begin   
    declare i int default 0;
    while i < 10 do
        set i = i + 1;
        call qcmdexc ('SBMJOB CMD(CRTDTAARA DTAARA(QTEMP/DUMMY) TYPE(*LGL)) JOB(SQLXXL) JOBQ(QSYSNOMAX) LOG(4 0 *MSG)');  
    end while;
end; 

-- Perfect 10 joblogs:
select *
from qsys2.output_queue_entries_basic
where output_queue_name = 'QEZJOBLOG'
and user_data = 'SQLXXL';

-- now this is the magic !! Procedural loop based on a result set!! 
-- I love the "for" statement - why?
-- 1) It is structured:
-- 2) columns are scoped within the loop aka. you don't need to declare them
-- 3) Each row from the reultset is exposed in the loop to let you do what ever  
begin
    for
        select *
        from   qsys2.output_queue_entries_basic
        where  output_queue_name = 'QEZJOBLOG'
        and    user_data = 'SQLXXL'
    do
        call qcmdexc('DLTSPLF FILE(' || spooled_file_name || ') JOB(' || job_name || ') SPLNBR(' ||  file_number || ')');
    end for;
end ;



