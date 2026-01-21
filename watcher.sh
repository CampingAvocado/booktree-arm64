#!/bin/sh

# Default vars
PYTHON="/venv/bin/python"
SCRIPT="/booktree/booktree.py"
CONFIG_DIR="/config"
SETTLE_DURATION=30
EXCLUDE_PATTERN="incomplete" # Regex pattern to ignore

# Validate config
if [ -z "$WATCH_DIR" ]; then
    echo "Error: WATCH_DIR environment variable is not set."
    exit 1
fi

# Function to run all configs
run_scan() {
    # Loop through all json files in /config
    for config_file in "$CONFIG_DIR"/*.json; do
        if [ -f "$config_file" ]; then
            echo "------------------------------------------------"
            echo "Running config: $(basename "$config_file")"
            echo "------------------------------------------------"
            $PYTHON $SCRIPT "$config_file"
        fi
    done
}

echo "Init: Running full scan on startup..."
run_scan

echo "Watcher: Monitoring $WATCH_DIR (excluding '$EXCLUDE_PATTERN')..."

while true; do
    # 1. BLOCK indefinitely until the FIRST event happens (excluding incomplete)
    inotifywait -r -e close_write -e moved_to -e create --exclude "$EXCLUDE_PATTERN" "$WATCH_DIR" > /dev/null 2>&1

    echo "Activity detected. Waiting for $WATCH_DIR to settle..."

    # 2. SETTLING LOOP
    while inotifywait -r -t "$SETTLE_DURATION" -e close_write -e moved_to -e create --exclude "$EXCLUDE_PATTERN" "$WATCH_DIR" > /dev/null 2>&1; do
        echo "New activity detected. Resetting ${SETTLE_DURATION}s timer..."
    done

    # 3. RUN
    echo "Directory stabilized. Syncing..."
    run_scan
    
    echo "Scan complete. Resuming watch."
done
