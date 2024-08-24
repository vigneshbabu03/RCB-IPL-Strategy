-- Objective Questions

-- obj 2 : What is the total number of run scored in 1st season by RCB (bonus : also include the extra runs using the extra runs table)

WITH match_detail AS 
(SELECT Match_Id , Team_1 , Team_2 , Toss_Winner , Toss_Decide ,
	   CASE WHEN Toss_Winner = 2 AND Toss_Decide = 1 THEN 2 
	        WHEN Toss_Winner = 2 AND Toss_Decide = 2 THEN 1 
			WHEN Toss_Winner !=2 AND Toss_Decide = 1 THEN 1 
			WHEN Toss_Winner !=2 AND Toss_Decide = 2 THEN 2 END AS Innings
FROM matches
WHERE Season_Id = 1 AND (Team_1 = 2 OR Team_2 = 2))
,
Runs_from_bat AS 
(SELECT SUM(bs.Runs_Scored) AS total
FROM batsman_scored bs 
JOIN match_detail md 
ON md.Match_Id = bs.Match_Id AND bs.Innings_No = md.Innings)
,
Runs_from_extra AS 
(SELECT sum(er.Extra_Runs) total
FROM extra_runs er 
JOIN match_detail md 
ON er.Match_Id = md.Match_Id AND er.Innings_No = md.Innings)


SELECT SUM(runs.total) Total_runs_by_RCB_in_Season_1
FROM
(SELECT total FROM Runs_from_bat rb 
UNION ALL
SELECT total FROM Runs_from_extra re) runs;


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- obj Q3 : How many players were more than age of 25 during season 2 ?

SELECT COUNT(Player_Name)  Age_greater_then_25
FROM (SELECT Player_Name , born_year , Second_season_year - born_year AS age 
      FROM  (SELECT  player_name , YEAR(DOB) Born_year, 
				    (SELECT Season_Year FROM season WHERE Season_ID = 2 ) AS Second_season_year
		     FROM player ) Year_deatils ) details
WHERE age > 25;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- obj 4 : How many matches did RCB win in season 1 ? 

SELECT Count(Match_Winner) Matches_win_by_RCB_in_Season1
FROM matches
WHERE Season_Id = 1 AND Match_Winner = 2;


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- obj 5 : List top 10 players according to their strike rate in last 4 seasons

WITH details AS 
(SELECT bb.Striker, COUNT(bb.Ball_Id) balls, SUM(bs.Runs_Scored) runs, 
        SUM(bs.Runs_Scored)/COUNT(bb.Ball_Id) * 100 strike_rate
FROM ball_by_ball bb
JOIN batsman_scored bs 
ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id
JOIN player p 
ON p.Player_Id = bb.Striker
WHERE bb.Match_Id IN (SELECT Match_Id FROM matches 
                      WHERE Season_Id IN (6,7,8,9))
GROUP BY bb.Striker)

SELECT p.Player_Name,d.Striker , d.balls , d.runs , d.strike_rate
FROM  Details d 
JOIN Player p 
ON p.Player_ID = d.Striker
WHERE d.balls > 100
ORDER BY d.strike_rate DESC
LIMIT 10;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- obj 6 : What is the average runs scored by each batsman considering all the seasons?

WITH detail AS 
(SELECT p.Player_Name , COUNT(DISTINCT bs.Match_Id) Matches_played , SUM(bs.Runs_Scored) runs,
	    SUM(bs.Runs_Scored)/COUNT(DISTINCT bs.Match_Id) AVG
FROM ball_by_ball bb
JOIN batsman_scored bs 
ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id
JOIN player p 
ON p.Player_Id = bb.Striker
GROUP BY p.Player_Name)

SELECT d.Player_Name , d.Matches_played , d.runs , d.AVG batting_average
FROM detail d 
ORDER BY d.AVG DESC;


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- obj 7 : What are the average wickets taken by each bowler considering all the seasons?


