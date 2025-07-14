-- NBA 2018 Redraft Statistical Analysis
-- SQL Server Management Studio 2020 Compatible

-- 1. Create Temporary Table for Calculations
SELECT 
    ID,
    Player,
    Debut,
    Age,
    Yrs,
    Draft_Position,
    Team,
    Draft_Status,
    G,
    MP,
    FG,
    FGA,
    3P,
    3PA,
    FT,
    FTA,
    ORB,
    TRB,
    AST,
    STL,
    BLK,
    TOV,
    PF,
    PTS,
    FG_PCT,
    3P_PCT,
    FT_PCT,
    MP_Avg_Per_Gm,
    PTS_Avg_Per_Gm,
    TRB_Avg_Per_Gm,
    AST_Avg_Per_Gm,
    STL_Avg_Per_Gm,
    BLK_Avg_Per_Gm,
    
    -- Calculate Individual Impact Scores (weighted by career totals)
    ((CAST(PTS AS FLOAT) * 0.35) + 
     (CAST(TRB AS FLOAT) * 0.20) + 
     (CAST(AST AS FLOAT) * 0.20) + 
     (CAST(STL AS FLOAT) * 0.10) + 
     (CAST(BLK AS FLOAT) * 0.10) + 
     (CAST(3P AS FLOAT) * 0.05)) * 
     (1 - (CAST(TOV AS FLOAT) / CAST(G AS FLOAT) * 0.1)) AS Career_Impact_Score

INTO #TempPlayerStats
FROM [dbo].[Revised_2018_NBA_Draft]
WHERE G > 0 -- Only consider players who have played in the NBA

-- 2. Calculate Normalized Impact Scores (1-100 scale)
SELECT 
    ID,
    Player,
    Debut,
    Age,
    Yrs,
    Draft_Position,
    Team,
    Draft_Status,
    G,
    MP,
    FG,
    FGA,
    3P,
    3PA,
    FT,
    FTA,
    ORB,
    TRB,
    AST,
    STL,
    BLK,
    TOV,
    PF,
    PTS,
    FG_PCT,
    3P_PCT,
    FT_PCT,
    MP_Avg_Per_Gm,
    PTS_Avg_Per_Gm,
    TRB_Avg_Per_Gm,
    AST_Avg_Per_Gm,
    STL_Avg_Per_Gm,
    BLK_Avg_Per_Gm,
    Career_Impact_Score,
    
    -- Calculate normalized score (1-100 scale)
    CAST(((Career_Impact_Score - MIN(Career_Impact_Score) OVER()) / 
          (MAX(Career_Impact_Score) OVER() - MIN(Career_Impact_Score) OVER())) * 100 AS DECIMAL(5,2)) AS Normalized_Impact_Score
INTO #FinalPlayerStats
FROM #TempPlayerStats

-- 3. Redrafted Order Based on Career Impact
SELECT 
    ROW_NUMBER() OVER (ORDER BY Career_Impact_Score DESC) AS Redraft_Position,
    Player,
    Draft_Position,
    Draft_Status,
    Career_Impact_Score,
    Normalized_Impact_Score,
    Team,
    G,
    PTS,
    TRB,
    AST,
    STL,
    BLK
FROM #FinalPlayerStats
ORDER BY Career_Impact_Score DESC

-- 4. Best Undrafted Free Agents
SELECT TOP 10
    Player,
    Team,
    Career_Impact_Score,
    Normalized_Impact_Score,
    G,
    PTS,
    TRB,
    AST,
    STL,
    BLK
FROM #FinalPlayerStats
WHERE Draft_Status = 'Undrafted'
ORDER BY Career_Impact_Score DESC

-- 5. Team Performance Analysis
SELECT 
    Team,
    COUNT(CASE WHEN Draft_Status = 'Drafted' THEN 1 END) AS Drafted_Players,
    COUNT(CASE WHEN Draft_Status = 'Undrafted' THEN 1 END) AS Undrafted_Players,
    SUM(Career_Impact_Score) AS Total_Impact,
    AVG(Career_Impact_Score) AS Avg_Impact,
    MAX(Career_Impact_Score) AS Best_Pick_Impact,
    MIN(Career_Impact_Score) AS Worst_Pick_Impact,
    STRING_AGG(Player, ', ') WITHIN GROUP (ORDER BY Career_Impact_Score DESC) AS Players
FROM #FinalPlayerStats
GROUP BY Team
ORDER BY Total_Impact DESC

-- 6. Draft Efficiency Analysis
SELECT 
    Team,
    Draft_Position,
    Player,
    Career_Impact_Score,
    Normalized_Impact_Score,
    G,
    PTS,
    TRB,
    AST,
    STL,
    BLK,
    
    -- Calculate draft efficiency (higher is better)
    CASE 
        WHEN Draft_Position = 0 THEN 0 -- Undrafted players
        ELSE CAST(Career_Impact_Score / Draft_Position AS DECIMAL(5,2))
    END AS Draft_Efficiency
FROM #FinalPlayerStats
WHERE Draft_Position > 0
ORDER BY Draft_Efficiency DESC

-- Cleanup
DROP TABLE IF EXISTS #TempPlayerStats
DROP TABLE IF EXISTS #FinalPlayerStats
