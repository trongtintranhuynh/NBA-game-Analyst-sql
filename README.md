# NBA-game-Analyst-sql

# 🎲 Game Win–Loss Analysis

## 🧩 Project Overview
A collection of SQL queries to analyze win–loss records in a `game` table.  
You’ll find scripts to:
- Retrieve all game records  
- List each game’s date, home/away teams, and outcomes  
- Compute total wins per team (home & away)  
- Build win–loss aggregates per team per season  
- Identify the best win–loss record in a single season  

## 🛠️ Technologies & Requirements
- **Database**: Any SQL‑compliant RDBMS (PostgreSQL, MySQL, SQL Server, etc.)  
- **Client**: `psql`, MySQL Shell, SQL Server Management Studio, DBeaver, etc.  
- **Scripts**: Plain `.sql` files—no special dependencies  

## 📂 Repository Structure
```
game-win-loss-analysis/
│
├── README.md                   # Project overview & usage
├── LICENSE                     # License file (e.g., MIT)
├── .gitignore                  # Ignore patterns for temporary files
│
├── data/                       # (Optional) DDL & sample data
│   ├── game_schema.sql         # CREATE TABLE game (...)
│   └── sample_game_data.csv    # Sample records
│
├── scripts/
│   └── game_analysis.sql       # All analysis queries
│
└── docs/
    └── sample_output.png       # Screenshots of query results
```

## 📑 `scripts/game_analysis.sql`
1. **Select all games**  
   ```sql
   SELECT * FROM game;
   ```

2. **List game date & team outcomes**  
   ```sql
   SELECT game_date,
          team_name_home, WL_home,
          team_name_away, WL_away
   FROM game
   ORDER BY game_date;
   ```

3. **Compute total wins per team**  
   ```sql
   SELECT team_name_home AS team_name, COUNT(*) AS wins
   FROM game
   WHERE WL_home = 'W'
   GROUP BY team_name_home
   UNION ALL
   SELECT team_name_away AS team_name, COUNT(*) AS wins
   FROM game
   WHERE WL_away = 'W'
   GROUP BY team_name_away;
   ```

4. **Aggregate wins & losses per team**  
   ```sql
   SELECT
     team_name,
     SUM(win)   AS total_wins,
     SUM(loss)  AS total_losses
   FROM (
     SELECT 
       team_name_home AS team_name,
       COUNT(CASE WHEN WL_home = 'W' THEN 1 END) AS win,
       COUNT(CASE WHEN WL_home = 'L' THEN 1 END) AS loss
     FROM game
     GROUP BY team_name_home
     UNION ALL
     SELECT 
       team_name_away AS team_name,
       COUNT(CASE WHEN WL_away = 'W' THEN 1 END) AS win,
       COUNT(CASE WHEN WL_away = 'L' THEN 1 END) AS loss
     FROM game
     GROUP BY team_name_away
   ) AS win_loss
   GROUP BY team_name
   ORDER BY total_wins DESC, total_losses DESC;
   ```

5. **Best single‑season win–loss record**  
   ```sql
   SELECT season_id,
          season_type,
          team_name,
          SUM(wins)   AS wins,
          SUM(losses) AS losses
   FROM your_win_loss_view
   GROUP BY season_id, season_type, team_name
   ORDER BY wins DESC, losses ASC
   LIMIT 1;
   ```

*(Replace `your_win_loss_view` with the actual view or table name created from the previous step.)*

---

## 🚀 How to Use
1. Create the `game` table using `data/game_schema.sql` and load sample data from `data/sample_game_data.csv`.  
2. Connect to your database via your preferred SQL client.  
3. Execute the queries in `scripts/game_analysis.sql` sequentially.  
4. Review results in your client or export to CSV/Excel.