WITH matches_played AS 
(select bb.Bowler , COUNT(DISTINCT bb.Match_Id) matches_played
FROM ball_by_ball bb 
JOIN batsman_scored bs 
ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id AND bb.Innings_No = bs.Innings_No
GROUP BY bb.Bowler)
,
wickets_taken AS 
(select bb.Bowler , COUNT(wt.Kind_Out) wickets
FROM ball_by_ball bb 
JOIN wicket_taken wt
ON  bb.Match_Id = wt.Match_Id AND bb.Over_Id = wt.Over_Id AND bb.Ball_Id = wt.Ball_Id AND bb.Innings_No = wt.Innings_No
GROUP BY bb.Bowler)


SELECT mp.Bowler ,p.Player_Name ,  mp.matches_played , wt.wickets , wt.wickets/mp.matches_played AS bowling_average
FROM matches_played mp
JOIN wickets_taken wt 
ON mp.Bowler = wt.Bowler
JOIN player p 
ON p.Player_Id = mp.Bowler
ORDER BY wickets DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- obj 8 : List all the players who have average runs scored greater than overall average and who have taken wickets greater than overall average
-- 8a

WITH detail AS 
(SELECT p.Player_Name , COUNT(DISTINCT bs.Match_Id) Matches_played , SUM(bs.Runs_Scored) runs,
	    SUM(bs.Runs_Scored)/COUNT(DISTINCT bs.Match_Id) AVG
FROM ball_by_ball bb
JOIN batsman_scored bs 
ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id
JOIN player p 
ON p.Player_Id = bb.Striker
GROUP BY p.Player_Name)

SELECT d.Player_Name , d.Matches_played , d.runs Runs , d.AVG Batting_average
FROM detail d 
WHERE d.AVG > (SELECT SUM(d.runs)/SUM(d.Matches_played) overall_bating_avg
               FROM detail d 
               ORDER BY d.AVG DESC)
ORDER BY d.AVG DESC;

-- 8b

WITH matches_played AS 
(select bb.Bowler , COUNT(DISTINCT bb.Match_Id) matches_played
FROM ball_by_ball bb 
JOIN batsman_scored bs 
ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id AND bb.Innings_No = bs.Innings_No
GROUP BY bb.Bowler)
,
wickets_taken AS 
(select bb.Bowler , COUNT(wt.Kind_Out) wickets
FROM ball_by_ball bb 
JOIN wicket_taken wt
ON  bb.Match_Id = wt.Match_Id AND bb.Over_Id = wt.Over_Id AND bb.Ball_Id = wt.Ball_Id AND bb.Innings_No = wt.Innings_No
GROUP BY bb.Bowler)


SELECT mp.Bowler ,p.Player_Name ,  mp.matches_played , wt.wickets , wt.wickets/mp.matches_played AS bowling_average
FROM matches_played mp
JOIN wickets_taken wt 
ON mp.Bowler = wt.Bowler
JOIN player p 
ON p.Player_Id = mp.Bowler
WHERE wt.wickets/mp.matches_played > (SELECT SUM(wt.wickets)/SUM(mp.matches_played) AS wicket_average
FROM matches_played mp
JOIN wickets_taken wt 
ON mp.Bowler = wt.Bowler
JOIN player p 
ON p.Player_Id = mp.Bowler
ORDER BY wickets DESC)
ORDER BY wickets DESC;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- obj 9 : Create a table rcb_record table that shows wins and losses of RCB in an individual venue

SELECT v.Venue_Name , COUNT(CASE WHEN m.Match_Winner = 2 THEN 1 else NULL end) as Matches_won, 
                      COUNT(CASE WHEN m.Match_Winner != 2 THEN 1 else NULL end) as Matches_loss
FROM venue v 
JOIN matches m 
ON v.Venue_Id = m.Venue_Id
WHERE m.Team_1 = 2 or m.Team_2 = 2 
GROUP BY v.Venue_Name
ORDER BY Matches_won DESC;


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- obj 10 : What is the impact of bowling style on wickets taken.

select bs.Bowling_skill ,COUNT(wt.Kind_Out) wickets
FROM bowling_style bs 
JOIN player p 
ON bs.Bowling_Id = p.Bowling_skill
JOIN ball_by_ball bb 
ON bb.Bowler = p.Player_Id
JOIN wicket_taken wt
ON bb.Match_Id = wt.Match_Id AND bb.Ball_Id = wt.Ball_Id AND bb.Over_Id = wt.Over_Id
GROUP BY bs.Bowling_skill
ORDER BY wickets DESC;


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- obj 11 : Write the sql query to provide a status of whether the performance of the team better than the previous year performance on the basis of number of runs scored by the team in the season and number of wickets taken 

