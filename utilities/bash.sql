-- Run bash schell and return response as clob 
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



