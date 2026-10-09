"""Rebuild the MotherDuck `nfl` database locally and export it as DuckDB, Parquet and CSV."""
import os
import sys

import duckdb

out = sys.argv[1]
raw = sys.argv[2]  # local copies of the nflverse files
os.makedirs(f"{out}/parquet", exist_ok=True)
os.makedirs(f"{out}/csv", exist_ok=True)
db_path = f"{out}/nfl_qb.duckdb"
if os.path.exists(db_path):
    os.remove(db_path)

con = duckdb.connect(db_path)
YEARS = "range(2015, 2027)"
TEAM_FIX = "CASE {c} WHEN 'OAK' THEN 'LV' WHEN 'SD' THEN 'LAC' WHEN 'STL' THEN 'LA' ELSE {c} END"

# Raw tables: same sources and cleaning as MotherDuck.
con.execute(f"""
CREATE TABLE rosters AS
SELECT * FROM read_parquet(['{raw}/roster_' || y || '.parquet' FOR y IN {YEARS}], union_by_name=true);

CREATE TABLE player_week_stats AS
SELECT * FROM read_parquet(['{raw}/stats_player_week_' || y || '.parquet' FOR y IN {YEARS}], union_by_name=true);

CREATE TABLE games AS
SELECT * REPLACE ({TEAM_FIX.format(c='home_team')} AS home_team, {TEAM_FIX.format(c='away_team')} AS away_team)
FROM read_csv_auto('{raw}/games.csv')
WHERE season >= 2015;

CREATE TABLE snap_counts AS
SELECT * REPLACE ({TEAM_FIX.format(c='team')} AS team)
FROM read_parquet(['{raw}/snap_counts_' || y || '.parquet' FOR y IN {YEARS}], union_by_name=true);

CREATE TABLE player_ids AS
SELECT pfr_id, any_value(gsis_id) AS gsis_id
FROM rosters WHERE pfr_id IS NOT NULL AND gsis_id IS NOT NULL
GROUP BY pfr_id HAVING count(DISTINCT gsis_id) = 1;

INSERT INTO player_ids
SELECT pfr_id, any_value(gsis_id) FROM read_parquet('{raw}/players.parquet')
WHERE pfr_id IS NOT NULL AND gsis_id IS NOT NULL AND pfr_id NOT IN (SELECT pfr_id FROM player_ids)
GROUP BY pfr_id HAVING count(DISTINCT gsis_id) = 1;
""")

# Views: definitions copied from MotherDuck, in dependency order.
con.execute(open(os.path.join(os.path.dirname(__file__), "views.sql")).read())

ANALYTIC = ["qb_starts", "qb_snaps", "team_game_snaps", "qb_team_seasons", "qb_seasons", "qb_moves", "team_lead_qbs"]
RAW = ["rosters", "player_week_stats", "games", "snap_counts", "player_ids"]

for name in ANALYTIC + RAW:
    con.execute(f"COPY (SELECT * FROM {name}) TO '{out}/parquet/{name}.parquet' (FORMAT parquet, COMPRESSION zstd)")
# CSV for the QB analytic views plus the smaller raw tables.
for name in ANALYTIC + ["rosters", "games"]:
    con.execute(f"COPY (SELECT * FROM {name}) TO '{out}/csv/{name}.csv' (HEADER)")

for name in ANALYTIC + RAW:
    n = con.execute(f"SELECT count(*) FROM {name}").fetchone()[0]
    print(f"{name}: {n:,} rows")
con.close()
