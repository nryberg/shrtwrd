#!/bin/bash
#
# External stats collection script for shrtwrd.com
# This script runs on the host server (outside the container) and collects stats via API
# Place this script in /opt/shrtwrd/ on your server and run via cron
#

set -e

# Configuration
API_URL="https://shrtwrd.com/stats?format=json"
STATS_DIR="utils"
STATS_FILE="$STATS_DIR/stats.csv"
LOG_FILE="/var/log/shrtwrd_stats.log"

# Get absolute path for better debugging
ABSOLUTE_STATS_FILE="$(pwd)/$STATS_FILE"

# Create utils directory if it doesn't exist
mkdir -p "$STATS_DIR"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to handle errors
handle_error() {
    log_message "ERROR: $1"
    exit 1
}

log_message "Starting stats collection from $API_URL"
log_message "Working directory: $(pwd)"
log_message "Stats file will be saved to: $ABSOLUTE_STATS_FILE"

# Fetch stats from API with timeout
if ! STATS_JSON=$(curl -s --max-time 30 --fail "$API_URL" 2>/dev/null); then
    handle_error "Failed to fetch stats from API"
fi

# Validate JSON response
if ! echo "$STATS_JSON" | python3 -m json.tool > /dev/null 2>&1; then
    handle_error "Invalid JSON response from API"
fi

log_message "Successfully fetched stats from API"

# Process and save stats to CSV using Python
python3 -c "
import json, sys, csv, os
from datetime import datetime

try:
    # Parse the JSON data
    data = json.loads('''$STATS_JSON''')

    # Check if file exists to determine if we need headers
    file_exists = os.path.exists('$STATS_FILE')

    # Write to CSV
    with open('$STATS_FILE', 'a', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=['timestamp', 'total_words_served', 'fetch_time'])

        # Write header if file is new
        if not file_exists:
            writer.writeheader()

        # Write data
        writer.writerow({
            'timestamp': data.get('timestamp'),
            'total_words_served': data.get('total_words_served'),
            'fetch_time': datetime.now().isoformat()
        })

    print('SUCCESS: Stats saved to $STATS_FILE')

except Exception as e:
    print(f'ERROR: Failed to process stats - {e}')
    sys.exit(1)
" 2>&1 | while read line; do log_message "$line"; done

# Check if the operation was successful
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    log_message "Stats collection completed successfully"

    # Show current stats file size for monitoring
    if [ -f "$STATS_FILE" ]; then
        LINES=$(wc -l < "$STATS_FILE")
        SIZE=$(ls -la "$STATS_FILE")
        log_message "Stats file now contains $LINES lines"
        log_message "File details: $SIZE"
        log_message "File permissions: $(ls -la $STATS_FILE | cut -d' ' -f1,3,4)"
    fi
else
    handle_error "Failed to process and save stats"
fi
