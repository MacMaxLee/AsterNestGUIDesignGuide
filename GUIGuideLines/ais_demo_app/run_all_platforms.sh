#!/bin/bash

# AIS Demo App - Run on All Available Platforms
# Launches the demo app on all detected platforms simultaneously

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}   ${GREEN}AIS Demo - Running on All Available Platforms${NC}          ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get dependencies first
echo -e "${YELLOW}▶${NC} Installing dependencies..."
flutter pub get > /dev/null 2>&1
echo -e "${GREEN}✓${NC} Dependencies ready"
echo ""

# Get list of available devices
echo -e "${YELLOW}▶${NC} Detecting available platforms..."
DEVICES=$(flutter devices --machine 2>/dev/null | grep -o '"id":"[^"]*"' | cut -d'"' -f4)

if [ -z "$DEVICES" ]; then
    echo -e "${RED}✗${NC} No devices found!"
    echo "Please start an emulator/simulator or connect a device."
    exit 1
fi

echo -e "${GREEN}✓${NC} Found devices:"
flutter devices 2>/dev/null | grep -E "•|─" | head -20
echo ""

# Array to store PIDs
declare -a PIDS

# Function to launch on a platform
launch_platform() {
    local device="$1"
    local name="$2"

    echo -e "${CYAN}→${NC} Launching on ${name}..."

    # Create a temporary log file
    local logfile="/tmp/ais_demo_${device}.log"

    # Launch in background
    flutter run -d "$device" > "$logfile" 2>&1 &
    local pid=$!
    PIDS+=($pid)

    echo -e "  ${GREEN}✓${NC} Started (PID: $pid, log: $logfile)"
}

# Launch on each available device
echo -e "${YELLOW}▶${NC} Launching applications..."
echo ""

for device in $DEVICES; do
    case "$device" in
        macos)
            launch_platform "macos" "macOS Desktop"
            ;;
        chrome)
            launch_platform "chrome" "Chrome Web"
            ;;
        *iPhone*|*iphone*|*simulator*)
            launch_platform "$device" "iOS Simulator"
            ;;
        *emulator*|*android*)
            launch_platform "$device" "Android Emulator"
            ;;
        linux)
            launch_platform "linux" "Linux Desktop"
            ;;
        windows)
            launch_platform "windows" "Windows Desktop"
            ;;
        *)
            launch_platform "$device" "$device"
            ;;
    esac
done

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}All platforms launched!${NC}"
echo ""
echo "Running processes:"
for pid in "${PIDS[@]}"; do
    if ps -p $pid > /dev/null 2>&1; then
        echo -e "  ${GREEN}●${NC} PID $pid - Running"
    else
        echo -e "  ${RED}●${NC} PID $pid - Stopped"
    fi
done
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop all instances${NC}"
echo ""

# Wait for all processes and handle Ctrl+C
cleanup() {
    echo ""
    echo -e "${YELLOW}▶${NC} Stopping all instances..."
    for pid in "${PIDS[@]}"; do
        if ps -p $pid > /dev/null 2>&1; then
            kill $pid 2>/dev/null || true
        fi
    done
    echo -e "${GREEN}✓${NC} All instances stopped"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Wait for all background processes
wait
