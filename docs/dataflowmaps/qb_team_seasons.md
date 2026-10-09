# Data Flow Map: `qb_team_seasons`

**Flows:** `@starts` + `@snaps` + `@team_snaps` → `@stats` → `@qb_team_seasons`

## @starts
*From the `qb_starts` view*

| Symbol | Action | Step |
|:---:|---|---|
| `O` | Get | `games`: one row per game |
| `X` | Fix | Team codes set to current franchises (OAK→LV, SD→LAC, STL→LA) |
| `v` | Cut | Games not played yet (`result` is null) |
| `^` | Keep | Home and away sides stacked into one list: team, QB id, QB name |
| `v` | Cut | Playoff games (regular season only) |
| `]` | Box | Season × QB × team |
| `#` | Size | Count of games → `starts` |

## @team_snaps
*From the `team_game_snaps` view*

| Symbol | Action | Step |
|:---:|---|---|
| `O` | Get | `snap_counts`: one row per player per game |
| `X` | Fix | Team codes set to current franchises |
| `]` | Box | Game × team |
| `#` | Size | Most snaps any player had → `team_off_snaps` per game |
| `v` | Cut | Playoff games |
| `]` | Box | Season × team |
| `#` | Size | Sum → `team_off_snaps` per season |

## @snaps
*From the `qb_snaps` view*

| Symbol | Action | Step |
|:---:|---|---|
| `O` | Get | `snap_counts` |
| `+` | Join | `player_ids`: Pro Football Reference ID → nflverse ID |
| `+` | Join | `@team_snaps`, matched on game and team |
| `v` | Cut | Rows where the player isn't listed at QB |
| `v` | Cut | Playoff games |
| `]` | Box | Season × QB × team |
| `#` | Size | Sum of `offense_snaps` → `qb_snaps` |

## @stats

| Symbol | Action | Step |
|:---:|---|---|
| `O` | Get | `player_week_stats`: one row per player per game |
| `v` | Cut | Playoff games |
| `v` | Cut | Players who aren't QBs, unless they ever started at QB (keeps Taysom Hill, Kendall Hinton) |
| `]` | Box | Season × player × team |
| `^` | Keep | `player_display_name` → `player_name` |
| `#` | Size | Distinct games with a pass or carry → `games_played` |
| `#` | Size | Sum attempts, yards, TDs, INTs → `pass_att`, `pass_yds`, `pass_td`, `ints` |
| `#` | Size | Sum passing EPA, rounded to 1 decimal → `pass_epa` |

## @qb_team_seasons
*`@stats` + `@starts` + `@snaps` + `@team_snaps`*

| Symbol | Action | Step |
|:---:|---|---|
| `O` | Get | `@stats` |
| `+` | Join | `@starts`, left join on season, QB, team |
| `+` | Join | `@snaps`, left join on season, QB, team |
| `+` | Join | `@team_snaps`, left join on season, team |
| `X` | Fix | Missing starts and snaps set to 0 |
| `X` | Fix | `snap_share` = `qb_snaps` ÷ `team_off_snaps`, rounded to 3 decimals |
| `X` | Fix | `meaningful` = 1+ start, or 100+ snaps with 25+ pass attempts |
| `^` | Keep | 14 columns: season, QB, team, games, starts, snaps, share, passing, EPA, meaningful |
| `=` | Ship | `qb_team_seasons` view: **919 rows**, 708 of them meaningful |

## Notes

- **The `@stats` QB check includes playoff starts.** That check uses every game in `qb_starts`, including playoffs. A non-QB who started only in a playoff game would still be kept. It has no effect today, but you could limit it to regular-season starts.
- **The team-snap total is an estimate.** It counts the most snaps any one player had in the game, assuming at least one offensive player, usually a lineman, was on the field for every snap.