WITH Runs_Per_Season AS 
(SELECT s.Season_Year, SUM(b.Runs_Scored) AS Total_Runs
FROM Season s
JOIN Matches m ON s.Season_Id = m.Season_Id
JOIN Batsman_Scored b ON m.Match_Id = b.Match_Id
WHERE (m.Team_1 = 2 AND b.Innings_No = 1) OR (m.Team_2 = 2 AND b.Innings_No = 2)
GROUP BY s.Season_Year)
,
Wickets_Per_Season AS 
(SELECT s.Season_Year, COUNT(w.Player_Out) AS Total_Wickets
FROM Season s
JOIN Matches m ON s.Season_Id = m.Season_Id
JOIN Wicket_Taken w ON m.Match_Id = w.Match_Id
WHERE (m.Team_1 = 2 AND w.Innings_No = 2) OR (m.Team_2 = 2 AND w.Innings_No = 1)
GROUP BY s.Season_Year)
,
Performance AS 
(SELECT r.Season_Year, r.Total_Runs, w.Total_Wickets,
        LAG(r.Total_Runs) OVER (ORDER BY r.Season_Year) AS Prev_Season_Runs,
        LAG(w.Total_Wickets) OVER (ORDER BY w.Season_Year) AS Prev_Season_Wickets
FROM Runs_Per_Season r
JOIN Wickets_Per_Season w ON r.Season_Year = w.Season_Year
)

SELECT Season_Year, Total_Runs, Total_Wickets, Prev_Season_Runs,Prev_Season_Wickets,
       CASE WHEN Total_Runs > Prev_Season_Runs AND Total_Wickets > Prev_Season_Wickets 
       THEN 'Better' ELSE 'Worse' END AS Performance_Status
FROM Performance;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- obj 12 : 12.	Can you derive more KPIs for the team strategy if possible?

Batting
--------
WITH match_detail AS 
(SELECT Match_Id , Team_1 , Team_2 , Toss_Winner , Toss_Decide ,
	   CASE WHEN Toss_Winner = 2 AND Toss_Decide = 1 THEN 2 
	        WHEN Toss_Winner = 2 AND Toss_Decide = 2 THEN 1 
			WHEN Toss_Winner !=2 AND Toss_Decide = 1 THEN 1 
			WHEN Toss_Winner !=2 AND Toss_Decide = 2 THEN 2 END AS Innings
FROM matches
WHERE Team_1 = 2 OR Team_2 = 2)
,
Runs_from_bat AS 
(SELECT SUM(bs.Runs_Scored) AS total
FROM batsman_scored bs 
JOIN match_detail md 
ON md.Match_Id = bs.Match_Id AND bs.Innings_No = md.Innings)
-- bs.Over_Id BETWEEN 7 and 15
-- bs.Over_Id < 6  
-- bs.Over_Id > 15
,
Runs_from_extra AS 
(SELECT sum(er.Extra_Runs) total
FROM extra_runs er 
JOIN match_detail md 
ON er.Match_Id = md.Match_Id AND er.Innings_No = md.Innings)
-- bs.Over_Id BETWEEN 7 and 15
-- bs.Over_Id < 6  
-- bs.Over_Id > 15

SELECT SUM(runs.total) Total_runs_by_RCB_in_Season_1
FROM
(SELECT total FROM Runs_from_bat rb 
UNION ALL
SELECT total FROM Runs_from_extra re) runs;


Bowling
-------

WITH match_detail AS 
(SELECT Match_Id , Team_1 , Team_2 , Toss_Winner , Toss_Decide ,
	   CASE WHEN Toss_Winner = 2 AND Toss_Decide = 1 THEN 2 
	        WHEN Toss_Winner = 2 AND Toss_Decide = 2 THEN 1 
			WHEN Toss_Winner !=2 AND Toss_Decide = 1 THEN 1 
			WHEN Toss_Winner !=2 AND Toss_Decide = 2 THEN 2 END AS Innings
FROM matches
WHERE (Team_1 = 2 OR Team_2 = 2))

