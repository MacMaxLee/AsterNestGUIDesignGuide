# AIS Demo App Makefile
# Asternest Interface Standard v1.0 Flutter Demo

.PHONY: all run run-macos run-ios run-web run-android clean analyze test help

# Default target
all: help

# Get dependencies
deps:
	@echo "📦 Getting dependencies..."
	@flutter pub get

# Analyze code
analyze:
	@echo "🔍 Analyzing code..."
	@flutter analyze

# Run on macOS
run-macos: deps
	@echo "🖥️  Running on macOS..."
	@flutter run -d macos

# Run on iOS Simulator
run-ios: deps
	@echo "📱 Running on iOS Simulator..."
	@flutter run -d "iPhone"

# Run on Chrome (Web)
run-web: deps
	@echo "🌐 Running on Chrome..."
	@flutter run -d chrome

# Run on Android
run-android: deps
	@echo "🤖 Running on Android..."
	@flutter run -d "emulator"

# Run interactive selector
run: deps
	@./run.sh

# Run on all platforms
run-all: deps
	@./run_all_platforms.sh

# Build for macOS
build-macos: deps
	@echo "🏗️  Building for macOS..."
	@flutter build macos

# Build for iOS
build-ios: deps
	@echo "🏗️  Building for iOS..."
	@flutter build ios

# Build for Web
build-web: deps
	@echo "🏗️  Building for Web..."
	@flutter build web

# Build for Android
build-android: deps
	@echo "🏗️  Building for Android..."
	@flutter build apk

# Clean build artifacts
clean:
	@echo "🧹 Cleaning..."
	@flutter clean
	@rm -rf build/

# List connected devices
devices:
	@flutter devices

# Run tests (placeholder - add tests as needed)
test:
	@echo "🧪 Running tests..."
	@flutter test

# Help
help:
	@echo ""
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║     AIS Demo App - Asternest Interface Standard v1.0      ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Available commands:"
	@echo ""
	@echo "  make run          - Interactive platform selector"
	@echo "  make run-all      - Run on all available platforms"
	@echo "  make run-macos    - Run on macOS Desktop"
	@echo "  make run-ios      - Run on iOS Simulator"
	@echo "  make run-web      - Run on Chrome (Web)"
	@echo "  make run-android  - Run on Android Emulator"
	@echo ""
	@echo "  make build-macos  - Build for macOS"
	@echo "  make build-ios    - Build for iOS"
	@echo "  make build-web    - Build for Web"
	@echo "  make build-android- Build APK for Android"
	@echo ""
	@echo "  make analyze      - Analyze code for issues"
	@echo "  make test         - Run tests"
	@echo "  make devices      - List connected devices"
	@echo "  make clean        - Clean build artifacts"
	@echo "  make deps         - Get dependencies"
	@echo ""
