

select * from call_Start_logs

select 'hi' 



/*
----------------------busiest route---------------------------

select origin, destination, sum(ticket_count) total_ticket_count
from
	(select * from ticket
	union all
	select airline_number, destination as origin, origin as destination, oneway_round, ticket_count
	from ticket
	where oneway_round='R') temp
group by origin, destination
order by total_ticket_count desc

--------------------familis that can get discount---------------------

select f.name, count(1)
from families f
join countries c
on f.family_size between c.min_size and c.max_size
group by f.name

-------------------------movies and ratings-----------------------

with ratings as
	(select movie_id, round(avg(rating), 0) avg_rating
	from reviews
	group by movie_id)


select *
from
	(select m.genre, m.title, r.avg_rating, ROW_NUMBER() over (partition by genre order by avg_rating desc) rn
	from ratings r
	join movies m
	on r.movie_id = m.id) temp
where rn=1

-----------words occumerd more than once-------------

select value as word, count(*) num
from namaste_python
cross apply string_split(content, ' ')
group by value
having count(*)>1

-----------------source targe-----------------------

select coalesce(s.id, t.id) identifier,
		case 
			when t.id is null then 'new in source' 
			when s.id is null then 'new in target'
			when s.name!=t.name then 'mismatch'
		end comment
from source s
full outer join target t
on s.id=t.id
where t.id is null or s.id is null or s.name!=t.name

-------------------------new customers added each month---------------

select month(order_date) order_month, count(*) customers_added
from
	(select *, ROW_NUMBER() over (partition by customer order by order_date) as rn
	from sales) temp
where rn=1
group by month(order_date)


----------------origin, destination-------------------

select f1.cid, f1.origin, f2.destination
from flights f1
join flights f2
on f1.cid=f2.cid and f1.destination=f2.origin

-----------------------match, win, lost------------------------------
with matches as
	(select team_1, count(*) matches
	from
		(select team_1 from icc_world_cup
		union all
		select team_2 from icc_world_cup) total_matches
	group by team_1),
wins as
	(select t.team_1, count(i.winner) wins 
	from 
	(select team_1 from icc_world_cup
		union
	select team_2 from icc_world_cup) t 
	left join icc_world_cup i
	on t.team_1=i.winner
	group by t.team_1)


select m.team_1 as team, m.matches, w.wins, (m.matches - w.wins) as lost
from matches m
join wins w
on m.team_1=w.team_1
------------------------child, father, mother------------------
with cte as
	(select r.c_id, 
		max((case when p.gender='F' then p.name end)) as mother,
		max((case when p.gender='M' then p.name end)) as father
	from relations r
	join people p
	on r.p_id = p.id
	group by r.c_id)

select p.name as child, c.father, c.mother
from cte c
left join people p
on c.c_id=p.id
order by child
----------------company with +ve yoy sales------------------------
with cte as
	(select *, LAG(revenue, 1) over (partition by company order by year) last_year_rev
	from company_revenue)

select company
from cte
group by company
having min(revenue-last_year_rev)>0

-------------------adult child pair-----------------

with adult as
	(select *, ROW_NUMBER() over (order by age desc) rn
	from family
	where type='adult')

, child as
	(select *, ROW_NUMBER() over (order by age asc) rn
	from family
	where type='child')

select a.person, c.person, a.age, c.age
from adult a
left join child c
on a.rn=c.rn

--------------------puzzle--------------------------
with cte as 
(select *, SUBSTRING(formula, 1, 1) fir, SUBSTRING(formula, 2, 1)sym, SUBSTRING(formula, 3, 1) sec
from input)


select i.*, 
(case when sym='+' then c.value+i.value else c.value-i.value end) as cal
from cte c
join input i
on c.sec=i.id
------------------call duration--------------------------
approach1
select * from call_start_logs;
select * from call_end_logs;

with cte as
	(select *, ROW_NUMBER() over (partition by phone_number order by start_time) rn from call_start_logs
	union all
	select *, ROW_NUMBER() over (partition by phone_number order by end_time) rn from call_end_logs)

select phone_number, max(start_time) start_time, min(start_time) end_time, DATEDIFF(MINUTE, min(start_time), max(start_time)) duration
from cte
group by phone_number, rn


approach2
select *, ROW_NUMBER() over (partition by phone_number order by start_time) temp
from call_start_logs

select *, ROW_NUMBER() over (partition by phone_number order by end_time) temp
from call_end_logs

select s.phone_number, s.start_time, e.end_time, DATEDIFF(MINUTE, s.start_time, e.end_time) duration
from
	(select *, ROW_NUMBER() over (partition by phone_number order by start_time) temp
	from call_start_logs) s
join
	(select *, ROW_NUMBER() over (partition by phone_number order by end_time) temp
	from call_end_logs) e
on s.phone_number=e.phone_number
where s.temp= e.temp

select max(s.phone_number, s.start_time, e.end_time, DATEDIFF(MINUTE, s.start_time,e.end_time) duration
from call_start_logs s
join call_end_logs e
on s.phone_number=e.phone_number 
where s.start_time<e.end_time
group by s.start_time, e.end_time

------------------max and min sal in each dept-------------------------


approach 1
with agg as
	(select dep_id, max(salary) max_sal, min(salary) min_sal
	from employee
	group by dep_id)


select e.dep_id,
max(CASE WHEN salary=max_sal THEN emp_name else null end) as max_sal,
max(CASE WHEN salary=min_sal THEN emp_name else null end) as min_sal
from employee e
inner join agg a
on e.dep_id=a.dep_id
group by e.dep_id


approach 2
with cte as (
select *, ROW_NUMBER() over (partition by dep_id order by salary desc) max_sal, ROW_NUMBER() over (partition by dep_id order by salary asc) min_sal
from employee)

select dep_id,
max(CASE WHEN max_sal=1 THEN emp_name else null end) as max_sal,
max(CASE WHEN max_sal=2 THEN emp_name else null end) as min_sal
from cte
group by dep_id

-------------emp in same dept having same salary-----------------------

select e1.*
from emp_salary e1
cross join emp_salary e2
where e1.dept_id=e2.dept_id and e1.salary=e2.salary and e1.emp_id!=e2.emp_id
order by salary

--------splitting a col airbnb---------------------

SELECT value as room_type, count(1) as num
FROM airbnb_searches
CROSS APPLY STRING_SPLIT(filter_room_types, ',')
group by value
order by num desc

------------how many inside the hospital-----------------

select emp_id
from hospital
where concat(emp_id, time) in 
	(select concat(emp_id, max(time)) 
	from hospital
	group by emp_id) 
	and action = 'in'

-----describe tables----------------------------------------------

exec sp_columns tickets

-----business days------------------------------------------------

select ticket_id, DATEDIFF(DAY, create_date, resolved_date) -
	   2*DATEDIFF(WEEK, create_date, resolved_date) -
	   count(holiday_date) business_days
from tickets
left join holidays
on holiday_date between create_date and resolved_date
group by ticket_id, create_date, resolved_date

------olympics---------------------------------------------

select gold name, count(1) medals
from events
where gold not in (
	select silver from events
	union 
	select bronze from events)
group by gold

*/