SELECT COUNT(wt.Kind_Out) 
FROM wicket_taken wt 
JOIN match_detail md 
ON wt.Match_Id = md.Match_Id  AND wt.Innings_No = md.Innings
-- WHERE wt.Over_Id < 7 
-- WHERE wt.Over_Id between 7 and 15 
-- WHERE wt.Over_Id > 15 


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- obj 13 : Using SQL, write a query to find out average wickets taken by each bowler in each venue. Also rank the gender according to the average value.

WITH runs_consided AS 
(SELECT v.Venue_Id , bb.Bowler , SUM(bs.Runs_Scored) runs_given
FROM matches m 
JOIN venue v ON v.Venue_Id = m.Venue_Id
JOIN ball_by_ball bb ON m.Match_Id = bb.Match_Id
JOIN batsman_scored bs ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id AND bb.Innings_No = bs.Innings_No
GROUP BY v.Venue_Id , bb.Bowler
ORDER BY v.Venue_Id)
,
wickets_taken AS 
(SELECT v.Venue_Id , bb.Bowler , COUNT(wt.Kind_Out) wickets
FROM matches m 
JOIN venue v ON v.Venue_Id = m.Venue_Id
JOIN ball_by_ball bb ON m.Match_Id = bb.Match_Id
JOIN wicket_taken wt ON  bb.Match_Id = wt.Match_Id AND bb.Over_Id = wt.Over_Id AND bb.Ball_Id = wt.Ball_Id AND bb.Innings_No = wt.Innings_No
GROUP BY v.Venue_Id , bb.Bowler
ORDER BY v.Venue_Id)

SELECT rc.Venue_Id , v.Venue_Name , rc.Bowler , p.Player_Name , rc.runs_given , wt.wickets , rc.runs_given/wt.wickets AS Bowling_AVG,
       dense_rank() OVER (ORDER BY rc.runs_given/wt.wickets) AS Ranks_by_avg_in_venue
FROM runs_consided rc 
JOIN wickets_taken wt 
ON rc.Venue_Id = wt.Venue_Id AND rc.Bowler = wt.Bowler
JOIN player p 
ON p.Player_Id = rc.Bowler
JOIN venue v 
ON v.Venue_Id = rc.Venue_Id;


-----------------------------------------------------------------------------------

-- obj 14 : Which of the given players have consistently performed well in past seasons? (will you use any visualisation to solve the problem)

-- consistence batter's

WITH detail AS 
(SELECT p.Player_Name , m.Season_Id, COUNT(DISTINCT bs.Match_Id) Matches_played , SUM(bs.Runs_Scored) runs,
	    SUM(bs.Runs_Scored)/COUNT(DISTINCT bs.Match_Id) AVG
FROM ball_by_ball bb
JOIN batsman_scored bs 
ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id
JOIN player p 
ON p.Player_Id = bb.Striker
join matches m 
on m.Match_Id = bb.Match_Id
GROUP BY p.Player_Name,m.Season_Id)

SELECT Player_Name , COUNT(*) consistence
FROM 
(SELECT d.Player_Name ,d.Season_Id , d.Matches_played , d.runs , d.AVG batting_average
FROM detail d 
WHERE d.runs >= 700) A 
GROUP BY Player_Name
HAVING COUNT(*) >=  4;


-- consistence Bowler's

WITH runs_consided AS 
(select bb.Bowler , m.Season_Id ,SUM(bs.Runs_Scored) runs_given
FROM ball_by_ball bb 
JOIN batsman_scored bs 
ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id AND bb.Innings_No = bs.Innings_No
JOIN matches m 
ON m.Match_Id = bb.Match_Id
GROUP BY bb.Bowler , m.Season_Id)
,
wickets_taken AS 
(select bb.Bowler , m.Season_Id  ,COUNT(wt.Kind_Out) wickets
FROM ball_by_ball bb 
JOIN wicket_taken wt
ON  bb.Match_Id = wt.Match_Id AND bb.Over_Id = wt.Over_Id AND bb.Ball_Id = wt.Ball_Id AND bb.Innings_No = wt.Innings_No
JOIN matches m 
ON m.Match_Id= bb.Match_Id
GROUP BY bb.Bowler , m.Season_Id)


