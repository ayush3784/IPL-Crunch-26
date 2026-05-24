# 📊 SOQL Queries Reference — IPL Crunch '26
# Author: Ayush Vats | MIET Meerut
# Run these in Salesforce Developer Console → Query Editor

# ═══════════════════════════════════════════════════════════
# ANALYSIS 1: TOSS WIN RATE
# ═══════════════════════════════════════════════════════════

-- Overall toss win rate
SELECT COUNT(Id) Total,
       SUM(CASE WHEN Toss_Winner__c = Winner__c THEN 1 ELSE 0 END) TossWins
FROM Match__c
WHERE Winner__c != NULL

-- By toss decision (bat / field)
SELECT Toss_Decision__c,
       COUNT(Id) TotalMatches,
       SUM(CASE WHEN Toss_Winner__c = Winner__c THEN 1 ELSE 0 END) TossWins
FROM Match__c
WHERE Winner__c != NULL AND Toss_Decision__c != NULL
GROUP BY Toss_Decision__c

-- Season-wise toss win trend
SELECT Season__c,
       COUNT(Id) TotalMatches,
       SUM(CASE WHEN Toss_Winner__c = Winner__c THEN 1 ELSE 0 END) TossWins
FROM Match__c
WHERE Winner__c != NULL
GROUP BY Season__c
ORDER BY Season__c ASC


# ═══════════════════════════════════════════════════════════
# ANALYSIS 2: PHASE-WISE RUN PRODUCTION
# ═══════════════════════════════════════════════════════════

-- Total runs by phase
SELECT Phase__c,
       COUNT(Id) Deliveries,
       SUM(Total_Runs__c) TotalRuns,
       AVG(Total_Runs__c) AvgRunsPerBall,
       COUNT(DISTINCT Match__c) Matches
FROM Delivery__c
WHERE Phase__c != NULL
GROUP BY Phase__c
ORDER BY Phase__c

-- Wickets by phase
SELECT Phase__c,
       COUNT(Id) TotalWickets
FROM Delivery__c
WHERE Is_Wicket__c = TRUE
AND Dismissal_Kind__c != 'run out'
AND Phase__c != NULL
GROUP BY Phase__c


# ═══════════════════════════════════════════════════════════
# ANALYSIS 3: TOP BATTERS — CONSISTENCY SCORE
# ═══════════════════════════════════════════════════════════

-- Top batters by total runs (filter min 200 balls, 10 innings)
SELECT Batsman__c,
       SUM(Batsman_Runs__c) TotalRuns,
       COUNT(Id) BallsFaced,
       COUNT(DISTINCT Match__c) Innings
FROM Delivery__c
WHERE Batsman__c != NULL
GROUP BY Batsman__c
HAVING COUNT(Id) >= 200 AND COUNT(DISTINCT Match__c) >= 10
ORDER BY SUM(Batsman_Runs__c) DESC
LIMIT 20

-- Top bowlers by wickets
SELECT Bowler__c,
       COUNT(Id) BallsBowled,
       SUM(Total_Runs__c) RunsConceded,
       SUM(CASE WHEN Is_Wicket__c = TRUE
                AND Dismissal_Kind__c != 'run out' THEN 1 ELSE 0 END) Wickets,
       COUNT(DISTINCT Match__c) Matches
FROM Delivery__c
WHERE Bowler__c != NULL
GROUP BY Bowler__c
HAVING COUNT(Id) >= 240 AND COUNT(DISTINCT Match__c) >= 10
ORDER BY SUM(CASE WHEN Is_Wicket__c = TRUE
                  AND Dismissal_Kind__c != 'run out' THEN 1 ELSE 0 END) DESC
LIMIT 10

-- Player of Match frequency
SELECT Player_Of_Match__c, COUNT(Id) Awards
FROM Match__c
WHERE Player_Of_Match__c != NULL
GROUP BY Player_Of_Match__c
ORDER BY COUNT(Id) DESC
LIMIT 10


# ═══════════════════════════════════════════════════════════
# ANALYSIS 4: VENUE CHASING WIN % (SURPRISE INSIGHT)
# ═══════════════════════════════════════════════════════════

-- Matches per venue (min 10 needed)
SELECT Venue__c,
       COUNT(Id) TotalMatches
FROM Match__c
WHERE Venue__c != NULL
GROUP BY Venue__c
HAVING COUNT(Id) >= 10
ORDER BY COUNT(Id) DESC

-- Toss decision distribution by venue
SELECT Venue__c, Toss_Decision__c,
       COUNT(Id) Count
FROM Match__c
WHERE Venue__c != NULL
GROUP BY Venue__c, Toss_Decision__c
ORDER BY COUNT(Id) DESC

-- Formula field check: Toss Won Match
SELECT Id, Toss_Winner__c, Winner__c, Toss_Won_Match__c
FROM Match__c
WHERE Winner__c != NULL
LIMIT 10


# ═══════════════════════════════════════════════════════════
# UTILITY QUERIES
# ═══════════════════════════════════════════════════════════

-- Count records loaded
SELECT COUNT(Id) FROM Match__c
SELECT COUNT(Id) FROM Delivery__c

-- Seasons available
SELECT Season__c, COUNT(Id) Matches
FROM Match__c
GROUP BY Season__c
ORDER BY Season__c ASC

-- Teams in dataset
SELECT Team1__c, COUNT(Id) Appearances
FROM Match__c
GROUP BY Team1__c
ORDER BY COUNT(Id) DESC
