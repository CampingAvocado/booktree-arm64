#!/bin/sh

# Default vars
PYTHON="/venv/bin/python"
SCRIPT="/booktree/booktree.py"
CONFIG="/config/config.json"
SETTLE_DURATION=30  # Time in seconds the directory must be quiet before running

# Validate config
if [ -z "$WATCH_DIR" ]; then
    echo "Error: WATCH_DIR environment variable is not set."
    exit 1
fi

echo "Init: Running full scan on startup..."
$PYTHON $SCRIPT $CONFIG

echo "Watcher: Monitoring $WATCH_DIR for changes..."
echo "Watcher: Will trigger after $SETTLE_DURATION seconds of silence."

while true; do
    # 1. BLOCK indefinitely until the FIRST event happens
    # We filter for close_write (file finish), moved_to (file move), and create
    inotifywait -r -e close_write -e moved_to -e create "$WATCH_DIR" > /dev/null 2>&1

    echo "Activity detected. Waiting for $WATCH_DIR to settle..."

    # 2. SETTLING LOOP
    # We keep waiting for SETTLE_DURATION.
    # If an event happens ('inotifywait' returns 0), the loop repeats (timer resets).
    # If the timeout expires ('inotifywait' returns 2), the loop breaks.
    while inotifywait -r -t "$SETTLE_DURATION" -e close_write -e moved_to -e create "$WATCH_DIR" > /dev/null 2>&1; do
        echo "New activity detected. Resetting ${SETTLE_DURATION}s timer..."
    done

    # 3. RUN
    echo "Directory stabilized. Syncing..."
    $PYTHON $SCRIPT $CONFIG
    
    echo "Scan complete. Resuming watch."
done
