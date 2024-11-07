-- Log a message to the joblog
--------------------------------------------------------------------------------------
call qsys2.ifs_write(
    path_name => '/tmp/main.c' , 
    file_ccsid => 1208, 
    overwrite => 'REPLACE',
    line =>
'{
  /* declare prototype for Qp0zLprintf */
  extern int Qp0zLprintf (char *format, ...);

  /* print input parameter to job log */
  Qp0zLprintf("%.*s\n", JOBLOG.TEXT.LEN, JOBLOG.TEXT.DAT);
}'
);


create or replace procedure sqlxxl.joblog (
    text varchar(256)
) 
external action 
modifies sql data 
set option output=*print, commit=*none, dbgview = *source --list
begin
    include '/tmp/main.c';
end;

-- Usecase:
---------------------------------------------
call sqlxxl.joblog('Test');    
    