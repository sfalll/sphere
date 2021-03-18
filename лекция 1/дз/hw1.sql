-- 1

SELECT COUNT(match_id) AS Count
FROM match
WHERE first_blood_time BETWEEN 61 AND 179;


-- 2

-- Сделал DISTINCT, т.к. некоторые игроки принимали участие в нескольких матчах,
-- которые удовлетворяют условию (без повторений 212 строк, с повторениями - 216)

SELECT DISTINCT account_id
FROM
    players
    INNER JOIN match USING (match_id)
WHERE (account_id) <> 0 AND (positive_votes > negative_votes)
                        AND (radiant_win = 'True');


-- 3

-- Убрал анонимных игроков, т.к. про них следующая задача

SELECT account_id, AVG(duration) AS Average_duration
FROM
    players
    INNER JOIN match USING (match_id)
WHERE account_id <> 0
GROUP BY account_id;


-- 4

SELECT SUM(gold_spent) AS Gold_spent,
       COUNT(DISTINCT hero_id) AS Unique_heroes,
       AVG(duration) AS Average_duration
FROM
    players
    INNER JOIN match USING (match_id)
WHERE account_id = 0;


-- 5

SELECT localized_name AS Name,
       COUNT(match_id) AS Matches,
       AVG(kills) AS Average_kills,
       MIN(deaths) AS Min_deaths,
       MAX(gold_spent) AS Max_spent,
       SUM(positive_votes) AS positive,
       SUM(negative_votes) AS negative
FROM
    hero_names
    INNER JOIN players USING (hero_id)
    INNER JOIN match USING (match_id)
GROUP BY  localized_name;


-- 6

SELECT DISTINCT match_id
FROM
    match
    INNER JOIN purchase_log USING (match_id)
WHERE item_id = 42 AND time > 100;


-- 7

SELECT *
FROM match, purchase_log
LIMIT 20