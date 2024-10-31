-- Functions ( scalar functions) returns one values based on zero or more parameters:
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

-- always use qualified where possible:
values sqlxxl.add ( x=>1 , y=>3 );

-- and parameters can arrive from another SQL statement
values sqlxxl.add ( 
    x=> (select count(*) from qsys2.services_info),
    y=> (max (5 , 6 , 7))
);

-- Lets step it up a bit: capitalize makes the first letter uppercase in the list of words 
create or replace function sqlxxl.capitalize (
   name varchar(256)
)  
returns varchar(256)
    no external action 
    deterministic 
    set option output=*print, commit=*none, dbgview = *list
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







