// =============================================================================
// AISButton.swift
// Asternest Interface Standard (AIS) v1.0 - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// A semantic button component that automatically applies AIS tokens.
// Buttons are categorized by their semantic meaning (primary, confirm,
// destructive, etc.) rather than their visual appearance.
//
// DESIGN PHILOSOPHY:
// - Semantic-first: Choose button type based on ACTION MEANING
// - Icon pairing: Every button type includes its semantic icon
// - Accessibility: Built-in support for VoiceOver and Dynamic Type
// - Consistent: Same button type looks the same everywhere
//
// USAGE:
// ```swift
// // Primary action button
// AISButton("Save Changes", type: .primary) {
//     saveChanges()
// }
//
// // Destructive action with custom icon
// AISButton("Delete", type: .destructive, icon: "trash") {
//     deleteItem()
// }
//
// // Loading state
// AISButton("Processing...", type: .primary, isLoading: true) { }
// ```
//
// =============================================================================

import SwiftUI

// MARK: - Button Type Enum

/// Semantic button types aligned with AIS action tokens.
/// Choose the type based on what the action MEANS, not how you want it to look.
///
/// ## Decision Guide
/// - `.primary`: Is this the main action on the screen?
/// - `.confirm`: Does this complete/approve something?
/// - `.caution`: Does this modify something significant but reversible?
/// - `.destructive`: Could this cause data loss or be hard to undo?
/// - `.neutral`: Is this dismissive or non-committal (Cancel, Close)?
/// - `.secondary`: Is this a secondary action that shouldn't compete with primary?
///
public enum AISButtonType {
    /// Primary brand action - most prominent button on screen
    /// Use for: Save, Submit, Continue, Next, primary CTAs
    case primary

    /// Confirmation action - affirms completion
    /// Use for: Confirm, Approve, Accept, Mark as Done
    case confirm

    /// Caution action - significant but reversible
    /// Use for: Edit, Modify, Change (when notable)
    case caution

    /// Destructive action - potentially harmful
    /// Use for: Delete, Remove, Cancel subscription
    /// Always pair with confirmation dialog
    case destructive

    /// Neutral action - non-committal
    /// Use for: Cancel, Close, Back, Skip, Maybe Later
    case neutral

    /// Secondary action - lower visual prominence
    /// Use for: Alternative actions, "Learn More", optional paths
    case secondary
}

// MARK: - Button Style Enum

/// Visual style variations for buttons.
/// The style affects appearance but not semantic meaning.
public enum AISButtonStyle {
    /// Filled background with contrasting text
    case filled

    /// Outlined with colored border and text
    case outlined

    /// Text-only with no background or border
    case text

    /// Icon-only compact button
    case iconOnly
}

// MARK: - Button Size Enum

/// Size presets for buttons following AIS spacing guidelines.
public enum AISButtonSize {
    /// Small: Compact UI, toolbars, tight spaces
    case small

    /// Medium: Standard size for most use cases
    case medium

    /// Large: Prominent CTAs, onboarding, accessibility
    case large
}

// MARK: - AISButton View

/// A semantic button component that automatically applies appropriate styling
/// based on its action type, following AIS token conventions.
///
/// ## Features
/// - Automatic token-based coloring
/// - Optional icon display (uses semantic icon if not specified)
/// - Loading state with spinner
/// - Disabled state handling
/// - Multiple visual styles (filled, outlined, text)
/// - Accessibility support
///
/// ## Example Usage
/// ```swift
/// // Simple primary button
/// AISButton("Save", type: .primary) {
///     viewModel.save()
/// }
///
/// // Destructive with confirmation
/// AISButton("Delete Account", type: .destructive) {
///     showDeleteConfirmation = true
/// }
/// .confirmationDialog(...)
///
/// // Loading state
/// AISButton("Processing", type: .primary, isLoading: isSaving) {
///     startSave()
/// }
/// ```
///
public struct AISButton: View {
    // MARK: - Properties

    /// The button's label text
    let title: String

    /// Semantic type determining color and default icon
    let type: AISButtonType

    /// Visual style (filled, outlined, text)
    let style: AISButtonStyle

    /// Size preset
    let size: AISButtonSize

    /// Optional custom icon (overrides semantic default)
    let icon: String?

    /// Whether to show the icon
    let showIcon: Bool

    /// Loading state - shows spinner and disables interaction
    let isLoading: Bool

    /// Whether the button is disabled
    let isDisabled: Bool

    /// Full width button (expands to fill container)
    let fullWidth: Bool

    /// Action to perform when tapped
    let action: () -> Void

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - Initialization

    /// Creates an AIS-compliant button with semantic styling.
    ///
    /// - Parameters:
    ///   - title: The button's label text
    ///   - type: Semantic action type (determines color/icon)
    ///   - style: Visual style variation (default: .filled)
    ///   - size: Size preset (default: .medium)
    ///   - icon: Custom SF Symbol name (optional, uses semantic icon if nil)
    ///   - showIcon: Whether to display an icon (default: true)
    ///   - isLoading: Shows loading spinner when true
    ///   - isDisabled: Disables the button when true
    ///   - fullWidth: Expands button to fill container width
    ///   - action: Closure to execute on tap
    ///
    public init(
        _ title: String,
        type: AISButtonType,
        style: AISButtonStyle = .filled,
        size: AISButtonSize = .medium,
        icon: String? = nil,
        showIcon: Bool = true,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.type = type
        self.style = style
        self.size = size
        self.icon = icon
        self.showIcon = showIcon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.fullWidth = fullWidth
        self.action = action
    }

