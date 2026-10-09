# Data Flow Map: `qb_moves`

**Flows:** `@qb_team_seasons` → `@qb_seasons` → `@qb_moves`

`@qb_team_seasons` is mapped in full in [qb_team_seasons.md](qb_team_seasons.md): one row per QB, team and regular season, with starts, snaps, passing and the `meaningful` flag.

## @qb_seasons
*From the `qb_seasons` view*

| Symbol | Action | Step |
|:---:|---|---|
| `O` | Get | `@qb_team_seasons`: one row per QB × team × season |
| `v` | Cut | Stints that aren't meaningful (no start, and under 100 snaps or 25 attempts) |
| `]` | Box | Season × QB |
| `^` | Keep | Any one `player_name` for the QB |
| `X` | Fix | `primary_team` = the team with the most QB snaps, ties broken by starts |
| `X` | Fix | `teams` = every team that season, most snaps first (e.g. `CAR/LA`) |
| `#` | Size | More than one team → `midseason_move` |
| `#` | Size | Sum starts, snaps, attempts, yards, TDs, INTs |
| `=` | Ship | `qb_seasons` view: **702 rows** |

## @qb_moves
*From the `qb_moves` view*

| Symbol | Action | Step |
|:---:|---|---|
| `O` | Get | `@qb_seasons` |
| `\` | Sort | Each QB's seasons in order |
| `X` | Fix | `prev_team` = main team in his previous meaningful season |
| `X` | Fix | `prev_season` = that previous season |
| `v` | Cut | Each QB's first season (nothing to compare to) |
| `v` | Cut | Seasons where the main team didn't change |
| `^` | Keep | QB, previous season and team, new season and team, and that season's stats, with `primary_team` → `new_team`, `teams` → `new_season_teams`, `starts` → `season_starts` |
| `=` | Ship | `qb_moves` view: **171 rows** |

## Notes

- **Stats cover the whole season.** `season_starts`, `qb_snaps` and the passing columns are the QB's totals across every team he had meaningful time with that season, not just the new team. The two differ only for the 6 seasons where a QB had meaningful time with two teams. (This column was called `new_team_starts` until it was renamed for accuracy.)
- **"Previous" means the last meaningful season, not last year.** 46 of the 171 moves skip at least one season, up to 4 years, while the QB was hurt or an unused backup. For example, a QB who played for Denver in 2021 and next got meaningful snaps for the Giants in 2024 counts as one DEN→NYG move.
- **A mid-season trade counts only if the new team got more snaps.** A QB traded in Week 12 keeps his old team as his main team for that season. His `new_season_teams` value (e.g. `CAR/LA`) still shows both.
- **The history starts in 2015.** Moves into 2016 compare against 2015, and those account for 6 moves. A QB whose last meaningful season was before 2015 shows up as a first season rather than a move.
