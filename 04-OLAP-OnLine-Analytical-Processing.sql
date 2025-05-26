-- OLAP -  OnLine Analytical Processing 
-- https://www.ibm.com/docs/en/i/7.5?topic=statement-using-olap-specifications

--drop table sqlxxl.account_transactions;
--truncate   sqlxxl.account_transactions;

create or replace  table sqlxxl.account_transactions ( 
    account_id int,
    transaction_id int,
    transaction_Date date,
    amount decimal ( 15,2) 
);
insert into sqlxxl.account_transactions values 
(  1 , 1 , '2024-06-01' , 1123),
(  1 , 2 , '2024-07-02' , 1234),
(  1 , 3 , '2024-08-03' , 1345),
(  2 , 1 , '2024-06-01' , 2123),
(  2 , 2 , '2024-07-02' , 2234),
(  2 , 3 , '2024-08-03' , 2345),
(  2 , 4 , '2024-09-04' , 2456);

-- First simple:  - number of rows wil OLAP
-- Normally count(*) is "group" function and can not be combined with scalar data
-- With OLAP you can - notice the "over()" that is the magic 
select 
    count(*) over() total_rows,
    ac.* 
from sqlxxl.account_transactions ac;


-- Windowed OLAP commulative sum  
select
    account_id,
    transaction_id,
    transaction_Date,
    amount,
    sum(amount) over (
        partition by account_id   
        order by account_id ,transaction_Date 
    ) as total
from sqlxxl.account_transactions
order by account_id ,transaction_Date;


-- Grouping sets and rollup
select
    case 
        when transaction_id is null and account_id is not null then 
            'Total for ' || account_id  
        when transaction_id is null and account_id is null then 
            'Grand total'
        else 
            'Detail'
    end text,
    account_id,
    transaction_id,
    transaction_Date,
    sum(amount) amount,
    grouping (account_id) group_ID -- 0=detail, 1=total
from sqlxxl.account_transactions
group by grouping sets( 
    (account_id, transaction_id , transaction_Date)  , rollup(account_id)
)
order by account_id ,transaction_id;


-- LAG/LEAD
select
    account_id,
    transaction_Date,
    amount,
    lag  (amount) over(order by account_id ,transaction_Date ) prev_amount,
    lead (amount) over(order by account_id ,transaction_Date ) next_amount
from sqlxxl.account_transactions
order by account_id ,transaction_Date;


-- all "usefull" OLAP's 
select 
    account_id ,
    transaction_Date ,
    amount,
    lag  (amount) over(partition by account_id order by account_id ,transaction_Date ) prev_amount,
    lead (amount) over(partition by account_id order by account_id ,transaction_Date ) next_amount,
    count(*)      over(partition by account_id ) counter  , -- number of rows in each group  
    dense_rank () over(order by account_id desc) group_id , -- unique id number pr group
    ntile(100)    over(order by account_id desc) n_tile   , -- number of rows divided with ntile parameter. here 100 
    row_number()  over() row_no
from sqlxxl.account_transactions
order by account_id ,transaction_Date;


-- Next level: Similar to the IBM documentation
----------------------------------------------- 
select 
    empno, 
    salary, 
    rank()       over(order by salary desc) rank_with_gaps,
    dense_rank() over(order by salary desc) rank_without_gaps,
    row_number() over(order by salary desc) row_no  
from sqlxxl.employee
fetch first 10 rows only;

select 
    workdept, 
    int(avg(salary)) as average, 
    rank()   over(order by avg(salary) desc) avg_salary, 
    ntile(3) over(order by avg(salary) desc) quantile -- Here 3 quantiles: Hight, Medium and Low
from sqlxxl.employee 
group by  workdept; 

select 
    lastname, 
    workdept, 
    bonus, 
    dense_rank() over(
        partition by workdept 
        order by bonus desc
    ) bonus_rank_in_dept 
from sqlxxl.employee
where workdept like 'E%';

select 
    row_number() over(order by order of emp) row_no,
    empno, 
    salary, 
    deptno, 
    deptname      
from (
    select 
        empno, 
        workdept, 
        salary 
    from sqlxxl.employee        
    order by salary desc     
    fetch first 5 rows only
) emp, sqlxxl.department 
where deptno = workdept;


select 
    row_number() over() row_no, 
    lastname, 
    salary,
    sum(salary) over(
        order by salary 
        range between unbounded preceding and current row
    ) rolling_total_range,
    sum(salary) over(
        order by salary 
        rows between unbounded preceding and current row
    ) rolling_total_rows,
    decimal(
        cume_dist() over (order by salary)
        ,4,3
    ) distribution
from  sqlxxl.employee
where workdept = 'D11'
order by salary;

select 
    lastname, 
    salary,
    sum(salary) over(
        order by salary
    ) rolling_total, 
    sum(salary) over(
        order by salary 
        range between 1000 preceding and 1000 following
    ) windowed_total,
    first_value(salary) over(
        order by salary 
        range between 1000 preceding and 1000 following
    ) first_value,
    last_value(salary) over(
        order by salary 
        range between 1000 preceding and 1000 following
    ) last_value
from sqlxxl.employee
where workdept = 'D11'
order by salary;

select 
    lastname, 
    salary,
    decimal(
        avg(salary) 
        over(
            order by salary 
            rows between 1 preceding and 1 following
        ), 7,2
    ) avg_salary
from sqlxxl.employee
where workdept = 'D11'
order by salary;


