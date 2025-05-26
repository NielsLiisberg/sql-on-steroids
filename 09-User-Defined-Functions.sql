-- https://www.ibm.com/docs/en/i/7.5?topic=statements-create-function-sql-scalar
-- Functions ( scalar functions) returns one value based on zero or more parameters:
create or replace function sqlxxl.add  (
   x int,
   y int 
)  
returns int
begin 
    return x + y;
end; 

-- So simple - does it work?
values sqlxxl.add ( 1 , 3 );

-- always use qualified named parameter where possible:
values sqlxxl.add ( x=>1 , y=>3 );

-- and parameters can arrive from another SQL statement
values sqlxxl.add ( 
    x=> (select count(*) from qsys2.services_info),
    y=> (max (5 , 6 , 7))
);

-- Lets step it up a bit: capitalize makes the first letter uppercase in the list of words 
-- Note the "deterministic" or "not deterministic" or "statement deterministic"
-- Note the "set option" for debugging
-- Note the "specific" this is the service program name ( to debug)
-- A great example to debug !!
create or replace function sqlxxl.capitalize (
   name varchar(256)
)  
returns varchar(256)
    no external action 
    deterministic 
    specific CAPITAL
    set option output=*print, commit=*none, dbgview = *source
begin
    declare temp varchar(256); 
    declare outString varchar(256); 
    declare i int;
    declare upperNext int;
    declare c char(1); 
    
    set temp = lower(name);
    set i = 1;
    set upperNext = 1;
    set outString = '';
    while i <=  length(temp) do 
       set c = substr(temp , i ,1);
       if c = ' ' then 
           set upperNext = 1;
       elseif upperNext = 1 then  
           set c  = upper(c);
           set upperNext = 0;
       end if;
       set outString = outString || c;
       set i = i +1;
    end while;   
    return outString;
end;

-- usecase 
values sqlxxl.capitalize('JOHN A JOHNSON');
values sqlxxl.capitalize('john a johnson');
values sqlxxl.capitalize('');

-- Now it can be used in our first CST - remember this?
with emp_full_name as (
    select 
        rtrim(firstnme) concat ' ' concat midinit concat ' ' concat  lastname as full_name,
        a.*
        from sqlxxl.employee a
)
select * from emp_full_name;

with emp_full_name as (
    select 
        sqlxxl.capitalize (rtrim(firstnme) concat ' ' concat midinit concat ' ' concat  lastname) as full_name,
        a.*
        from sqlxxl.employee a
)
select * from emp_full_name;

-- And perhaps make it a view - only exposing the full name:
create or replace view sqlxxl.emp_full_name as (
    select
        empno, 
        sqlxxl.capitalize (rtrim(firstnme) concat ' ' concat midinit concat ' ' concat  lastname) as full_name,
        workdept, 
        phoneno, 
        hiredate, 
        job, 
        edlevel, 
        sex, 
        birthdate, 
        salary, 
        bonus, 
        comm 
        from sqlxxl.employee
);

-- 
select *
from sqlxxl.emp_full_name;

-- And to the advanced level - we can wrap API's and incelud C-code....
-- Use MI to generarte a RFC 4122 compiant UUID / GUID 
call qsys2.ifs_write(
    path_name => '/tmp/main.c' , 
    file_ccsid => 1208, 
    overwrite => 'REPLACE',
    line =>'
{
    #include "QSYSINC/MIH/GENUUID"
    _UUID_Template_T ut;

    memset  (&ut , 0, sizeof(ut));
    ut.bytesProv = sizeof(ut);
    // ut.version = 4; --from version 7.5 this is default

    _GENUUID (&ut);
    memcpy (MAIN.UUID , ut.uuid , sizeof(ut.uuid));

} 
');


create or replace function sqlxxl.uuid (
) 
returns char (36)
    specific uuid
    external action 
    not deterministic
    set option output=*print, commit=*none, DECMPT=*PERIOD ,dbgview = *list -- *source --list
main:
begin
    
    declare uuid  char(16) for bit data default '';
    declare uuidhex char(32);
    include '/tmp/main.c';
    set uuidhex =  hex(uuid);
    return substr(uuidhex , 1 ,8) || '-' || substr(uuidhex , 9 ,4) || '-' || substr(uuidhex , 13 ,4) || '-' || substr(uuidhex , 17, 4) || '-' || substr(uuidhex , 21, 12); 
end;

-- Perfect for world-wide unique keys 
values sqlxxl.uuid  ();

-- Is it non deterministic? 
select 
    sqlxxl.uuid() uuid,
    full_name
from sqlxxl.emp_full_name;


-- and this is usefull too: BASH!! 
call qsys2.ifs_write(
    FILE_CCSID => 1208,
    OVERWRITE => 'REPLACE',
    path_name =>'/tmp/main.c',
    line  => '
#include <ifs.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <QSYSINC/H/SQLUDF>
#include <QP2SHELL.h> 

    int stmf; 
    long len;
    char tempname [256];
    char buffer [32000];
    putenv ("QIBM_USE_DESCRIPTOR_STDIO=Y");
    putenv ("QIBM_PASE_DESCRIPTOR_STDIO=B");
    
    _C_IFS_tmpnam (tempname);
    stmf  = open(tempname, O_WRONLY|O_CREAT|O_APPEND, 0600);
    dup2(stmf, STDOUT_FILENO);     
    dup2(stmf, STDERR_FILENO);     

    BASH.COMMAND.DAT[BASH.COMMAND.LEN] = 0;
    QP2SHELL ("/QOpenSys/pkgs/bin/bash" , "-c" , BASH.COMMAND.DAT);

    close(stmf);
    stmf = open(tempname, O_RDONLY , 0600);
    len  =  read (stmf , buffer , sizeof(buffer)); 
    while (len > 0) {
        long reslen;
        long rc = sqludf_append (
            &MAIN.RETVAL,
            buffer, 
            len ,
            &reslen
        ); 
        len  =  read (stmf , buffer , sizeof(buffer)); 
    }
    close  (stmf);
    unlink (tempname); 

');

create or replace function sqlxxl.bash (
    command varchar(32000)
) 
returns clob  ccsid 1208 
set option  output=*print, commit=*ur, dbgview = *source   --list
main:
begin
  declare retval clob ccsid 1208 default'';
  include '/tmp/main.c';
  return retval;
end;

-- Usecases:
---------------------------------------------
-- List content of the IFS users homedirectory
values  sqlxxl.bash ('cd /home;ls'); 

-- more readable:
select * from table(systools.split (sqlxxl.bash ('cd /home;ls'),x'25')); 


-- ensure NLS works
values  sqlxxl.bash ('echo "æøå" '); 

-- No issues with multiple calls for each row
select 
    authorization_name, 
    home_directory  , 
    sqlxxl.bash ('cd ' || home_directory || ';ls -xla') dir_list
from qsys2.user_info;














