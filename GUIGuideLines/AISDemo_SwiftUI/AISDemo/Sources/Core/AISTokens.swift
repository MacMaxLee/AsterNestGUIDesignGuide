// =============================================================================
// AISTokens.swift
// Asternest Interface Standard (AIS) v1.0 - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// This file defines the core semantic token system as specified in AIS §2.
// Semantic tokens ensure consistent visual language across the application
// by mapping MEANING to APPEARANCE, not appearance directly.
//
// KEY CONCEPTS:
// - Each token represents a semantic meaning (e.g., "primary action", "error state")
// - Tokens include both a color AND a paired icon (AIS §2.3)
// - Color alone is NEVER the only signal (accessibility requirement)
// - Tokens adapt automatically to light/dark mode
//
// USAGE:
// ```swift
// // Access tokens via environment
// @Environment(\.aisTokens) var tokens
//
// // Use in views
// Text("Save").foregroundColor(tokens.actionPrimary.color)
// Image(systemName: tokens.actionConfirm.iconName)
// ```
//
// =============================================================================

import SwiftUI

// MARK: - Semantic Token Protocol

/// Protocol defining what a semantic token must provide.
/// Every token MUST have both a color and an icon to satisfy AIS §2.3
/// (color is never the only signal).
///
/// - Important: Conforming types must provide meaningful icon pairing.
///              Using a blank or invisible icon violates the standard.
public protocol AISSemanticToken {
    /// The semantic color for this token
    var color: Color { get }

    /// The SF Symbol name paired with this token
    /// This icon MUST be used alongside the color to convey meaning
    var iconName: String { get }
}

// MARK: - Token Implementation

/// A concrete implementation of a semantic token.
/// Immutable value type that pairs a color with its required icon.
///
/// Example:
/// ```swift
/// let confirm = AISToken(color: .green, iconName: "checkmark.circle.fill")
/// ```
public struct AISToken: AISSemanticToken {
    public let color: Color
    public let iconName: String

    public init(color: Color, iconName: String) {
        self.color = color
        self.iconName = iconName
    }
}

// MARK: - Core Token Set (AIS §2.2)

/// The complete AIS token set containing all 9 core semantic tokens.
/// This struct provides the single source of truth for all semantic colors
/// and their paired icons throughout the application.
///
/// ## Token Categories
///
/// ### Action Tokens (user-initiated operations)
/// - `actionPrimary`: Brand-aligned primary actions (Save, Submit, Continue)
/// - `actionConfirm`: Affirmative completion actions (Confirm, Approve, Accept)
/// - `actionCaution`: Reversible but significant actions (Edit, Modify)
/// - `actionDestructive`: Irreversible harmful actions (Delete, Remove permanently)
/// - `actionNeutral`: Non-committal actions (Cancel, Close, Back)
///
/// ### State Tokens (system-communicated conditions)
/// - `stateError`: Something failed, user action required
/// - `stateWarning`: Potential issue, user attention needed
/// - `stateInfo`: Neutral information, no action required
/// - `stateUnavailable`: Value is absent, NOT zero (important distinction)
///
/// ## Light vs Dark Mode
/// Create appropriate instances for each color scheme using the factory methods.
///
public struct AISTokenSet {

    // MARK: - Action Tokens

    /// Primary brand action - most important actionable element on screen.
    /// Use for: Save, Submit, Continue, primary CTAs
    /// Icon: Indicates forward progress or primary action
    public let actionPrimary: AISToken

    /// Confirmation/success action - affirms completion or approval.
    /// Use for: Confirm, Approve, Accept, Mark Complete
    /// Icon: Checkmark indicates successful completion
    public let actionConfirm: AISToken

    /// Caution action - reversible but significant changes.
    /// Use for: Edit, Modify, Update (when changes are notable)
    /// Icon: Pencil indicates modification capability
    public let actionCaution: AISToken

    /// Destructive action - irreversible or harmful operations.
    /// Use for: Delete, Remove, Cancel subscription
    /// Icon: Trash indicates removal/destruction
    /// - Warning: Always require confirmation for destructive actions
    public let actionDestructive: AISToken

    /// Neutral action - non-committal, can always be performed.
    /// Use for: Cancel, Close, Back, Dismiss
    /// Icon: X mark indicates dismissal without commitment
    public let actionNeutral: AISToken

    // MARK: - State Tokens

    /// Error state - something failed, requires user attention.
    /// Use for: Validation errors, failed operations, system errors
    /// Icon: Exclamation in circle draws attention to problem
    public let stateError: AISToken

