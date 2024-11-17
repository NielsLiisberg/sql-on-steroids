-- JSON:
-- https://www.ibm.com/docs/en/i/7.5?topic=data-using-json-table
-- Note: removal of mongo among others:
-- https://www.ibm.com/docs/en/i/7.5?topic=changes-removal-db2-i-json-store-technology-preview
------------------------------------------------------------------------------


-- Let's get some JSON data:
-- https://www.floatrates.com/
-- http://www.floatrates.com/daily/dkk.json 
-- Note the "new": qsys2.http_get: https://www.ibm.com/docs/en/i/7.5?topic=programming-http-functions-overview#rbafyhttpoverview/HTTP_SSL 
-- We will use the "new": qsys2.http_get https://www.ibm.com/docs/en/i/7.5?topic=functions-http-get
-- To set up SSL: https://www.ibm.com/docs/en/i/7.5?topic=programming-http-functions-overview#rbafyhttpoverview__HTTP_SSL__title__1

-- get the clob from the internet: 
values qsys2.http_get ('http://www.floatrates.com/daily/dkk.json');

-- You can still use the "old" Java version - 
-- But notice: You can only have ONE PASE environment open at the time in the job !!: 
values systools.httpGetClob ( url => 'http://www.floatrates.com/daily/dkk.json' , httpheader => NULL);


-- Now - let's "normalize" to relationel data
Select * 
from json_table (
    qsys2.http_get ('http://www.floatrates.com/daily/dkk.json'),
    'lax $.*'
    columns (             
        code char(3)     path '$.code',
        name varchar(32) path '$.name',
        rate float       path '$.rate'
    )
);


-- Lets convert a JSON ( on another platform ) to relational data:
create or replace function  sqlxxl.exchange_rates (
    from_currency char(3)
)
returns table ( 
    from_currency char(3),
    to_currency char(3),     
    currency_name varchar(32),
    rate float
)

    specific EXCHRATE
    statement deterministic
    reads sql data
    no external action
    set option dbgview=*source, output=*print, commit=*none, datfmt=*iso
begin
    
    return 
        Select upper(from_currency), code , name , rate 
        from json_table (
            qsys2.http_get ('http://www.floatrates.com/daily/' || lower( from_currency) || '.json'),
            'lax $.*'
            columns (             
                code char(3)     path '$.code',
                name varchar(32) path '$.name',
                rate float       path '$.rate'
            )
        );

end;

-- does it work;
select * from table  (sqlxxl.exchange_rates (from_currency => 'dkk'));
select * from table  (sqlxxl.exchange_rates (from_currency => 'eur'));

-- Now the other way arround - produce a JSON from relationel data:
select * from sqlxxl.emp_full_name;

values                               
    json_array(                          
        (
            select json_object(
                'employeeNumber' : int(empno),
                'employeeName'   : full_name,
                'workDepartment' : workdept,
                'phoneNumber'    : phoneno,
                'hireDate'       : hiredate,
                'jobTitle'       : job,
                'educationLevel' : edlevel,
                'sex'            : case when sex='M' then 'Male' when sex='F' then 'Female' else 'Other' end ,
                'birthDate'      : birthdate,
                'salary'         : salary,
                'bonus'          : bonus,
                'commission'     : comm
            )
            from sqlxxl.emp_full_name order by empno
        ) format json                       
    );