SELECT Player_Name , COUNT(*)
FROM
(SELECT p.Player_Name,rc.Season_Id ,rc.runs_given , wt.wickets , rc.runs_given / wt.wickets AS bowling_average
FROM runs_consided rc 
JOIN wickets_taken wt 
ON rc.Bowler = wt.Bowler AND rc.Season_Id = wt.Season_Id
JOIN player p 
ON p.Player_Id = rc.Bowler
WHERE wt.wickets >= 15) A 
GROUP BY Player_Name
HAVING count(*) >= 4;


-- ALL rounder consistence

-- bat

WITH detail AS 
(SELECT p.Player_Name , m.Season_Id, COUNT(DISTINCT bs.Match_Id) Matches_played , SUM(bs.Runs_Scored) runs,
	    SUM(bs.Runs_Scored)/COUNT(DISTINCT bs.Match_Id) AVG
FROM ball_by_ball bb
JOIN batsman_scored bs 
ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id
JOIN player p 
ON p.Player_Id = bb.Striker
join matches m 
on m.Match_Id = bb.Match_Id
GROUP BY p.Player_Name,m.Season_Id)

SELECT Player_Name , COUNT(*) consistence
FROM 
(SELECT d.Player_Name ,d.Season_Id , d.Matches_played , d.runs , d.AVG batting_average
FROM detail d 
WHERE d.runs >= 400) A 
GROUP BY Player_Name
HAVING COUNT(*) >=  4;

-- bowl

WITH runs_consided AS 
(select bb.Bowler , m.Season_Id ,SUM(bs.Runs_Scored) runs_given
FROM ball_by_ball bb 
JOIN batsman_scored bs 
ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id AND bb.Innings_No = bs.Innings_No
JOIN matches m 
ON m.Match_Id = bb.Match_Id
GROUP BY bb.Bowler , m.Season_Id)
,
wickets_taken AS 
(select bb.Bowler , m.Season_Id  ,COUNT(wt.Kind_Out) wickets
FROM ball_by_ball bb 
JOIN wicket_taken wt
ON  bb.Match_Id = wt.Match_Id AND bb.Over_Id = wt.Over_Id AND bb.Ball_Id = wt.Ball_Id AND bb.Innings_No = wt.Innings_No
JOIN matches m 
ON m.Match_Id= bb.Match_Id
GROUP BY bb.Bowler , m.Season_Id)


SELECT Player_Name , COUNT(*)
FROM
(SELECT p.Player_Name,rc.Season_Id ,rc.runs_given , wt.wickets , rc.runs_given / wt.wickets AS bowling_average
FROM runs_consided rc 
JOIN wickets_taken wt 
ON rc.Bowler = wt.Bowler AND rc.Season_Id = wt.Season_Id
JOIN player p 
ON p.Player_Id = rc.Bowler
WHERE wt.wickets >= 8) A 
GROUP BY Player_Name
HAVING count(*) >= 4;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- obj 15 : Are there players whose performance is more suited to specific venues or conditions? (how would you present this using charts?) 

-- bat

WITH detail AS 
(SELECT m.Venue_Id , p.Player_Name , COUNT(DISTINCT bs.Match_Id) Matches_played ,
		SUM(bs.Runs_Scored) runs, SUM(bs.Runs_Scored)/COUNT(DISTINCT bs.Match_Id) batting_avg 
FROM ball_by_ball bb
JOIN batsman_scored bs 
ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id
JOIN matches m 
ON m.Match_Id = bb.Match_Id
JOIN player p 
ON p.Player_Id = bb.Striker
GROUP BY   m.Venue_Id , p.Player_Name)
,
detail_by_rank AS
(SELECT d.Venue_Id , d.Player_Name , d.Matches_played , d.runs , d.batting_avg , 
        dense_rank() OVER (partition by d.Venue_Id ORDER BY d.runs DESC , d.batting_avg) as Ranks
FROM detail d)

