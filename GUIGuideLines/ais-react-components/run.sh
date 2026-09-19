#!/bin/bash

# AIS React Components - Run Script
# Usage: ./run.sh [command]
#
# Commands:
#   dev       - Start development server (default)
#   build     - Build the library
#   preview   - Preview production build
#   install   - Install dependencies
#   clean     - Remove node_modules and reinstall

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║       AIS React Components - Asternest Interface Standard ║"
    echo "║                         v1.0                              ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_node() {
    if ! command -v node &> /dev/null; then
        echo -e "${RED}Error: Node.js is not installed${NC}"
        echo "Please install Node.js from https://nodejs.org/"
        exit 1
    fi
    echo -e "${GREEN}✓ Node.js $(node --version)${NC}"
}

check_npm() {
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}Error: npm is not installed${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ npm $(npm --version)${NC}"
}

install_deps() {
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}Installing dependencies...${NC}"
        npm install
        echo -e "${GREEN}✓ Dependencies installed${NC}"
    else
        echo -e "${GREEN}✓ Dependencies already installed${NC}"
    fi
}

cmd_dev() {
    print_header
    check_node
    check_npm
    install_deps
    echo ""
    echo -e "${GREEN}Starting development server...${NC}"
    echo -e "${YELLOW}Open http://localhost:5173 in your browser${NC}"
    echo ""
    npm run dev
}

cmd_build() {
    print_header
    check_node
    check_npm
    install_deps
    echo ""
    echo -e "${GREEN}Building library...${NC}"
    npm run build
    echo -e "${GREEN}✓ Build complete! Output in dist/${NC}"
}

cmd_preview() {
    print_header
    check_node
    check_npm
    if [ ! -d "dist" ]; then
        echo -e "${YELLOW}No build found. Building first...${NC}"
        npm run build
    fi
    echo ""
    echo -e "${GREEN}Starting preview server...${NC}"
    npm run preview
}

cmd_install() {
    print_header
    check_node
    check_npm
    echo -e "${YELLOW}Installing dependencies...${NC}"
    npm install
    echo -e "${GREEN}✓ Dependencies installed${NC}"
}

cmd_clean() {
    print_header
    echo -e "${YELLOW}Cleaning...${NC}"
    rm -rf node_modules dist
    echo -e "${GREEN}✓ Cleaned node_modules and dist${NC}"
    echo ""
    echo -e "${YELLOW}Reinstalling dependencies...${NC}"
    npm install
    echo -e "${GREEN}✓ Dependencies reinstalled${NC}"
}

cmd_help() {
    print_header
    echo "Usage: ./run.sh [command]"
    echo ""
    echo "Commands:"
    echo "  dev       Start development server (default)"
    echo "  build     Build the library"
    echo "  preview   Preview production build"
    echo "  install   Install dependencies"
    echo "  clean     Remove node_modules and reinstall"
    echo "  help      Show this help message"
    echo ""
}

# Main
case "${1:-dev}" in
    dev)
        cmd_dev
        ;;
    build)
        cmd_build
        ;;
    preview)
        cmd_preview
        ;;
    install)
        cmd_install
        ;;
    clean)
        cmd_clean
        ;;
    help|--help|-h)
        cmd_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
