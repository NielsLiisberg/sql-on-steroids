﻿-- Examples of usages of the Db2 for i temporal support

create or replace table sqlxxl.department(
      deptno    char(3)       not null,
      deptname  varchar(36)   not null,
      mgrno     char(6),
      admrdept  char(3)       not null, 
      location  char(16),
      start_ts  timestamp(12) not null generated always as row begin,
      end_ts    timestamp(12) not null generated always as row end,
      ts_id     timestamp(12) generated always as transaction start id,
      period system_time (start_ts, end_ts),
      primary key (deptno)
);
      
create or replace table sqlxxl.department_hist like sqlxxl.department;


alter table sqlxxl.department add versioning use history table sqlxxl.department_hist;

select * from sqlxxl.department for system_time as of current timestamp - 6 months;


alter table sqlxxl.department drop versioning;

create or replace table sqlxxl.department (
      deptno    char(3)       not null,
      deptname  varchar(36)   not null,
      mgrno     char(6),
      admrdept  char(3)       not null, 
      location  char(16),
      turnover  dec(15 ,2),  -- now adding colum turnover  dec(15 ,2)!!!
      start_ts  timestamp(12) not null generated always as row begin,
      end_ts    timestamp(12) not null generated always as row end,
      ts_id     timestamp(12) generated always as transaction start id,
      period system_time (start_ts, end_ts),
      primary key (deptno)
);

create or replace table sqlxxl.department_hist like sqlxxl.department;

alter table sqlxxl.department add versioning use history table sqlxxl.department_hist;

select * from sqlxxl.department for system_time as of current timestamp - 6 months;
