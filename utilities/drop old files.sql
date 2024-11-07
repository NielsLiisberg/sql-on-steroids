create or replace procedure  sqlxxl.drop_old_files (
    in library char(10) 
) 
specific DROPOLDF  
begin 
    declare continue handler for sqlstate  '42704', sqlstate '42809' begin end; 
    for 
        Select * 
        from table(object_statistics ( library , '*FILE' ))
        where regexp_like  (objtext , 'Old name .* in .* owned by .*')
    do
        execute immediate 'drop table ' || rtrim(objLongSchema) || '.' || rtrim(objLongName);
    end for;
end;

call sqlxxl.drop_old_files ( 'BLUEX');    
