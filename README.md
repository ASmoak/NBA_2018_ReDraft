# NBA 2018 Redraft Analysis

This project provides a comprehensive statistical analysis of the 2018 NBA Draft class using TSQL in SQL Server Management Studio 2020. The analysis evaluates player performance and draft efficiency based on career statistics.

## Key Features

### Career Impact Score
A sophisticated formula that evaluates players based on:
- Points (PTS) * 1.0
- Rebounds (TRB) * 1.2
- Assists (AST) * 1.5
- Steals (STL) * 3.0
- Blocks (BLK) * 3.0
- Turnovers (TOV) * -1.0 (penalty)
- Field Goal Percentage (FG%) * 100
- Free Throw Percentage (FT%) * 50
- Three-Point Percentage (3P%) * 100
- Adjusted by games played (G/500)

### Value Status Categories
Players are categorized based on their original draft position vs redrafted position:
- **MASSIVE UNDRAFTED STEAL**: Undrafted players redrafted in top 30
- **UNDRAFTED STEAL**: Undrafted players redrafted in top 60
- **HUGE STEAL**: Drafted after 20th, redrafted in top 10
- **STEAL**: Drafted after 30th, redrafted in top 15
- **MAJOR BUST**: Drafted 1-10th, redrafted after 30th
- **BUST**: Drafted 1-5th, redrafted after 20th
- **Expected Value**: All other cases

### Analysis Outputs
1. **Redrafted Order**: Players ranked by career impact score
2. **Position Change**: Shows movement from original draft position to redrafted position
3. **Team Performance Analysis**: Includes:
   - Drafted vs Undrafted players count
   - Total and average impact scores
   - Value status counts
   - Top performer details
4. **Undrafted Free Agents**: Top undrafted players by impact score
5. **Draft Efficiency**: Analysis of draft position vs player performance

## Requirements
- SQL Server Management Studio 2020
- TSQL compatibility
- Input data table: `Revised_2018_NBA_Draft`

## Usage
1. Execute the SQL script in sequence
2. Review the comprehensive analysis outputs
3. Use the normalized scoring system (1-100 scale) for easy comparison
4. Analyze team performance and draft efficiency

## Data Sources
The analysis uses the `Revised_2018_NBA_Draft` table containing career statistics for all players from the 2018 draft class, including:
- Career totals and averages
- Draft position and status
- Team information
- Shooting percentages
- Per game statistics
