# Stats Collection Setup Instructions

This document explains how to set up automated stats collection on your Ubuntu server.

## Overview

The stats collection runs **outside** the Docker container on the host server, calling the API every hour and saving historical data to a CSV file that can be downloaded via the `/stats.csv` endpoint.

## Setup Steps

### 1. Copy the script to your server

Copy `collect_stats.sh` to your server's project directory:

```bash
# On your server
cd /opt/shrtwrd
# Upload the collect_stats.sh file here
chmod +x collect_stats.sh
```

### 2. Test the script manually

```bash
cd /opt/shrtwrd
./collect_stats.sh
```

You should see output like:
```
2024-XX-XX XX:XX:XX - Starting stats collection from https://shrtwrd.com/stats?format=json
2024-XX-XX XX:XX:XX - Successfully fetched stats from API
2024-XX-XX XX:XX:XX - SUCCESS: Stats saved to utils/stats.csv
2024-XX-XX XX:XX:XX - Stats collection completed successfully
2024-XX-XX XX:XX:XX - Stats file now contains 2 lines
```

### 3. Set up the cron job

Edit the crontab:
```bash
crontab -e
```

Add this line to run every hour:
```bash
0 * * * * cd /opt/shrtwrd && ./collect_stats.sh
```

### 4. Verify the setup

Check that cron is running:
```bash
systemctl status cron
```

View your crontab:
```bash
crontab -l
```

Check the log file:
```bash
tail -f /var/log/shrtwrd_stats.log
```

## Files Created

- `utils/stats.csv` - Historical stats data (served by `/stats.csv` endpoint)
- `/var/log/shrtwrd_stats.log` - Collection log file

## Monitoring

- **Log file**: `/var/log/shrtwrd_stats.log` - Shows collection status and errors
- **Stats file**: `/opt/shrtwrd/utils/stats.csv` - The actual data
- **Web endpoint**: `https://shrtwrd.com/stats.csv` - Download the CSV file

## Troubleshooting

### Check if cron job is running
```bash
grep -i cron /var/log/syslog
```

### Test API manually
```bash
curl -s "https://shrtwrd.com/stats?format=json" | python3 -m json.tool
```

### Check disk space
```bash
df -h /opt/shrtwrd
```

### View recent log entries
```bash
tail -20 /var/log/shrtwrd_stats.log
```

## CSV Format

The generated CSV file has these columns:
- `timestamp` - When the stats were recorded by the API
- `total_words_served` - Cumulative word count
- `fetch_time` - When the stats were collected by this script

## Security Notes

- The script only reads from the public API endpoint
- No authentication required
- Logs are written to `/var/log/shrtwrd_stats.log`
- Data is stored in the project directory accessible to the web server