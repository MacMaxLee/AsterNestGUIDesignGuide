// swift-tools-version:5.9
// =============================================================================
// Package.swift
// AIS Demo App - Swift Package Manager Configuration
// =============================================================================
//
// This package defines the AIS SwiftUI component library and demo app.
// It can be used as a local package dependency or built standalone.
//
// =============================================================================

import PackageDescription

let package = Package(
    name: "AISDemo",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        // The main executable app
        .executable(
            name: "AISDemo",
            targets: ["AISDemo"]
        ),
        // The reusable component library
        .library(
            name: "AISComponents",
            targets: ["AISComponents"]
        )
    ],
    dependencies: [
        // No external dependencies - pure SwiftUI
    ],
    targets: [
        // The demo app executable
        .executableTarget(
            name: "AISDemo",
            dependencies: ["AISComponents"],
            path: "AISDemo",
            exclude: ["Info.plist"],
            sources: [
                "AISDemoApp.swift",
                "Sources/Screens"
            ]
        ),
        // The reusable AIS component library
        .target(
            name: "AISComponents",
            path: "AISDemo/Sources",
            exclude: ["Screens"],
            sources: [
                "Core",
                "Components"
            ]
        ),
        // Unit tests for components
        .testTarget(
            name: "AISComponentsTests",
            dependencies: ["AISComponents"],
            path: "Tests"
        )
    ]
)
