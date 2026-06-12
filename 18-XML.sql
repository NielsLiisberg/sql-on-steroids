-- XML:
-- https://www.ibm.com/docs/en/i/7.5?topic=programming-sql-statements-sqlxml-functions

-- https://www.nationalbanken.dk/api/currencyratesxml?lang=en
-- Note the new: qsys2.http_get: https://www.ibm.com/docs/en/i/7.5?topic=programming-http-functions-overview#rbafyhttpoverview/HTTP_SSL 
-- We will use the new: qsys2.http_get https://www.ibm.com/docs/en/i/7.5?topic=functions-http-get
-- To set up SSL: https://www.ibm.com/docs/en/i/7.5?topic=programming-http-functions-overview#rbafyhttpoverview__HTTP_SSL__title__1

-- get the clob from the internet: 
values qsys2.http_get ('https://www.nationalbanken.dk/api/currencyratesxml?lang=en');

-- You can still use the "old" Java version - 
-- But notice: You can only have ONE PASE envirinment open at the time in the job !!: 
values systools.httpGetClob ( url => 'https://www.nationalbanken.dk/api/currencyratesxml?lang=en' , httpheader => NULL);


-- First return the response as a XML data type:
values xmlparse (
    document qsys2.http_get ('https://www.nationalbanken.dk/api/currencyratesxml?lang=en') 
);



-- Now - let's "normalize" to relationel data
select * 
from xmltable(
    '/exchangerates/dailyrates/currency' 
    passing xmlparse (
        document qsys2.http_get ('https://www.nationalbanken.dk/api/currencyratesxml?lang=en') 
    )
    columns 
        ref_date        date       default null path '../@id',
        currency_code   char(3)     default null path '@code',
        desciption      varchar(64) default null path '@desc',
        exchange_rate   double      default null path '@rate'
);    

-- And put it into a MQT - materializer query table :
create or replace table sqlxxl.exchange_rates_dkk as (
    select * 
    from xmltable(
        '/exchangerates/dailyrates/currency' 
        passing xmlparse (
            document qsys2.http_get ('https://www.nationalbanken.dk/api/currencyratesxml?lang=en') 
        )
        columns 
            ref_date        date       default null path '../@id',
            currency_code   char(3)     default null path '@code',
            desciption      varchar(64) default null path '@desc',
            exchange_rate   double      default null path '@rate'
    )    
)
data initially immediate  
refresh deferred 
enable query optimization
maintained by user;

-- MQT will not work - why? Ok, so we do it by hand:
create or replace table sqlxxl.exchange_rates_dkk as (
    select 
        timestamp(now() , 0) loaded_time, 
        rates.*
    from xmltable(
        '/exchangerates/dailyrates/currency' 
        passing xmlparse (
            document qsys2.http_get ('https://www.nationalbanken.dk/api/currencyratesxml?lang=en') 
        )
        columns 
            ref_date        date   default null path '../@id',
            currency_code   char(3)     default null path '@code',
            desciption      varchar(64) default null path '@desc',
            exchange_rate   double      default null path '@rate'
    )  rates   
) with data on replace delete rows; 

-- Does it work?
select * from sqlxxl.exchange_rates_dkk;

-- Put it in a procedure:
create or replace procedure sqlxxl.get_exchange_rates_dkk  ()
    specific GETEXHRAT   -- this i the program name, when we debug it
    language sql         -- Surprise - it is SQL
    no external action   -- Optimize the SQL and let i know we using the OS
    modifies sql data    -- This is not a read only
    set option dbgview = *source , output=*print , commit=*none , datfmt=*iso
begin
    create or replace table sqlxxl.exchange_rates_dkk as (
        select 
            timestamp(now() , 0) loaded_time, 
            rates.*
        from xmltable(
            '/exchangerates/dailyrates/currency' 
            passing xmlparse (
                document qsys2.http_get ('https://www.nationalbanken.dk/api/currencyratesxml?lang=en') 
            )
            columns 
                ref_date        date   default null path '../@id',
                currency_code   char(3)     default null path '@code',
                desciption      varchar(64) default null path '@desc',
                exchange_rate   double      default null path '@rate'
        )  rates   
    ) with data on replace delete rows; 
end;

-- Does it work?
call sqlxxl.get_exchange_rates_dkk  ();
select * from sqlxxl.exchange_rates_dkk;



-- Now the other way around - produce a XML from relationel data:
select * from sqlxxl.emp_full_name;


values   
    xmlelement ( name "root" , (
        Select 
            xmlagg( 
                xmlelement ( name "row", 
                    xmlelement ( name "employeeNumber" , int(empno)),
                    xmlelement ( name "employeeName"   , full_name),
                    xmlelement ( name "workDepartment" , workdept),
                    xmlelement ( name "phoneNumber"    , phoneno),
                    xmlelement ( name "hireDate"       , hiredate),
                    xmlelement ( name "jobTitle"       , rtrim(job)),
                    xmlelement ( name "educationLevel" , edlevel),
                    xmlelement ( name "sex"            , case when sex='M' then 'Male' when sex='F' then 'Female' else 'Other' end ),
                    xmlelement ( name "birthDate"      , birthdate),
                    xmlelement ( name "salary"         , salary),
                    xmlelement ( name "bonus"          , bonus),
                    xmlelement ( name "commission"     , comm)
                ) order by empno
            )
        from sqlxxl.emp_full_name 
    ));


-- More correct: As a CLOB field with the prolog:
values  xmlserialize (
    xmlelement ( name "root" , (
        Select 
            xmlagg( 
                xmlelement ( name "row", 
                    xmlelement ( name "employeeNumber" , int(empno)),
                    xmlelement ( name "employeeName"   , full_name),
                    xmlelement ( name "workDepartment" , workdept),
                    xmlelement ( name "phoneNumber"    , phoneno),
                    xmlelement ( name "hireDate"       , hiredate),
                    xmlelement ( name "jobTitle"       , rtrim(job)),
                    xmlelement ( name "educationLevel" , edlevel),
                    xmlelement ( name "sex"            , case when sex='M' then 'Male' when sex='F' then 'Female' else 'Other' end ),
                    xmlelement ( name "birthDate"      , birthdate),
                    xmlelement ( name "salary"         , salary),
                    xmlelement ( name "bonus"          , bonus),
                    xmlelement ( name "commission"     , comm)
                ) order by empno
            )
        from sqlxxl.emp_full_name 
    ))
    as clob(1g) ccsid 1208 including xmldeclaration
);
