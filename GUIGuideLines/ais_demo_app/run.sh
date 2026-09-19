#!/bin/bash

# AIS Demo App Runner Script
# Asternest Interface Standard v1.0 Flutter Demo

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}     ${GREEN}AIS Demo App - Asternest Interface Standard v1.0${NC}      ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print step
print_step() {
    echo -e "${YELLOW}▶${NC} $1"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print error
print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if Flutter is installed
print_step "Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi
print_success "Flutter found: $(flutter --version | head -1)"

# Get dependencies
print_step "Getting dependencies..."
flutter pub get
print_success "Dependencies installed"

# Analyze code
print_step "Analyzing code..."
ERRORS=$(flutter analyze 2>&1 | grep -c " error " || true)
if [ "$ERRORS" -gt 0 ]; then
    print_error "Found $ERRORS errors in code"
    flutter analyze
    exit 1
fi
print_success "No errors found"

# Show available platforms
echo ""
print_step "Available platforms:"
echo ""

# Detect available devices
DEVICES=$(flutter devices 2>/dev/null)

# Parse command line arguments
PLATFORM="${1:-}"
DEVICE=""

show_menu() {
    echo "  1) macOS (Desktop)"
    echo "  2) iOS Simulator"
    echo "  3) Chrome (Web)"
    echo "  4) Android Emulator"
    echo "  5) List all devices"
    echo "  6) Exit"
    echo ""
}

run_app() {
    local target="$1"
    echo ""
    print_step "Launching AIS Demo App on $target..."
    echo ""
    echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
    echo ""

    case "$target" in
        "macos")
            flutter run -d macos
            ;;
        "ios")
            flutter run -d "iPhone"
            ;;
        "chrome")
            flutter run -d chrome
            ;;
        "android")
            flutter run -d "emulator"
            ;;
        *)
            flutter run -d "$target"
            ;;
    esac
}

# If platform specified as argument
if [ -n "$PLATFORM" ]; then
    case "$PLATFORM" in
        "macos"|"mac"|"desktop")
            run_app "macos"
            ;;
        "ios"|"iphone"|"simulator")
            run_app "ios"
            ;;
        "web"|"chrome"|"browser")
            run_app "chrome"
            ;;
        "android")
            run_app "android"
            ;;
        *)
            run_app "$PLATFORM"
            ;;
    esac
    exit 0
fi

# Interactive menu
while true; do
    show_menu
    read -p "Select platform (1-6): " choice

    case $choice in
        1)
            run_app "macos"
            break
            ;;
        2)
            run_app "ios"
            break
            ;;
        3)
            run_app "chrome"
            break
            ;;
        4)
            run_app "android"
            break
            ;;
        5)
            echo ""
            print_step "Connected devices:"
            flutter devices
            echo ""
            read -p "Enter device ID to run on: " device_id
            if [ -n "$device_id" ]; then
                run_app "$device_id"
                break
            fi
            ;;
        6)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid option. Please select 1-6."
            echo ""
            ;;
    esac
done
