Select *
from game
;

select game_Date, team_name_home, WL_home, WL_away, team_name_away
from game
order by game_date
;
select team_name_home as team_name, count(*) as win
from game
where WL_home = 'W'
group by team_name_home
union all
select team_name_away, count(*) as win
from game
where WL_away = 'W'
group by team_name_away
order by team_name asc;

#How many games has each team won and lost in their entire history

SELECT 
    team_name, 
    SUM(win) AS total_win, 
    SUM(loss) AS total_loss
FROM (
    SELECT 
        team_name_home AS team_name, 
        COUNT(CASE WHEN wl_home = 'W' THEN 1 END) AS win, 
        COUNT(CASE WHEN wl_home = 'L' THEN 1 END) AS loss
    FROM game
    GROUP BY team_name_home

    UNION ALL

    SELECT 
        team_name_away AS team_name, 
        COUNT(CASE WHEN wl_away = 'W' THEN 1 END) AS win, 
        COUNT(CASE WHEN wl_away = 'L' THEN 1 END) AS loss
    FROM game
    GROUP BY team_name_away
) AS win_loss
GROUP BY team_name
ORDER BY total_win DESC, total_loss DESC;

#what is the best win-loss record by a team in a single season ?

select season_id, season_type,
team_name,
sum(wins)as wins, sum(losses) as losses
from
(
Select season_id, season_type, team_name_home as team_name,
sum(case when wl_home = 'W' then 1 else 0 end) as wins,
sum(case when wl_home = 'L' then 1 else 0 end) as losses
from game
group by season_id, season_type, team_name_home
union all
select
season_id, season_type,
team_name_away,
sum(case when wl_away = 'W' then 1 else 0 end) as wins,
sum(case when wl_away = 'L' then 1 else 0 end) as losses
from game
group by season_id, season_type, team_name_away
) as win_loss
group by season_id, season_type, team_name
;


	with win_loss as 
	(
	Select right(season_id,4) as season, season_type, team_name_home as team_name,
	sum(case when wl_home = 'W' then 1 else 0 end) as wins,
	sum(case when wl_home = 'L' then 1 else 0 end) as losses
	from game
	group by season, season_type, team_name_home
	union all
	select
	right(season_id,4) as season, season_type,
	team_name_away,
	sum(case when wl_away = 'W' then 1 else 0 end) as wins,
	sum(case when wl_away = 'L' then 1 else 0 end) as losses
	from game
	group by season, season_type, team_name_away
	)

	select season, team_name, season_type,
	sum(wins)as wins, sum(losses) as losses,
	round(sum(wins) / sum(wins + losses),4) as Win_PCT
	from win_loss
	group by season, team_name, season_type
	order by season
;

#Who has the worst (or the best) win - loss record by a team in a single season ?

WITH Team_Records AS (
    SELECT 
        team_name,
        SUBSTR(season_id,2,4) AS season, 
        SUM(win) AS total_win, 
        SUM(loss) AS total_loss, 
        ROUND((SUM(win) / (SUM(win) + SUM(loss))) * 100, 4) AS WLP
    FROM (
        SELECT 
            team_name_home AS team_name, 
            season_id, 
            SUM(CASE WHEN wl_home = 'W' THEN 1 ELSE 0 END) AS win, 
            SUM(CASE WHEN wl_home = 'L' THEN 1 ELSE 0 END) AS loss
        FROM game
        GROUP BY team_name_home, season_id

        UNION ALL

        SELECT 
            team_name_away AS team_name, 
            season_id, 
            SUM(CASE WHEN wl_away = 'W' THEN 1 ELSE 0 END) AS win, 
            SUM(CASE WHEN wl_away = 'L' THEN 1 ELSE 0 END) AS loss
        FROM game
        GROUP BY team_name_away, season_id
    ) AS win_loss
    GROUP BY team_name, SUBSTR(season_id,2,4)
),

Ranked_Teams AS (
    SELECT *,
           RANK() OVER (PARTITION BY season ORDER BY total_loss desc) AS rank1
    FROM Team_Records
)

SELECT team_name, season, total_win, total_loss, WLP
FROM Ranked_Teams
WHERE rank1 = 1
ORDER BY season ASC;

#Which team has the best win-loss record over a 5-year period ?
 with season_record as (SELECT 
        team_name, season, 
        SUM(wins) AS total_win, 
        SUM(losses) AS total_loss, 
        ROUND(SUM(wins) / (SUM(wins) + SUM(losses)), 4) AS WPCT
FROM (
	Select right(season_id,4) as season, season_type, team_name_home as team_name,
	sum(case when wl_home = 'W' then 1 else 0 end) as wins,
	sum(case when wl_home = 'L' then 1 else 0 end) as losses
	from game
    where season_type = 'regular season'
	group by season, season_type, team_name_home
	union all
	select
	right(season_id,4) as season, season_type,
	team_name_away,
	sum(case when wl_away = 'W' then 1 else 0 end) as wins,
	sum(case when wl_away = 'L' then 1 else 0 end) as losses
	from game
    where season_type = 'regular season'
	group by season, season_type, team_name_away
	) as win_loss
group by season, team_name),

season_5y as 
(select 
season, team_name, total_win, total_loss, WPCT,
sum(total_win) over(partition by team_name order by season
rows between 4 preceding and current row) as total_win_5y,
sum(total_loss) over(partition by team_name order by season
rows between 4 preceding and current row) as total_loss_5y,
count(*) over(partition by team_name order by season asc
rows between 4 preceding and current row) as season_included
from season_record)

select 
season, team_name, total_win, total_loss, WPCT, total_win_5y, total_loss_5y, (total_win_5y /(total_win_5y + total_loss_5y)) as WPCT_5y
from season_5y
where season_included = 5
order by WPCT_5y desc
;

#which team has had the biggest increase or decrease in wins from one season to the next 

	with wins_count as
    (select season, team_name, sum(wins) as wins, sum(losses) as losses
    from(
    Select CONVERT(RIGHT(season_id, 4), UNSIGNED) as season, season_type, team_name_home as team_name,
	sum(case when wl_home = 'W' then 1 else 0 end) as wins,
	sum(case when wl_home = 'L' then 1 else 0 end) as losses
	from game
	where season_type = 'regular season'
	group by season, season_type, team_name_home
	union all
	select
	CONVERT(RIGHT(season_id, 4), UNSIGNED) as season, season_type,
	team_name_away,
	sum(case when wl_away = 'W' then 1 else 0 end) as wins,
	sum(case when wl_away = 'L' then 1 else 0 end) as losses
	from game
	where season_type = 'regular season'
	group by season, season_type, team_name_away
    ) as win_loss
    group by season, team_name),
    
    season_with_prev as (
    select season,team_name, wins,losses, 
    lag(wins,1) over(partition by team_name order by season asc) as wins_prev_season,
    sum(wins) over(partition by team_name order by season asc
				range between 1 preceding and 1 preceding) as wins_prev_season_sum
    from wins_count)
    
    Select season, team_name, wins, wins_prev_season, wins - wins_prev_season as wins_increase
    from season_with_prev
    where wins - wins_prev_season is not null and wins_prev_season_sum is not null
    order by wins - wins_prev_season asc
    