    /// Warning state - potential issue, should be addressed.
    /// Use for: Approaching limits, deprecated features, risky situations
    /// Icon: Triangle with exclamation signals caution
    public let stateWarning: AISToken

    /// Informational state - neutral information, no action required.
    /// Use for: Tips, notes, status updates, help text
    /// Icon: "i" in circle indicates supplementary information
    public let stateInfo: AISToken

    /// Unavailable state - value is absent (NOT zero).
    /// Use for: Missing data, null values, not-yet-loaded content
    /// Icon: Minus in circle indicates absence
    /// - Important: This is semantically different from a zero value.
    ///              "No value" ≠ "value of zero"
    public let stateUnavailable: AISToken

    // MARK: - Surface Colors

    /// Primary background surface
    public let surface: Color

    /// Secondary/elevated background surface
    public let surfaceSecondary: Color

    /// Primary text/foreground color on surfaces
    public let onSurface: Color

    /// Secondary/muted text color on surfaces
    public let onSurfaceSecondary: Color

    // MARK: - Initialization

    public init(
        actionPrimary: AISToken,
        actionConfirm: AISToken,
        actionCaution: AISToken,
        actionDestructive: AISToken,
        actionNeutral: AISToken,
        stateError: AISToken,
        stateWarning: AISToken,
        stateInfo: AISToken,
        stateUnavailable: AISToken,
        surface: Color,
        surfaceSecondary: Color,
        onSurface: Color,
        onSurfaceSecondary: Color
    ) {
        self.actionPrimary = actionPrimary
        self.actionConfirm = actionConfirm
        self.actionCaution = actionCaution
        self.actionDestructive = actionDestructive
        self.actionNeutral = actionNeutral
        self.stateError = stateError
        self.stateWarning = stateWarning
        self.stateInfo = stateInfo
        self.stateUnavailable = stateUnavailable
        self.surface = surface
        self.surfaceSecondary = surfaceSecondary
        self.onSurface = onSurface
        self.onSurfaceSecondary = onSurfaceSecondary
    }

    // MARK: - Factory Methods

    /// Creates the light mode token set.
    /// Colors are optimized for light backgrounds with WCAG AA contrast.
    public static var light: AISTokenSet {
        AISTokenSet(
            // Action tokens - Light mode
            actionPrimary: AISToken(
                color: Color(red: 0.0, green: 0.478, blue: 1.0), // iOS blue
                iconName: "arrow.right.circle.fill"
            ),
            actionConfirm: AISToken(
                color: Color(red: 0.204, green: 0.780, blue: 0.349), // Green
                iconName: "checkmark.circle.fill"
            ),
            actionCaution: AISToken(
                color: Color(red: 1.0, green: 0.584, blue: 0.0), // Orange
                iconName: "pencil.circle.fill"
            ),
            actionDestructive: AISToken(
                color: Color(red: 1.0, green: 0.231, blue: 0.188), // Red
                iconName: "trash.fill"
            ),
            actionNeutral: AISToken(
                color: Color(red: 0.557, green: 0.557, blue: 0.576), // Gray
                iconName: "xmark.circle.fill"
            ),

            // State tokens - Light mode
            stateError: AISToken(
                color: Color(red: 1.0, green: 0.231, blue: 0.188),
                iconName: "exclamationmark.circle.fill"
            ),
            stateWarning: AISToken(
                color: Color(red: 1.0, green: 0.8, blue: 0.0), // Yellow
                iconName: "exclamationmark.triangle.fill"
            ),
            stateInfo: AISToken(
                color: Color(red: 0.0, green: 0.478, blue: 1.0),
                iconName: "info.circle.fill"
            ),
            stateUnavailable: AISToken(
                color: Color(red: 0.6, green: 0.6, blue: 0.6),
                iconName: "minus.circle.fill"
            ),

            // Surface colors - Light mode
            surface: Color(red: 1.0, green: 1.0, blue: 1.0),
            surfaceSecondary: Color(red: 0.95, green: 0.95, blue: 0.97),
            onSurface: Color(red: 0.0, green: 0.0, blue: 0.0),
            onSurfaceSecondary: Color(red: 0.4, green: 0.4, blue: 0.4)
        )
    }

