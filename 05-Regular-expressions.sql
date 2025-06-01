-- https://www.ibm.com/docs/en/i/7.5?topic=queries-using-recursive-common-table-expressions-recursive-views

-- This is what we can work with:
select * from sqlxxl.systables;
select * from sqlxxl.employee;

-- regexp_count     https://www.ibm.com/docs/en/i/7.5?topic=functions-regexp-count
-- regexp_instr     https://www.ibm.com/docs/en/i/7.5?topic=functions-regexp-instr
-- regexp_substr    https://www.ibm.com/docs/en/i/7.5?topic=functions-regexp-substr
-- regexp_replace   https://www.ibm.com/docs/en/i/7.5?topic=functions-regexp-replace
-- regexp_like      https://www.ibm.com/docs/en/i/7.5?topic=predicates-regexp-like-predicate


-- https://regex101.com/
values regexp_replace ('ABCDEFG' , 'ABC' ,'abc'); 
values regexp_replace ('AMOUNT:  123,456.78 $' , '[^0-9\.]', '');

-- AI (ChatGPT) can also help with regex, but it is not always correct.
/* 
make a regex to filter out all non-numeric exept decimal poins and signs 
characters from a string usin SQL regexp_replace in Db2 for i using this 
string 'AMOUNT:  123,456.78 $' and sql "values" statement. sql in lower case.
*/
values regexp_replace('AMOUNT:  123,456.78 $', '[^0-9+\-.]+', '');

-- regexp_instr 1=Email OK , 0=Email not valid 
values regexp_instr ( 'john@gmail.com'   ,'^[a-zA-Z0-9-]+@[a-zA-Z0-9-]+\.[a-zA-Z]{2,3}$');
values regexp_instr ( 'john@gmail.cdrom' ,'^[a-zA-Z0-9-]+@[a-zA-Z0-9-]+\.[a-zA-Z]{2,3}$');
values regexp_instr ( 'john@gmail.c'     ,'^[a-zA-Z0-9-]+@[a-zA-Z0-9-]+\.[a-zA-Z]{2,3}$');
values regexp_instr ( 'john@gmail-com'   ,'^[a-zA-Z0-9-]+@[a-zA-Z0-9-]+\.[a-zA-Z]{2,3}$');

-- Or simpler, but more sloppy:
values regexp_instr ( 'john@gmail.com'   ,'^\S+@\S+\.\S+$');


-- Get the extension from a path: 
values(regexp_substr('/qibm/ProdData/Java400/bin/JavaDoc.html','(\w+)$'));

-- Count slashes:
values(regexp_count('/qibm/ProdData/Java400/bin/JavaDoc','/'));



-- Real example regexp_like - Do you have "old files" after restore?: 
Select * 
from table(object_statistics ( 'BLUEX' , '*FILE' ))
where regexp_like  (objtext , 'Old name .* in .* owned by .*');

-- Jumping the gun a bit - using regex in a stored procedure ... 
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

select * from qsys2.systables where table_text like 'Old%';

