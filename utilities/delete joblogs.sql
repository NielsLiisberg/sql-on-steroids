create or replace procedure sqlxxl.delete_joblogs  (
    in user_data char(10) default 'SQLXXL' -- Be carefull with this !! 
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
        and    outq.user_data = delete_joblogs.user_data
    do
        call qcmdexc('DLTSPLF FILE(' || spooled_file_name || ') JOB(' || job_name || ') SPLNBR(' ||  file_number || ')');
    end for;
end;

-- does it work
call sqlxxl.delete_joblogs  (
    user_data => 'SQLXXL' 
);

-- Also with out parameters ? does it work
call sqlxxl.delete_joblogs  ();
