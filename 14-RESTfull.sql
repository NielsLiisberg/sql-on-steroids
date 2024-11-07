-- Exposing restfull services using noxDbApi
-- https://github.com/sitemule/noxDbApi

-- and use the 'sql-on-steroids.xml' config
cl:addlible icebreak;
cl:ADDICESVR SVRID(NOXDBAPI) TEXT('Views as webservices') SVRPORT(7007) HTTPPATH('/prj/noxdbAPI') WWWDFTDOC('index.html') WEBCONFIG('webConfig-sql-on-steroids.xml'); 
cl:STRICESVR SVRID(noxDbAPI);

-- Compile the noxDbAPI router router code:

cl:CRTICEPGM STMF('/prj/noxDbAPI/noxDbAPI.rpgle') SVRID(noxDbAPI);

-- My favorite "goto guy"
select * from qsys2.services_info;

-- make an "alias" in the sqlxxl schema:
create or replace view sqlxxl.services_info as 
    select * from qsys2.services_info;

-- The parameter description will be visible in the openAPI( swagger) user interface: 
-- The annotation @Method in is valid methods exposed: GET,PUT,POST,DELETE  
-- The annotation @Endpoint is the name of the endpoint and makes the view visible in the openAPI( swagger) user interface
-- The annotation @Location describes whe the parameter is found: 
--  PATH=In the path comma number of the url next to the endpoint. 
--  QUERY=Query string parameter
--  FORM=In the form  
--  BODY=In the JSON payload
comment on table  sqlxxl.services_info               is 'Services info view @Endpoint=servicesInfo';
comment on column sqlxxl.services_info.service_name  is 'Find services by name @Location=PATH,1';

-- Now our employee table: noxDbApi will only expose views for safty reasons:
create or replace view sqlxxl.employee_view  as 
    select * from sqlxxl.employee;
comment on table  sqlxxl.employee_view         is 'Employees  @Endpoint=employee @Method=GET,PUT,POST,DELETE';
comment on column sqlxxl.employee_view.empno   is 'Find employee employee number  @Location=PATH,1';

-- Try to insert an "unvalid" row: 
values qsys2.http_post (
    'http://my_ibm_i:7007/noxdbapi/sqlxxl/employee',
'{
  "empno": "999999",
  "firstnme": "John",
  "midinit": "S",
  "lastname": "johnson",
  "workdept": "A10",
  "phoneno": "1234",
  "job": "MANAGER",
  "edlevel": 1,
  "sex": "M",
  "salary": 0,
  "bonus": 0,
  "comm": 0
}');

-- So what is constraint "RED" ? 
select * from sqlxxl.systables;
select * from sqlxxl.sysrefcst;

-- Ahh - the department number - OK !!
select * from sqlxxl.department;

-- let's make an endpoint
create or replace view sqlxxl.department_view  as 
    select * from sqlxxl.department;
comment on table  sqlxxl.department_view         is 'Departments  @Endpoint=department @Method=GET';
comment on column sqlxxl.department_view.empno   is 'Find department by  department number  @Location=PATH,1';

-- Let's retry with a real department number A00: 
values qsys2.http_post (
    'http://my_ibm_i:7007/noxdbapi/sqlxxl/employee',
'{
  "empno": "999999",
  "firstnme": "John",
  "midinit": "S",
  "lastname": "johnson",
  "workdept": "A00",
  "phoneno": "1234",
  "job": "MANAGER",
  "edlevel": 1,
  "sex": "M",
  "salary": 0,
  "bonus": 0,
  "comm": 0
}');

-- Remember this view? 
select * from sqlxxl.emp_full_name;

-- now this as a endpoint:
comment on table  sqlxxl.emp_full_name         is 'Employees with full names @Endpoint=empFullName @Method=GET';
comment on column sqlxxl.emp_full_name.empno   is 'Find employee by employee number  @Location=PATH,1';

-- And note the methods in swagger / openAPI 
select * from sqlxxl.sysviews;

select * from sqlxxl.EMP_FULL_NAME for update;	    

