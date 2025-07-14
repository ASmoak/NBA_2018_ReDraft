-- NBA 2018 Redraft Statistical Analysis
-- SQL Server Management Studio 2020 Compatible

-- Using CTEs for better readability and performance
WITH PlayerStats AS (
    -- Base player statistics with Impact Score calculation
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
        [3P_PCT],
        FT_PCT,
        MP_Avg_Per_Gm,
        PTS_Avg_Per_Gm,
        TRB_Avg_Per_Gm,
        AST_Avg_Per_Gm,
        STL_Avg_Per_Gm,
        BLK_Avg_Per_Gm,
        
        -- Calculate Career Impact Score with new formula
        (
            (PTS * 1.0) + 
            (TRB * 1.2) + 
            (AST * 1.5) + 
            (STL * 3.0) + 
            (BLK * 3.0) - 
            (TOV * 1.0) +  -- Penalty for turnovers
            (FG_PCT * 100) + 
            (FT_PCT * 50) + 
            ([3P_PCT] * 100)
        ) * 
        -- Games played multiplier (G/500)
        (CAST(G AS FLOAT) / 500.0) AS Career_Impact_Score,
        
    FROM [dbo].[Revised_2018_NBA_Draft]
    WHERE G > 0 -- Only consider players who have played in the NBA
),

NormalizedStats AS (
    -- Calculate normalized scores, add Redraft Position, and Value Status
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
        [3P_PCT],
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
              (MAX(Career_Impact_Score) OVER() - MIN(Career_Impact_Score) OVER())) * 100 AS DECIMAL(5,2)) AS Normalized_Impact_Score,
        
        -- Calculate Redraft Position
        ROW_NUMBER() OVER (ORDER BY Career_Impact_Score DESC) AS Redraft_Position,
        
        -- Calculate Value Status based on Draft vs Redraft position
        CASE 
            WHEN Draft_Position = 0 AND Redraft_Position <= 30 THEN 'MASSIVE UNDRAFTED STEAL'
            WHEN Draft_Position = 0 AND Redraft_Position <= 60 THEN 'UNDRAFTED STEAL'
            WHEN Draft_Position > 20 AND Redraft_Position <= 10 THEN 'HUGE STEAL'
            WHEN Draft_Position > 30 AND Redraft_Position <= 15 THEN 'STEAL'
            WHEN Draft_Position BETWEEN 1 AND 10 AND Redraft_Position > 30 THEN 'MAJOR BUST'
            WHEN Draft_Position BETWEEN 1 AND 5 AND Redraft_Position > 20 THEN 'BUST'
            ELSE 'Expected Value'
        END AS Value_Status
    FROM PlayerStats
)


-- Main Redrafted Order Query
SELECT 
    Redraft_Position,
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
    BLK,
    FG_PCT,
    [3P_PCT],
    FT_PCT,
    MP_Avg_Per_Gm,
    PTS_Avg_Per_Gm,
    TRB_Avg_Per_Gm,
    AST_Avg_Per_Gm,
    STL_Avg_Per_Gm,
    BLK_Avg_Per_Gm,
    
    -- Calculate Position Change
    CASE 
        WHEN Draft_Position = 0 THEN 'Undrafted -> Pick ' + CAST(Redraft_Position as VARCHAR(3))
        ELSE 'Pick ' + CAST(Draft_Position as VARCHAR(3)) + ' -> Pick ' + CAST(Redraft_Position as VARCHAR(3))
    END AS Position_Change,

    -- Calculate Value Status based on Draft vs Redraft position
    CASE 
        WHEN Draft_Position = 0 AND Redraft_Position <= 30 THEN 'MASSIVE UNDRAFTED STEAL'
        WHEN Draft_Position = 0 AND Redraft_Position <= 60 THEN 'UNDRAFTED STEAL'
        WHEN Draft_Position > 20 AND Redraft_Position <= 10 THEN 'HUGE STEAL'
        WHEN Draft_Position > 30 AND Redraft_Position <= 15 THEN 'STEAL'
        WHEN Draft_Position BETWEEN 1 AND 10 AND Redraft_Position > 30 THEN 'MAJOR BUST'
        WHEN Draft_Position BETWEEN 1 AND 5 AND Redraft_Position > 20 THEN 'BUST'
        ELSE 'Expected Value'
    END AS Value_Status

FROM NormalizedStats
ORDER BY Redraft_Position
OFFSET 5 ROWS FETCH FIRST 100 ROWS ONLY



-- Best Undrafted Free Agents
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
    BLK,
	FG_PCT,
    [3P_PCT],
    FT_PCT,
FROM NormalizedStats
WHERE Draft_Status = 'Undrafted'
ORDER BY Career_Impact_Score DESC



-- Team Performance Analysis with Value Status counts and top scorer details
SELECT 
    Team,
    COUNT(CASE WHEN Draft_Status = 'Drafted' THEN 1 END) AS Drafted_Players,
    COUNT(CASE WHEN Draft_Status = 'Undrafted' THEN 1 END) AS Undrafted_Players,
    SUM(Career_Impact_Score) AS Total_Impact,
    AVG(Career_Impact_Score) AS Avg_Impact,
    MAX(Career_Impact_Score) AS Best_Pick_Impact,
    MIN(Career_Impact_Score) AS Worst_Pick_Impact,
    
    -- Value Status counts
    COUNT(CASE WHEN Value_Status = 'MASSIVE UNDRAFTED STEAL' THEN 1 END) AS Massive_Undrafted_Steals,
    COUNT(CASE WHEN Value_Status = 'UNDRAFTED STEAL' THEN 1 END) AS Undrafted_Steals,
    COUNT(CASE WHEN Value_Status = 'HUGE STEAL' THEN 1 END) AS Huge_Steals,
    COUNT(CASE WHEN Value_Status = 'STEAL' THEN 1 END) AS Steals,
    COUNT(CASE WHEN Value_Status = 'MAJOR BUST' THEN 1 END) AS Major_Busts,
    COUNT(CASE WHEN Value_Status = 'BUST' THEN 1 END) AS Busts,
    
    -- Top scorer details (using SELECT TOP 1 for clarity)
    (SELECT TOP 1 Player FROM NormalizedStats n2 WHERE n2.Team = NormalizedStats.Team ORDER BY Normalized_Impact_Score DESC) AS Top_Scorer,
    (SELECT TOP 1 Normalized_Impact_Score FROM NormalizedStats n2 WHERE n2.Team = NormalizedStats.Team ORDER BY Normalized_Impact_Score DESC) AS Top_Scorer_Score,
    (SELECT TOP 1 G FROM NormalizedStats n2 WHERE n2.Team = NormalizedStats.Team ORDER BY Normalized_Impact_Score DESC) AS Top_Scorer_Games
    
FROM NormalizedStats
GROUP BY Team
ORDER BY Avg_Impact DESC




-- Draft Efficiency Analysis
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
FROM NormalizedStats
WHERE Draft_Position > 0
ORDER BY Draft_Efficiency DESC