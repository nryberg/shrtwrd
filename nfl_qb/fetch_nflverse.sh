#!/usr/bin/env bash
# Download the nflverse source files that build_exports.py reads.
# Usage: ./fetch_nflverse.sh [dest_dir]   (default: ./nflverse_raw)
set -euo pipefail
dest="${1:-nflverse_raw}"
mkdir -p "$dest"
rel=https://github.com/nflverse/nflverse-data/releases/download
for y in $(seq 2015 2026); do
  curl -sSfL -o "$dest/roster_$y.parquet" "$rel/rosters/roster_$y.parquet"
  curl -sSfL -o "$dest/stats_player_week_$y.parquet" "$rel/stats_player/stats_player_week_$y.parquet"
  curl -sSfL -o "$dest/snap_counts_$y.parquet" "$rel/snap_counts/snap_counts_$y.parquet"
done
curl -sSfL -o "$dest/players.parquet" "$rel/players/players.parquet"
curl -sSfL -o "$dest/games.csv" https://raw.githubusercontent.com/nflverse/nfldata/master/data/games.csv
echo "Downloaded to $dest"