SELECT v.Venue_Name , dr.* 
FROM detail_by_rank dr 
JOIN venue v 
ON dr.Venue_Id = v.Venue_Id
WHERE dr.Ranks <= 3;

-- Bowl

WITH runs_consided AS 
(select m.Venue_Id , bb.Bowler , SUM(bs.Runs_Scored) runs_given
FROM ball_by_ball bb 
JOIN batsman_scored bs 
ON bb.Match_Id = bs.Match_Id AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id AND bb.Innings_No = bs.Innings_No
JOIN matches m 
ON m.Match_Id= bb.Match_Id 
GROUP BY m.Venue_Id , bb.Bowler)
,
wickets_taken AS 
(select m.Venue_Id, bb.Bowler , COUNT(wt.Kind_Out) wickets
FROM ball_by_ball bb 
JOIN wicket_taken wt
ON  bb.Match_Id = wt.Match_Id AND bb.Over_Id = wt.Over_Id AND bb.Ball_Id = wt.Ball_Id AND bb.Innings_No = wt.Innings_No
JOIN matches m 
ON m.Match_Id= bb.Match_Id 
GROUP BY m.Venue_Id , bb.Bowler)
,
Details_by_Rank AS 
(SELECT rc.Venue_Id , rc.Bowler ,p.Player_Name ,  rc.runs_given , wt.wickets , rc.runs_given / wt.wickets AS bowling_average , 
       dense_rank() OVER (partition by rc.Venue_Id ORDER BY wt.wickets DESC , rc.runs_given / wt.wickets ASC ) Ranks
FROM runs_consided rc 
JOIN wickets_taken wt 
ON rc.Venue_Id = wt.Venue_Id AND rc.Bowler = wt.Bowler
JOIN player p 
ON p.Player_Id = rc.Bowler)

SELECT v.Venue_Name , dr.* 
FROM Details_by_Rank dr 
JOIN venue v 
ON v.Venue_Id = dr.Venue_Id
WHERE dr.Ranks <= 3;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Subjective Questions

-- sub Q1 : How does toss decision have affected the result of the match ? (which visualisations could be used to better present your answer) And is the impact limited to only specific venues?

-- total number of matches
SELECT count(Match_Id) total_matches 
FROM matches;

-- Number of matches won afer wining the toss
SELECT COUNT(*) Matches_and_toss_won
FROM matches
WHERE Toss_Winner = Match_Winner AND Win_Type in (1,2,4);

-- Matches won after tos winning as per venue
SELECT v.Venue_Name , COUNT(m.Match_Id) matches , COUNT(CASE WHEN m.Toss_Winner = m.Match_Winner THEN 1 else NULL END ) AS toss_win_and_match_win
FROM matches m 
JOIN venue v 
ON m.Venue_Id = v.Venue_Id
WHERE Win_Type in (1,2,4)
GROUP BY v.Venue_Name ;



-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- sub Q8 : Analyze the impact of home ground advantage on team performance and identify strategies to maximize this advantage for RCB.
-- RCB Home Match
SELECT COUNT(*) RCB_Home_Match , COUNT( CASE WHEN Match_Winner = 2 THEN 1 else NULL END ) AS RCB_WIN ,
                  COUNT(CASE WHEN Match_Winner != 2 THEN 1 ELSE NULL END ) AS RCB_LOSS , 
                  COUNT(*) - COUNT(Match_Winner) No_result , 
                  COUNT( CASE WHEN Match_Winner = 2 THEN 1 else NULL END )/COUNT(*) * 100 AS win_percentage
FROM matches
WHERE Venue_Id = 1 AND (Team_1 = 2 or Team_2 =2);

-- RCB Away Match

SELECT COUNT(*) RCB_away_Match , COUNT( CASE WHEN Match_Winner = 2 THEN 1 else NULL END ) AS RCB_WIN ,
                  COUNT(CASE WHEN Match_Winner != 2 THEN 1 ELSE NULL END ) AS RCB_LOSS , 
                  COUNT(*) - COUNT(Match_Winner) No_result , 
                  COUNT( CASE WHEN Match_Winner = 2 THEN 1 else NULL END )/COUNT(*) * 100 AS win_percentage
