-- Starting QB for each team in each completed game.
CREATE VIEW qb_starts AS
SELECT season, week, game_type, game_id, home_team AS team, home_qb_id AS player_id, home_qb_name AS player_name FROM games WHERE result IS NOT NULL
UNION ALL
SELECT season, week, game_type, game_id, away_team, away_qb_id, away_qb_name FROM games WHERE result IS NOT NULL;

-- Team offensive snaps per game (the most snaps any player on the team played).
CREATE VIEW team_game_snaps AS
SELECT game_id, season, game_type, team, max(offense_snaps)::INT AS team_off_snaps
FROM snap_counts GROUP BY ALL;

-- QB snaps per game, keyed to the nflverse (gsis) player id.
CREATE VIEW qb_snaps AS
SELECT s.season, s.week, s.game_type, s.game_id, s.team, i.gsis_id AS player_id, s.player AS player_name,
       s.offense_snaps, s.offense_pct, t.team_off_snaps
FROM snap_counts s
JOIN player_ids i ON i.pfr_id = s.pfr_player_id
JOIN team_game_snaps t USING (game_id, team)
WHERE s.position = 'QB';

-- One row per QB, team and regular season. meaningful = 1+ start, or 100+ QB snaps with 25+ pass attempts.
CREATE VIEW qb_team_seasons AS
WITH stats AS (
  SELECT season, player_id, any_value(player_display_name) AS player_name, team,
         count(DISTINCT game_id) FILTER (WHERE attempts > 0 OR carries > 0) AS games_played,
         sum(attempts) AS pass_att, sum(passing_yards) AS pass_yds,
         sum(passing_tds) AS pass_td, sum(passing_interceptions) AS ints,
         round(sum(passing_epa), 1) AS pass_epa
  FROM player_week_stats
  WHERE season_type = 'REG'
    AND (position = 'QB' OR player_id IN (SELECT player_id FROM qb_starts))
  GROUP BY ALL
), starts AS (
  SELECT season, player_id, team, count(*) AS starts
  FROM qb_starts WHERE game_type = 'REG' GROUP BY ALL
), snaps AS (
  SELECT season, player_id, team, sum(offense_snaps)::INT AS qb_snaps
  FROM qb_snaps WHERE game_type = 'REG' GROUP BY ALL
), team_snaps AS (
  SELECT season, team, sum(team_off_snaps)::INT AS team_off_snaps
  FROM team_game_snaps WHERE game_type = 'REG' GROUP BY ALL
)
SELECT s.season, s.player_id, s.player_name, s.team, s.games_played,
       coalesce(st.starts, 0) AS starts,
       coalesce(sn.qb_snaps, 0) AS qb_snaps,
       round(coalesce(sn.qb_snaps, 0) / ts.team_off_snaps, 3) AS snap_share,
       s.pass_att, s.pass_yds, s.pass_td, s.ints, s.pass_epa,
       (coalesce(st.starts, 0) >= 1 OR (coalesce(sn.qb_snaps, 0) >= 100 AND s.pass_att >= 25)) AS meaningful
FROM stats s
LEFT JOIN starts st USING (season, player_id, team)
LEFT JOIN snaps sn USING (season, player_id, team)
LEFT JOIN team_snaps ts USING (season, team);

-- One row per meaningful QB season, with his main team (most snaps).
CREATE VIEW qb_seasons AS
SELECT season, player_id, any_value(player_name) AS player_name,
       arg_max(team, qb_snaps * 100 + starts) AS primary_team,
       string_agg(team, '/' ORDER BY qb_snaps DESC, starts DESC) AS teams,
       count(*) > 1 AS midseason_move,
       sum(starts) AS starts, sum(qb_snaps) AS qb_snaps, sum(pass_att) AS pass_att,
       sum(pass_yds) AS pass_yds, sum(pass_td) AS pass_td, sum(ints) AS ints
FROM qb_team_seasons
WHERE meaningful
GROUP BY season, player_id;

-- Every time a QB's main team changed from his previous meaningful season.
CREATE VIEW qb_moves AS
WITH x AS (
  SELECT *, lag(primary_team) OVER w AS prev_team, lag(season) OVER w AS prev_season
  FROM qb_seasons WINDOW w AS (PARTITION BY player_id ORDER BY season)
)
SELECT player_id, player_name, prev_season, prev_team, season, primary_team AS new_team,
       teams AS new_season_teams, starts AS season_starts, qb_snaps, pass_att, pass_yds, pass_td, ints
FROM x
WHERE prev_team IS NOT NULL AND prev_team <> primary_team;

-- Each team's lead QB (most snaps) per season, and how he got there.
CREATE VIEW team_lead_qbs AS
WITH ranked AS (
  SELECT *, row_number() OVER (PARTITION BY team, season ORDER BY qb_snaps DESC, starts DESC) AS rk
  FROM qb_team_seasons
), lead AS (SELECT * FROM ranked WHERE rk = 1),
prior AS (
  SELECT l.team, l.season,
         bool_or(p.team = l.team AND p.season >= l.season - 2) AS recent_with_team,
         arg_max(p.team, p.season) FILTER (WHERE p.team <> l.team) AS last_other_team
  FROM lead l JOIN qb_team_seasons p ON p.player_id = l.player_id AND p.season < l.season AND p.meaningful
  GROUP BY ALL
)
SELECT l.team, l.season, l.player_id, l.player_name AS qb, l.starts, l.qb_snaps, l.snap_share,
       CASE WHEN pr.recent_with_team THEN 'Returning'
            WHEN pr.last_other_team IS NOT NULL THEN 'Arrived from another team'
            ELSE 'First meaningful season' END AS how,
       CASE WHEN NOT coalesce(pr.recent_with_team, false) THEN pr.last_other_team END AS from_team
FROM lead l LEFT JOIN prior pr USING (team, season);
