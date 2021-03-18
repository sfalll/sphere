-- join-ы
-- декартово произведение

select *
from dota.players,dota.player_ratings
limit 20;

-- через cross join
select p.match_id,
       p.account_id,
       r.account_id,
       p.gold_spent,
       r.total_wins,
       r.total_matches
from dota.players p cross join dota.player_ratings r
limit 20;


--- inner join
select account_id,
       kills
from dota.players
where account_id > 0
order by account_id asc
limit 15;


select account_id,
       total_wins
from dota.player_ratings
where account_id > 0
order by account_id asc
limit 15;


select p.account_id,
       r.total_wins
    from dota.player_ratings r inner join dota.players p on p.account_id = r.account_id
where p.account_id > 0
order by p.account_id asc
limit 15;


-- outer join
--left join

select p.account_id,
       sum(gold_spent) as total_gold_spent,
       sum(r.total_wins) as total_wins
from dota.players p left join dota.player_ratings r using (account_id)
where p.account_id > 0
group by p.account_id;

-- right join

select p.account_id,
       sum(gold_spent) as total_gold_spent,
       sum(r.total_wins) as total_wins
from dota.player_ratings r right join dota.players p using (account_id)
where p.account_id > 0
group by p.account_id;




-- индексы
-- условие по индексу
explain analyse verbose
select *
from dota.match
where match_id < 10;

--условие без индекса
explain analyse verbose
select *
from dota.match
where first_blood_time < 10;




-- запрос 1
with cte as (
    select account_id,
           avg(deaths) as average_deaths,
           avg(kills)  as average_kills
    from dota.players
    group by account_id
    having count(match_id) > 1
)
select max(average_deaths),
       max(average_kills)
from cte;

-- запрос 2

with radiant_win as(
    SELECT *
    from dota.match
    where radiant_win = 'True'
)
select * FROM radiant_win;


-- запрос 2. Материализация CTE vs subquery
-- materialized cte

explain analyse verbose
WITH _ AS MATERIALIZED (
    SELECT * FROM dota.purchase_log WHERE time > 0
)
SELECT * FROM _ WHERE item_id = 10;

-- subquery

explain analyse verbose
select * from (
              SELECT * FROM dota.purchase_log WHERE time > 0
                  ) t
where item_id = 10;
-- not materialized cte

explain analyse verbose
WITH _ AS NOT MATERIALIZED (
    SELECT * FROM dota.purchase_log WHERE time > 0
)
SELECT * FROM _ where item_id = 10;



-- запрос 3
with matches  as materialized
         (SELECT match_id,
                 radiant_win,
                 negative_votes,
                 positive_votes
          from dota.match
         ),
details as materialized (
    SELECT match_id,
           sum(kills) as total_kills,
           sum(deaths) as total_deaths,
           sum(gold_spent) as total_gold_spent
    from dota.players
    group by match_id
    )
select *
 from matches join details on matches.match_id = details.match_id;


-- запрос 4
-- рекурсивные СТЕ, теоретический пример
with recursive  cte(n)
as (
    select 1
    union all
    select n + 1 from cte where n < 10
    )
select * from cte;

-- запрос 5
-- рекурсивные СТЕ
with recursive cte as (
    select
           min(first_blood_time) as blood_time
    from dota.match
    union all
    select
           blood_time + 10
    from cte
    where blood_time + 10  < (select avg(duration) from dota.match)
)
select blood_time
from cte;


-- Оконные функции
--OVER()
select account_id,
       match_id,
       hero_id,
       count(*) over ()
from dota.players;



-- OVER + PARTITION BY()
-- пример 1
SELECT account_id,
       match_id,
       hero_id,
       gold_spent,
       sum(gold_spent) over() as total_gold_spent,
       sum(gold_spent) over (partition by match_id) as gold_spent_per_match
from dota.players
where account_id > 0
limit 20;

-- пример 2
SELECT account_id,
       match_id,
       hero_id,
       gold_spent,
       sum(gold_spent) over() as total_gold_spent,
       sum(gold_spent) over (partition by hero_id,match_id) as gold_spent_per_match
