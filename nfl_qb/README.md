# NFL QB movement data

Builds a DuckDB database of NFL quarterback movement between teams, 2015 to the current season, from nflverse data, then exports it as DuckDB, Parquet and CSV. The same tables and views live in the MotherDuck database `nfl`.

## Run it

```sh
pip install duckdb
./fetch_nflverse.sh nflverse_raw          # download the source files (about 21 MB)
python build_exports.py exports nflverse_raw
```

Output goes to `exports/`:

- `nfl_qb.duckdb`: the raw tables, with the QB tables as views over them
- `parquet/`: every table and view
- `csv/`: the QB views plus `rosters` and `games`

To cover a new season, raise the end of `range(2015, 2027)` in `build_exports.py` and the year list in `fetch_nflverse.sh`.

## Files

- `fetch_nflverse.sh`: downloads rosters, weekly player stats, snap counts, the player ID crosswalk, and the games schedule.
- `build_exports.py`: loads the raw tables, normalizes team codes (OAK→LV, SD→LAC, STL→LA), builds the views, and writes the exports.
- `views.sql`: the view definitions, also used in MotherDuck. See `../docs/dataflowmaps/qb_team_seasons.md` for a Data Flow Map of `qb_team_seasons`.

## Views

| View | One row per |
|---|---|
| `qb_starts` | team × game (starting QB) |
| `qb_snaps` | QB × game |
| `team_game_snaps` | team × game |
| `qb_team_seasons` | QB × team × season |
| `qb_seasons` | meaningful QB season, with main team |
| `qb_moves` | QB move to a new main team |
| `team_lead_qbs` | team × season lead QB, and how he got there |

**Meaningful** = at least one regular-season start, or 100+ QB snaps with 25+ pass attempts.

## Source

Data from nflverse (https://github.com/nflverse). Snap counts originate from Pro Football Reference. Check the nflverse-data license notes before republishing raw tables, and credit nflverse.
