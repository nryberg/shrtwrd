#!/usr/bin/env python3
"""
Script to fetch stats from the shrtwrd API and save to CSV
"""

import requests
import csv
import json
from datetime import datetime
import os


def fetch_stats(base_url="https://shrtwrd.com"):
    """Fetch stats from the API"""
    try:
        response = requests.get(f"{base_url}/stats?format=json")
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error fetching stats: {e}")
        return None


def save_to_csv(stats_data, filename="stats.csv"):
    """Save stats data to CSV file"""
    if not stats_data:
        print("No data to save")
        return

    # Create utils directory if it doesn't exist
    os.makedirs(
        os.path.dirname(filename) if os.path.dirname(filename) else ".", exist_ok=True
    )

    # Check if file exists to determine if we need headers
    file_exists = os.path.exists(filename)

    with open(filename, "a", newline="") as csvfile:
        fieldnames = ["timestamp", "total_words_served", "fetch_time"]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

        # Write header if file is new
        if not file_exists:
            writer.writeheader()

        # Write data
        writer.writerow(
            {
                "timestamp": stats_data.get("timestamp"),
                "total_words_served": stats_data.get("total_words_served"),
                "fetch_time": datetime.now().isoformat(),
            }
        )

    print(f"Stats saved to {filename}")


def main():
    """Main function"""
    import argparse

    parser = argparse.ArgumentParser(description="Fetch shrtwrd stats and save to CSV")
    parser.add_argument(
        "--url",
        default="https://shrtwrd.com",
        help="Base URL for the API (default: https://shrtwrd.com)",
    )
    parser.add_argument(
        "--output",
        default="utils/stats.csv",
        help="Output CSV file (default: utils/stats.csv)",
    )
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")

    args = parser.parse_args()

    if args.verbose:
        print(f"Fetching stats from {args.url}")

    stats = fetch_stats(args.url)

    if stats:
        if args.verbose:
            print(f"Retrieved stats: {json.dumps(stats, indent=2)}")
        save_to_csv(stats, args.output)
    else:
        print("Failed to fetch stats")
        exit(1)


if __name__ == "__main__":
    main()