from dota.players
where account_id > 0 and hero_id > 0
order by match_id,hero_id asc
limit 20;

--  ROW_NUMBER()
select account_id,
       match_id,
       hero_id,
       row_number() over ()
from dota.players;


-- ROW_NUMBER + сортировка значений

select account_id,
       kills,
       gold,
       row_number() over (order by kills desc) as kills_rating,
       row_number() over (order by gold desc)  as gold_rating
from dota.players
order by gold desc;


-- топ 5 игроков по колличеству убийств и золоту
with rating as (
    select account_id,
           kills,
           gold,
           row_number() over (order by kills desc) as kills_rating,
           row_number() over (order by gold desc)  as gold_rating
    from dota.players
)
select *
from rating
where (kills_rating between 1 and 5) OR (gold_rating between 1 and 5);


--Рейтинг игроков по количеству убийств и золоту среди одинаковых персонажей
select
account_id,
       kills,
       hero_id,
       gold,
       row_number() over(partition by hero_id order by kills desc) as kills_rating,
       row_number() over(partition by hero_id order by gold desc) as gold_rating
from dota.players
where hero_id > 0
order by hero_id asc, kills_rating asc;


-- функция RANK()
SELECT account_id,
       kills,
       gold_spent,
       RANK() OVER (ORDER BY gold_spent DESC) AS RankByGoldSpent,
       RANK() OVER(ORDER BY kills DESC) AS RankByKills
FROM dota.players
order by kills desc;



SELECT account_id,
       kills,
       gold_spent,
       dense_rank() OVER (ORDER BY gold_spent DESC) AS RankByGoldSpent,
       dense_rank() OVER(ORDER BY kills DESC) AS RankByKills
FROM dota.players
order by kills desc;


-- cte + оконные функции RANK()
with cte as (
    select account_id,
           count(distinct match_id) as matches,
           sum(kills)               as total_kills,
           sum(deaths)              as total_deaths
    from dota.players
    where account_id > 0
    group by account_id
),
     cte2 as (
         select *,
                case when cte.matches > 10 then 'active' else 'not_active' end as active_status
         from cte
     )
select *,
       rank() over (partition by cte2.active_status order by cte2.total_kills desc) as kill_rating
from cte2;

-- функция NTILE()
SELECT account_id,
       gold_spent,
       RANK() OVER (ORDER BY gold_spent DESC)   AS RankByGoldSpent,
       ntile(3) OVER (ORDER BY gold_spent DESC) AS Group_Number
FROM dota.players;


-- функции LAG и LEAD()
SELECT account_id,
       gold_spent,
       LAG(gold_spent, 1) OVER ()   as lag_prev_gold,
       LAG(gold_spent, -1) OVER (ORDER BY gold_spent DESC)  as lag_next_gold,
       LEAD(gold_spent, 1) OVER (ORDER BY gold_spent DESC)  as lead_next_gold,
       LEAD(gold_spent, -1) OVER (ORDER BY gold_spent DESC) as lead_prev_gold
from dota.players;


--- функция LAG(). Разница в потраченном золоте по матчам

with general_info as (
    select match_id,
           sum(gold_spent) as gold_spent
    from dota.players
    group by match_id
)
select *,
       lag(gold_spent) over (order by gold_spent desc),
       lag(gold_spent) over (order by gold_spent desc) - gold_spent as gold_diff
from general_info;


-- функция PERCENTILE_CONT()
select match_id,
       percentile_cont(0.25) within group ( order by gold_spent ) as gold_spent_percentile_25,
       percentile_cont(0.90) within group ( order by gold_spent ) as gold_spent_percentile_90
from dota.players
group by match_id;


-- межквартильный размах
select match_id,
       percentile_cont(0.75) within group ( order by gold_spent asc ) -
       percentile_cont(0.25) within group ( order by gold_spent asc ) as iqr
from dota.players
group by match_id;