    /// Creates the dark mode token set.
    /// Colors are adjusted for dark backgrounds while maintaining contrast.
    public static var dark: AISTokenSet {
        AISTokenSet(
            // Action tokens - Dark mode (slightly adjusted for dark backgrounds)
            actionPrimary: AISToken(
                color: Color(red: 0.039, green: 0.518, blue: 1.0),
                iconName: "arrow.right.circle.fill"
            ),
            actionConfirm: AISToken(
                color: Color(red: 0.188, green: 0.820, blue: 0.345),
                iconName: "checkmark.circle.fill"
            ),
            actionCaution: AISToken(
                color: Color(red: 1.0, green: 0.624, blue: 0.039),
                iconName: "pencil.circle.fill"
            ),
            actionDestructive: AISToken(
                color: Color(red: 1.0, green: 0.271, blue: 0.227),
                iconName: "trash.fill"
            ),
            actionNeutral: AISToken(
                color: Color(red: 0.6, green: 0.6, blue: 0.62),
                iconName: "xmark.circle.fill"
            ),

            // State tokens - Dark mode
            stateError: AISToken(
                color: Color(red: 1.0, green: 0.271, blue: 0.227),
                iconName: "exclamationmark.circle.fill"
            ),
            stateWarning: AISToken(
                color: Color(red: 1.0, green: 0.84, blue: 0.039),
                iconName: "exclamationmark.triangle.fill"
            ),
            stateInfo: AISToken(
                color: Color(red: 0.039, green: 0.518, blue: 1.0),
                iconName: "info.circle.fill"
            ),
            stateUnavailable: AISToken(
                color: Color(red: 0.5, green: 0.5, blue: 0.5),
                iconName: "minus.circle.fill"
            ),

            // Surface colors - Dark mode
            surface: Color(red: 0.11, green: 0.11, blue: 0.118),
            surfaceSecondary: Color(red: 0.17, green: 0.17, blue: 0.18),
            onSurface: Color(red: 1.0, green: 1.0, blue: 1.0),
            onSurfaceSecondary: Color(red: 0.6, green: 0.6, blue: 0.6)
        )
    }
}

// MARK: - Environment Integration

/// Environment key for accessing AIS tokens throughout the view hierarchy.
/// This enables dependency injection of the token set.
private struct AISTokensKey: EnvironmentKey {
    static let defaultValue: AISTokenSet = .light
}

/// Extension to provide convenient access to AIS tokens via the environment.
///
/// Usage:
/// ```swift
/// struct MyView: View {
///     @Environment(\.aisTokens) var tokens
///
///     var body: some View {
///         Button("Save") { }
///             .foregroundColor(tokens.actionPrimary.color)
///     }
/// }
/// ```
public extension EnvironmentValues {
    var aisTokens: AISTokenSet {
        get { self[AISTokensKey.self] }
        set { self[AISTokensKey.self] = newValue }
    }
}

// MARK: - View Extension for Token Application

/// Convenience extension for applying tokens to the view hierarchy.
public extension View {
    /// Applies the appropriate AIS token set based on color scheme.
    /// Call this on your root view to enable token access throughout.
    ///
    /// Example:
    /// ```swift
    /// @main
    /// struct MyApp: App {
    ///     var body: some Scene {
    ///         WindowGroup {
    ///             ContentView()
    ///                 .withAISTokens()
    ///         }
    ///     }
    /// }
    /// ```
    func withAISTokens() -> some View {
        modifier(AISTokenModifier())
    }
}

/// View modifier that automatically applies light/dark tokens based on color scheme.
private struct AISTokenModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .environment(\.aisTokens, colorScheme == .dark ? .dark : .light)
    }
}

// MARK: - Spacing Constants (AIS Compliant)

/// Standard spacing values for consistent layout throughout the app.
/// These values follow an 8-point grid system for visual harmony.
public enum AISSpacing {
    /// Extra small spacing: 4pt
    public static let xs: CGFloat = 4

    /// Small spacing: 8pt
    public static let sm: CGFloat = 8

    /// Medium spacing: 16pt (base unit)
    public static let md: CGFloat = 16

    /// Large spacing: 24pt
    public static let lg: CGFloat = 24

    /// Extra large spacing: 32pt
    public static let xl: CGFloat = 32

    /// Extra extra large spacing: 48pt
    public static let xxl: CGFloat = 48
}

// MARK: - Corner Radius Constants

/// Standard corner radius values for consistent rounded corners.
public enum AISRadius {
    /// Small radius: 4pt (subtle rounding)
    public static let sm: CGFloat = 4

    /// Medium radius: 8pt (standard buttons, cards)
    public static let md: CGFloat = 8

    /// Large radius: 12pt (prominent elements)
    public static let lg: CGFloat = 12

    /// Extra large radius: 16pt (modal sheets, large cards)
    public static let xl: CGFloat = 16

    /// Full/pill radius: 9999pt (circular elements)
    public static let full: CGFloat = 9999
}