FROM matches
WHERE Venue_Id != 1 AND (Team_1 = 2 or Team_2 =2);


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- sub Q5 : Are there players whose presence positively influences the morale and performance of the team? (justify your answer using visualisation)

WITH Details AS 
(SELECT p.Player_Id,COUNT(DISTINCT m.Match_Id) Matches_played , COUNT(CASE WHEN t.Team_Id = m.Match_Winner then 1 else NULL end) AS wins,
				   COUNT(CASE WHEN t.Team_Id = m.Match_Winner then 1 else NULL end)/COUNT(DISTINCT m.Match_Id) * 100  AS win_percentage
FROM player p 
JOIN player_match pm 
ON p.Player_Id = pm.Player_Id
JOIN team t 
ON t.Team_Id = pm.Team_Id
JOIN matches m 
ON m.Match_Id = pm.Match_Id
GROUP BY 1)

SELECT p.Player_Name , d.Matches_played , d.wins , d.win_percentage 
FROM Details d 
JOIN player p 
ON p.Player_Id = d.player_Id
WHERE d.Matches_played > 40
ORDER BY d.win_percentage DESC
LIMIT 20;


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- sub Q9 : Come up with a visual and analytical analysis with the RCB past seasons performance and potential reasons for them not winning a trophy.

-- Sesson vise record

SELECT Season_Id , Count(Match_Id) Matches_Played , COUNT(CASE WHEN Match_Winner = 2 THEN 1 else NULL end) AS won ,
                   COUNT(CASE WHEN Match_Winner != 2 THEN 1 else NULL end) AS loss , 
                   COUNT(CASE WHEN Match_Winner = 2 THEN 1 else NULL end) / Count(Match_Id) * 100  AS win_percentage
                   
FROM matches
WHERE Team_1 = 2 or Team_2 = 2
GROUP BY Season_Id;

-- Overall Record 

WITH Detail AS 
(SELECT Season_Id , Count(Match_Id) Matches_Played , COUNT(CASE WHEN Match_Winner = 2 THEN 1 else NULL end) AS won ,
                   COUNT(CASE WHEN Match_Winner != 2 THEN 1 else NULL end) AS loss , 
                   COUNT(CASE WHEN Match_Winner = 2 THEN 1 else NULL end) / Count(Match_Id) * 100  AS win_percentage
FROM matches
WHERE Team_1 = 2 or Team_2 = 2
GROUP BY Season_Id)

select SUM(matches_played) Total_matches , SUM(won) Wins , SUM(loss) loss, 
       AVG(win_percentage) overall_win_percentage , SUM(won) - SUM(loss) AS No_result
FROM Detail;


-- Runs and Wickets

WITH Runs_Per_Season AS 
(SELECT s.Season_Year, SUM(b.Runs_Scored) AS Total_Runs
FROM Season s
JOIN Matches m ON s.Season_Id = m.Season_Id
JOIN Batsman_Scored b ON m.Match_Id = b.Match_Id
WHERE (m.Team_1 = 2 AND b.Innings_No = 1) OR (m.Team_2 = 2 AND b.Innings_No = 2)
GROUP BY s.Season_Year)
,
Wickets_Per_Season AS 
(SELECT s.Season_Year, COUNT(w.Player_Out) AS Total_Wickets
FROM Season s
JOIN Matches m ON s.Season_Id = m.Season_Id
JOIN Wicket_Taken w ON m.Match_Id = w.Match_Id
WHERE (m.Team_1 = 2 AND w.Innings_No = 2) OR (m.Team_2 = 2 AND w.Innings_No = 1)
GROUP BY s.Season_Year)
,
Performance AS 
(SELECT r.Season_Year, r.Total_Runs, w.Total_Wickets,
        LAG(r.Total_Runs) OVER (ORDER BY r.Season_Year) AS Prev_Season_Runs,
        LAG(w.Total_Wickets) OVER (ORDER BY w.Season_Year) AS Prev_Season_Wickets
FROM Runs_Per_Season r
JOIN Wickets_Per_Season w ON r.Season_Year = w.Season_Year
)

SELECT Season_Year, Total_Runs, Total_Wickets
FROM Performance;


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------