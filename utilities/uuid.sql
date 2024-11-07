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
    ut.version = 4;

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
    firstnme
from sqlxxl.employee;


