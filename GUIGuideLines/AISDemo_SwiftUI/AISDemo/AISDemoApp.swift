// =============================================================================
// AISDemoApp.swift
// Asternest Interface Standard (AIS) v1.0 - SwiftUI Demo Application
// =============================================================================
//
// PURPOSE:
// Main entry point for the AIS Demo application. Demonstrates all AIS-compliant
// UI components in a SwiftUI context with proper token application.
//
// HOW TO USE:
// 1. Open this project in Xcode
// 2. Build and run (Cmd+R)
// 3. Navigate through component demos
//
// REQUIREMENTS:
// - macOS 12.0+ / iOS 15.0+
// - Xcode 14.0+
// - Swift 5.7+
//
// =============================================================================

import SwiftUI

// MARK: - App Entry Point

/// The main app struct conforming to the App protocol.
/// This is the entry point for the SwiftUI application lifecycle.
///
/// ## Key Responsibilities
/// - Configure the app's scene hierarchy
/// - Apply global AIS token theming
/// - Set up app-wide environment values
///
@main
struct AISDemoApp: App {
    // MARK: - State

    /// Controls the current color scheme (light/dark mode)
    @AppStorage("colorScheme") private var colorSchemePreference: ColorSchemePreference = .system

    /// Access to system color scheme
    @Environment(\.colorScheme) private var systemColorScheme

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            HomeScreen()
                .withAISTokens()
                .preferredColorScheme(effectiveColorScheme)
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1200, height: 800)
        #endif

        #if os(macOS)
        // Settings window for macOS
        Settings {
            SettingsView(colorSchemePreference: $colorSchemePreference)
                .withAISTokens()
        }
        #endif
    }

    // MARK: - Computed Properties

    /// Resolves the effective color scheme based on user preference
    private var effectiveColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// MARK: - Color Scheme Preference

/// User preference for color scheme
enum ColorSchemePreference: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

// MARK: - Settings View (macOS)

#if os(macOS)
/// Settings view for macOS app preferences
struct SettingsView: View {
    @Binding var colorSchemePreference: ColorSchemePreference
    @Environment(\.aisTokens) private var tokens

    var body: some View {
        Form {
            Picker("Appearance", selection: $colorSchemePreference) {
                ForEach(ColorSchemePreference.allCases, id: \.self) { preference in
                    Text(preference.rawValue).tag(preference)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(AISSpacing.lg)
        .frame(width: 300, height: 100)
    }
}
#endif

// =============================================================================
// MARK: - Documentation
// =============================================================================
//
// ## AIS COMPONENT LIBRARY OVERVIEW
//
// This SwiftUI implementation provides the following AIS-compliant components:
//
// ### Core Components
//
// 1. **AISTokens** (Core/AISTokens.swift)
//    - 9 semantic action & state tokens
//    - Light/dark mode support
//    - Environment-based injection
//    - Spacing and radius constants
//
// 2. **AISButton** (Components/AISButton.swift)
//    - Semantic button types (primary, confirm, caution, destructive, neutral)
//    - Style variants (filled, outlined, text, iconOnly)
//    - Size presets (small, medium, large)
//    - Loading and disabled states
//
// 3. **AISListDetailShell** (Components/AISListDetailShell.swift)
//    - Generic list-detail pattern
//    - State retention across edit cycles (C-05)
//    - Selection guard with unsaved changes (C-06)
//    - Dual empty states (C-07)
//
// 4. **AISValueComponent** (Components/AISValueComponent.swift)
//    - Generic numeric display
//    - Required annotations (C-04)
//    - Format options (integer, decimal, currency, percentage, etc.)
//    - Comparison/change indicators
//
// 5. **AISDataGrid** (Components/AISDataGrid.swift)
//    - Generic Excel-like data grid
//    - Column sorting and filtering (C-35, C-36)
//    - Selection (single/multiple)
//    - Export functionality
//
// 6. **AISMediaPicker** (Components/AISMediaPicker.swift)
//    - File selection with metadata extraction
//    - MD5 checksum computation
//    - MIME type detection
//    - Multiple file type filters
//
// 7. **AISErrorEnvelope** (Components/AISErrorEnvelope.swift)
//    - Loading state wrapper
//    - Error display with recovery actions
//    - Inline errors for forms
//    - Error banners for notifications
//
// 8. **AISStateBadge** (Components/AISStateBadge.swift)
//    - Semantic state indicators
//    - Style variants (standard, pill, outlined, compact, dot)
//    - State progress indicator
//    - State legend
//
// ### Design Principles
//
// - **Semantic-First**: Components are categorized by meaning, not appearance
// - **Type-Safe**: Full Swift generics for compile-time safety
// - **Accessible**: Color is never the only signal (AIS §2.3)
// - **Documented**: Extensive comments explain AIS concepts
// - **Consistent**: Same component looks the same everywhere
//
// ### Conformance Tests Covered
//
// - C-04: Value annotations required
// - C-05: List state retention
// - C-06: Selection guard
// - C-07: Dual empty states
// - C-35: Column sorting
// - C-36: Column filtering
//
// =============================================================================
