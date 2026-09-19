#!/bin/bash

# AIS Demo Apps - Master Run Script
# =================================
# Run any of the AIS demo implementations
#
# Usage: ./run_demos.sh [app]
#
# Apps:
#   react     - React/TypeScript demo (localhost:5173)
#   swiftui   - SwiftUI macOS demo
#   flutter   - Flutter demo (requires platform selection)
#   all       - Show status of all apps

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Paths
REACT_DIR="$SCRIPT_DIR/GUIGuideLines/ais-react-components"
SWIFTUI_DIR="$SCRIPT_DIR/GUIGuideLines/AISDemo_SwiftUI"
FLUTTER_DIR="$SCRIPT_DIR/GUIGuideLines/ais_demo_app"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_banner() {
    echo -e "${CYAN}"
    echo "╔═════════════════════════════════════════════════════════════════╗"
    echo "║                                                                 ║"
    echo "║     █████╗ ██╗███████╗    ██████╗ ███████╗███╗   ███╗ ██████╗   ║"
    echo "║    ██╔══██╗██║██╔════╝    ██╔══██╗██╔════╝████╗ ████║██╔═══██╗  ║"
    echo "║    ███████║██║███████╗    ██║  ██║█████╗  ██╔████╔██║██║   ██║  ║"
    echo "║    ██╔══██║██║╚════██║    ██║  ██║██╔══╝  ██║╚██╔╝██║██║   ██║  ║"
    echo "║    ██║  ██║██║███████║    ██████╔╝███████╗██║ ╚═╝ ██║╚██████╔╝  ║"
    echo "║    ╚═╝  ╚═╝╚═╝╚══════╝    ╚═════╝ ╚══════╝╚═╝     ╚═╝ ╚═════╝   ║"
    echo "║                                                                 ║"
    echo "║           Asternest Interface Standard v1.0                     ║"
    echo "║                                                                 ║"
    echo "╚═════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_react() {
    if [ -d "$REACT_DIR" ] && [ -f "$REACT_DIR/package.json" ]; then
        echo -e "${GREEN}✓${NC} React/TypeScript"
        return 0
    else
        echo -e "${RED}✗${NC} React/TypeScript (not found)"
        return 1
    fi
}

check_swiftui() {
    if [ -d "$SWIFTUI_DIR" ] && [ -f "$SWIFTUI_DIR/AISDemo.xcodeproj/project.pbxproj" ]; then
        echo -e "${GREEN}✓${NC} SwiftUI macOS"
        return 0
    else
        echo -e "${RED}✗${NC} SwiftUI macOS (not found)"
        return 1
    fi
}

check_flutter() {
    if [ -d "$FLUTTER_DIR" ] && [ -f "$FLUTTER_DIR/pubspec.yaml" ]; then
        echo -e "${GREEN}✓${NC} Flutter"
        return 0
    else
        echo -e "${RED}✗${NC} Flutter (not found)"
        return 1
    fi
}

run_react() {
    echo -e "${BLUE}Starting React demo...${NC}"
    cd "$REACT_DIR"

    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}Installing dependencies...${NC}"
        npm install
    fi

    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  React demo running at:               ║${NC}"
    echo -e "${GREEN}║  ${YELLOW}http://localhost:5173${GREEN}                ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
    echo ""

    npm run dev
}

run_swiftui() {
    echo -e "${BLUE}Building and running SwiftUI demo...${NC}"
    cd "$SWIFTUI_DIR"

    echo -e "${YELLOW}Building with xcodebuild...${NC}"
    xcodebuild -scheme AISDemo -destination 'platform=macOS' build 2>&1 | tail -5

    # Find and run the app
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "AISDemo.app" -path "*/Build/Products/Debug/*" 2>/dev/null | head -1)

    if [ -n "$APP_PATH" ]; then
        echo ""
        echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  Launching SwiftUI AISDemo app...     ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
        echo ""
        open "$APP_PATH"
    else
        echo -e "${RED}Could not find built app. Try opening in Xcode:${NC}"
        echo "open $SWIFTUI_DIR/AISDemo.xcodeproj"
    fi
}

run_flutter() {
    echo -e "${BLUE}Starting Flutter demo...${NC}"
    cd "$FLUTTER_DIR"

    echo ""
    echo "Select platform:"
    echo "  1) macOS"
    echo "  2) iOS Simulator"
    echo "  3) Chrome (web)"
    echo ""
    read -p "Enter choice [1-3]: " choice

    case $choice in
        1)
            echo -e "${GREEN}Running on macOS...${NC}"
            flutter run -d macos
            ;;
        2)
            echo -e "${GREEN}Running on iOS Simulator...${NC}"
            flutter run -d ios
            ;;
        3)
            echo -e "${GREEN}Running on Chrome...${NC}"
            flutter run -d chrome
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
}

show_status() {
    print_banner
    echo "Available Demos:"
    echo "════════════════"
    echo ""
    check_react
    check_swiftui
    check_flutter
    echo ""
    echo "Usage: ./run_demos.sh [react|swiftui|flutter]"
    echo ""
}

show_help() {
    print_banner
    echo "Usage: ./run_demos.sh [command]"
    echo ""
    echo "Commands:"
    echo "  react     Run React/TypeScript demo (localhost:5173)"
    echo "  swiftui   Build and run SwiftUI macOS demo"
    echo "  flutter   Run Flutter demo (select platform)"
    echo "  status    Show status of all demos"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./run_demos.sh react     # Start React dev server"
    echo "  ./run_demos.sh swiftui   # Build and launch SwiftUI app"
    echo "  ./run_demos.sh flutter   # Run Flutter (prompts for platform)"
    echo ""
}

# Make scripts executable
chmod +x "$REACT_DIR/run.sh" 2>/dev/null || true
chmod +x "$FLUTTER_DIR/run.sh" 2>/dev/null || true

# Main
case "${1:-status}" in
    react)
        print_banner
        run_react
        ;;
    swiftui)
        print_banner
        run_swiftui
        ;;
    flutter)
        print_banner
        run_flutter
        ;;
    status|all)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