    // MARK: - Computed Properties

    /// Returns the appropriate AIS token for this button type
    private var token: AISToken {
        switch type {
        case .primary:
            return tokens.actionPrimary
        case .confirm:
            return tokens.actionConfirm
        case .caution:
            return tokens.actionCaution
        case .destructive:
            return tokens.actionDestructive
        case .neutral:
            return tokens.actionNeutral
        case .secondary:
            return AISToken(color: tokens.onSurfaceSecondary, iconName: "ellipsis.circle")
        }
    }

    /// The icon to display (custom or semantic default)
    private var displayIcon: String {
        icon ?? token.iconName
    }

    /// Foreground color based on style
    private var foregroundColor: Color {
        if isDisabled {
            return tokens.onSurfaceSecondary.opacity(0.5)
        }
        switch style {
        case .filled:
            // White text on colored background
            return type == .neutral ? tokens.onSurface : .white
        case .outlined, .text, .iconOnly:
            return token.color
        }
    }

    /// Background color based on style
    private var backgroundColor: Color {
        if isDisabled {
            return tokens.surfaceSecondary
        }
        switch style {
        case .filled:
            return token.color
        case .outlined, .text, .iconOnly:
            return .clear
        }
    }

    /// Border color for outlined style
    private var borderColor: Color {
        switch style {
        case .outlined:
            return isDisabled ? tokens.onSurfaceSecondary.opacity(0.3) : token.color
        default:
            return .clear
        }
    }

    /// Padding based on size
    private var padding: EdgeInsets {
        switch size {
        case .small:
            return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        case .medium:
            return EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        case .large:
            return EdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        }
    }

    /// Font based on size
    private var font: Font {
        switch size {
        case .small:
            return .subheadline.weight(.medium)
        case .medium:
            return .body.weight(.semibold)
        case .large:
            return .title3.weight(.semibold)
        }
    }

    /// Icon size based on button size
    private var iconSize: CGFloat {
        switch size {
        case .small: return 14
        case .medium: return 16
        case .large: return 20
        }
    }

    // MARK: - Body

    public var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                action()
            }
        }) {
            HStack(spacing: AISSpacing.sm) {
                // Loading spinner or icon
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(size == .small ? 0.8 : 1.0)
                } else if showIcon && style != .iconOnly {
                    Image(systemName: displayIcon)
                        .font(.system(size: iconSize))
                }

                // Title (unless icon-only style)
                if style != .iconOnly {
                    Text(title)
                        .font(font)
                }

                // Icon-only style
                if style == .iconOnly {
                    Image(systemName: displayIcon)
                        .font(.system(size: iconSize + 4))
                }
            }
            .foregroundColor(foregroundColor)
            .padding(padding)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(backgroundColor)
            .cornerRadius(AISRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AISRadius.md)
                    .stroke(borderColor, lineWidth: style == .outlined ? 1.5 : 0)
            )
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.6 : 1.0)
        // Accessibility
        .accessibilityLabel(title)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isLoading ? .updatesFrequently : [])
    }

    /// Accessibility hint based on button state
    private var accessibilityHint: String {
        if isLoading {
            return "Loading, please wait"
        }
        if isDisabled {
            return "Button is disabled"
        }
        return ""
    }
}

// MARK: - Icon-Only Button Convenience

extension AISButton {
    /// Creates an icon-only button with no text label.
    ///
    /// - Parameters:
    ///   - icon: SF Symbol name
    ///   - type: Semantic action type
    ///   - size: Size preset
    ///   - accessibilityLabel: Required label for VoiceOver
    ///   - action: Closure to execute on tap
    ///
    public static func icon(
        _ icon: String,
        type: AISButtonType,
        size: AISButtonSize = .medium,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        AISButton(
            accessibilityLabel,
            type: type,
            style: .iconOnly,
            size: size,
            icon: icon,
            action: action
        )
    }
}

// MARK: - Preview

#if DEBUG
struct AISButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AISSpacing.lg) {
            // Filled buttons
            Group {
                AISButton("Primary Action", type: .primary) { }
                AISButton("Confirm", type: .confirm) { }
                AISButton("Caution", type: .caution) { }
                AISButton("Delete", type: .destructive) { }
                AISButton("Cancel", type: .neutral) { }
            }

            Divider()

            // Outlined buttons
            Group {
                AISButton("Outlined", type: .primary, style: .outlined) { }
                AISButton("Loading", type: .primary, isLoading: true) { }
                AISButton("Disabled", type: .primary, isDisabled: true) { }
            }

            Divider()

            // Full width
            AISButton("Full Width Button", type: .primary, fullWidth: true) { }
        }
        .padding()
        .withAISTokens()
    }
}
#endif
