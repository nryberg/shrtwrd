#!/bin/bash

# Script to fetch CSV stats from shrtwrd API and append to history file
# Usage: ./collect_stats.sh [base_url] [output_file]

# Default values
BASE_URL="${1:-https://shrtwrd.com}"
OUTPUT_FILE="${2:-utils/data/stats_history.csv}"
STATS_URL="${BASE_URL}/stats?format=csv"

# Create output directory if it doesn't exist
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR"

# Fetch CSV data
CSV_DATA=$(curl -s "$STATS_URL")

# Check if curl was successful
if [ $? -ne 0 ] || [ -z "$CSV_DATA" ]; then
    echo "Error: Failed to fetch stats from $STATS_URL"
    exit 1
fi

# Add header if this is a new file
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "$CSV_DATA" | head -n1 > "$OUTPUT_FILE"
fi

# Skip the header and append data
echo "$CSV_DATA" | tail -n +2 >> "$OUTPUT_FILE"

echo "Stats appended to $OUTPUT_FILE"
