// =============================================================================
// AISStateBadge.swift
// Asternest Interface Standard (AIS) v1.0 - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// Provides visual indicators for record/item states following AIS guidelines.
// State badges communicate the current status of data items at a glance.
//
// KEY REQUIREMENTS (AIS Conformance):
// 1. SEMANTIC COLORS: Use AIS tokens for state indication
// 2. ICON PAIRING: Color is never the only signal (AIS §2.3)
// 3. CONSISTENCY: Same state looks the same everywhere
// 4. ACCESSIBILITY: State must be announced to screen readers
// 5. SIZE VARIANTS: Support for different contexts (list, detail, compact)
//
// DESIGN PHILOSOPHY:
// States represent the LIFECYCLE of data items:
// - Draft → Pending → Active → Completed → Archived
// - Or domain-specific states that map to these semantic categories
//
// USAGE:
// ```swift
// // Using semantic state
// AISStateBadge(.active)
//
// // Using custom state with semantic mapping
// AISStateBadge("Published", semanticState: .active)
//
// // Compact variant for lists
// AISStateBadge(.pending, style: .compact)
// ```
//
// =============================================================================

import SwiftUI

// MARK: - Semantic State

/// Semantic states that items can be in.
/// These map to AIS tokens for consistent visual treatment.
///
/// ## State Definitions
/// - `.draft`: Work in progress, not yet submitted
/// - `.pending`: Awaiting action/approval
/// - `.active`: Currently active/live
/// - `.completed`: Successfully finished
/// - `.archived`: No longer active but retained
/// - `.error`: In an error state
/// - `.warning`: Needs attention
/// - `.inactive`: Disabled/unavailable
///
public enum AISSemanticState: CaseIterable {
    /// Draft state - work in progress
    case draft

    /// Pending state - awaiting action
    case pending

    /// Active state - currently live
    case active

    /// Completed state - finished successfully
    case completed

    /// Archived state - retained but inactive
    case archived

    /// Error state - something wrong
    case error

    /// Warning state - needs attention
    case warning

    /// Inactive state - disabled
    case inactive

    /// Default display label for the state
    public var label: String {
        switch self {
        case .draft: return "Draft"
        case .pending: return "Pending"
        case .active: return "Active"
        case .completed: return "Completed"
        case .archived: return "Archived"
        case .error: return "Error"
        case .warning: return "Warning"
        case .inactive: return "Inactive"
        }
    }

    /// SF Symbol icon for the state
    public var iconName: String {
        switch self {
        case .draft: return "pencil.circle"
        case .pending: return "clock"
        case .active: return "checkmark.circle.fill"
        case .completed: return "checkmark.seal.fill"
        case .archived: return "archivebox"
        case .error: return "exclamationmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .inactive: return "minus.circle"
        }
    }
}

// MARK: - Badge Style

/// Visual style variants for state badges.
public enum AISStateBadgeStyle {
    /// Full badge with icon, label, and background
    case standard

    /// Compact badge with icon only (for dense lists)
    case compact

    /// Pill badge with filled background
    case pill

    /// Outlined badge with border only
    case outlined

    /// Dot indicator only (minimal)
    case dot
}

// MARK: - Badge Size

/// Size variants for state badges.
public enum AISStateBadgeSize {
    /// Small size for compact UIs
    case small

    /// Medium size (default)
    case medium

    /// Large size for emphasis
    case large
}

// MARK: - State Badge View

/// A visual indicator showing the state of an item.
///
/// ## Features
/// - Semantic state mapping to AIS tokens
/// - Multiple style variants (standard, compact, pill, outlined, dot)
/// - Size variants for different contexts
/// - Accessibility support
/// - Custom label override
///
/// ## Examples
///
/// ### Basic Usage
/// ```swift
/// // Using semantic state
/// AISStateBadge(.active)
///
/// // Compact style for lists
/// AISStateBadge(.pending, style: .compact)
///
/// // Custom label
/// AISStateBadge("Published", semanticState: .active)
/// ```
///
/// ### In a List Row
/// ```swift
/// HStack {
///     Text(item.name)
///     Spacer()
///     AISStateBadge(.active, style: .pill, size: .small)
/// }
/// ```
///
public struct AISStateBadge: View {
    // MARK: - Properties

    /// The semantic state
    let semanticState: AISSemanticState

    /// Custom label (overrides semantic state label)
    let customLabel: String?

    /// Visual style
    let style: AISStateBadgeStyle

    /// Size variant
    let size: AISStateBadgeSize

    /// Whether to show the icon
    let showIcon: Bool

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - Initialization

    /// Creates a state badge with the specified semantic state.
    ///
    /// - Parameters:
    ///   - state: The semantic state to display
    ///   - style: Visual style variant (default: .standard)
    ///   - size: Size variant (default: .medium)
    ///   - showIcon: Whether to show the icon (default: true)
    ///
    public init(
        _ state: AISSemanticState,
        style: AISStateBadgeStyle = .standard,
        size: AISStateBadgeSize = .medium,
        showIcon: Bool = true
    ) {
        self.semanticState = state
        self.customLabel = nil
        self.style = style
        self.size = size
        self.showIcon = showIcon
    }

    /// Creates a state badge with a custom label.
    ///
    /// - Parameters:
    ///   - label: Custom display label
    ///   - semanticState: The semantic state for color/icon
    ///   - style: Visual style variant (default: .standard)
    ///   - size: Size variant (default: .medium)
    ///   - showIcon: Whether to show the icon (default: true)
    ///
    public init(
        _ label: String,
        semanticState: AISSemanticState,
        style: AISStateBadgeStyle = .standard,
        size: AISStateBadgeSize = .medium,
        showIcon: Bool = true
    ) {
        self.semanticState = semanticState
        self.customLabel = label
        self.style = style
        self.size = size
        self.showIcon = showIcon
    }

    // MARK: - Computed Properties

    /// The display label (custom or semantic default)
    private var label: String {
        customLabel ?? semanticState.label
    }

    /// Returns the appropriate AIS token for the state
    private var stateToken: AISToken {
        switch semanticState {
        case .draft:
            return tokens.actionNeutral
        case .pending:
            return tokens.actionCaution
        case .active:
            return tokens.actionConfirm
        case .completed:
            return tokens.actionPrimary
        case .archived:
            return AISToken(color: tokens.onSurfaceSecondary, iconName: "archivebox")
        case .error:
            return tokens.stateError
        case .warning:
            return tokens.stateWarning
        case .inactive:
            return tokens.stateUnavailable
        }
    }

    /// Font based on size
    private var font: Font {
        switch size {
        case .small: return .caption2
        case .medium: return .caption
        case .large: return .subheadline
        }
    }

    /// Icon size based on badge size
    private var iconSize: CGFloat {
        switch size {
        case .small: return 10
        case .medium: return 12
        case .large: return 16
        }
    }

    /// Padding based on size
    private var padding: EdgeInsets {
        switch size {
        case .small:
            return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
        case .medium:
            return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        case .large:
            return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        }
    }

    /// Corner radius based on style
    private var cornerRadius: CGFloat {
        switch style {
        case .pill:
            return AISRadius.full
        default:
            return AISRadius.sm
        }
    }

    // MARK: - Body

    public var body: some View {
        switch style {
        case .standard:
            standardBadge
        case .compact:
            compactBadge
        case .pill:
            pillBadge
        case .outlined:
            outlinedBadge
        case .dot:
            dotBadge
        }
    }

    // MARK: - Badge Styles

    /// Standard badge with icon, label, and subtle background
    private var standardBadge: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: semanticState.iconName)
                    .font(.system(size: iconSize))
            }

            Text(label)
                .font(font.weight(.medium))
        }
        .foregroundColor(stateToken.color)
        .padding(padding)
        .background(stateToken.color.opacity(0.15))
        .cornerRadius(cornerRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Status: \(label)")
    }

    /// Compact badge with icon only
    private var compactBadge: some View {
        Image(systemName: semanticState.iconName)
            .font(.system(size: iconSize + 2))
            .foregroundColor(stateToken.color)
            .accessibilityLabel("Status: \(label)")
    }

    /// Pill-shaped badge with filled background
    private var pillBadge: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: semanticState.iconName)
                    .font(.system(size: iconSize))
            }

            Text(label)
                .font(font.weight(.semibold))
        }
        .foregroundColor(.white)
        .padding(padding)
        .background(stateToken.color)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Status: \(label)")
    }

    /// Outlined badge with border only
    private var outlinedBadge: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: semanticState.iconName)
                    .font(.system(size: iconSize))
            }

            Text(label)
                .font(font.weight(.medium))
        }
        .foregroundColor(stateToken.color)
        .padding(padding)
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(stateToken.color, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Status: \(label)")
    }

    /// Minimal dot indicator
    private var dotBadge: some View {
        Circle()
            .fill(stateToken.color)
            .frame(width: dotSize, height: dotSize)
            .accessibilityLabel("Status: \(label)")
    }

    private var dotSize: CGFloat {
        switch size {
        case .small: return 6
        case .medium: return 8
        case .large: return 12
        }
    }
}

// MARK: - State Badge Group

/// A group of state badges with consistent styling.
///
/// ## Example
/// ```swift
/// AISStateBadgeGroup([.active, .pending, .completed])
/// ```
///
public struct AISStateBadgeGroup: View {
    let states: [AISSemanticState]
    let style: AISStateBadgeStyle
    let size: AISStateBadgeSize
    let spacing: CGFloat

    public init(
        _ states: [AISSemanticState],
        style: AISStateBadgeStyle = .standard,
        size: AISStateBadgeSize = .small,
        spacing: CGFloat = AISSpacing.xs
    ) {
        self.states = states
        self.style = style
        self.size = size
        self.spacing = spacing
    }

    public var body: some View {
        HStack(spacing: spacing) {
            ForEach(states, id: \.self) { state in
                AISStateBadge(state, style: style, size: size)
            }
        }
    }
}

// MARK: - State Progress Indicator

/// Shows a progress indicator through multiple states.
///
/// ## Example
/// ```swift
/// AISStateProgress(
///     states: [.draft, .pending, .active, .completed],
///     currentState: .pending
/// )
/// ```
///
public struct AISStateProgress: View {
    let states: [AISSemanticState]
    let currentState: AISSemanticState
    let showLabels: Bool

    @Environment(\.aisTokens) private var tokens

    public init(
        states: [AISSemanticState],
        currentState: AISSemanticState,
        showLabels: Bool = true
    ) {
        self.states = states
        self.currentState = currentState
        self.showLabels = showLabels
    }

    private var currentIndex: Int {
        states.firstIndex(of: currentState) ?? 0
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(states.enumerated()), id: \.element) { index, state in
                if index > 0 {
                    // Connector line
                    Rectangle()
                        .fill(index <= currentIndex ? tokens.actionConfirm.color : tokens.surfaceSecondary)
                        .frame(height: 2)
                }

                // State indicator
                VStack(spacing: AISSpacing.xs) {
                    ZStack {
                        Circle()
                            .fill(index <= currentIndex ? stateToken(for: state).color : tokens.surfaceSecondary)
                            .frame(width: 28, height: 28)

                        if index < currentIndex {
                            // Completed step
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        } else if index == currentIndex {
                            // Current step
                            Image(systemName: state.iconName)
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        } else {
                            // Future step
                            Text("\(index + 1)")
                                .font(.caption2.bold())
                                .foregroundColor(tokens.onSurfaceSecondary)
                        }
                    }

                    if showLabels {
                        Text(state.label)
                            .font(.caption2)
                            .foregroundColor(
                                index <= currentIndex
                                    ? tokens.onSurface
                                    : tokens.onSurfaceSecondary
                            )
                            .lineLimit(1)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Progress: \(currentState.label) (\(currentIndex + 1) of \(states.count))")
    }

    private func stateToken(for state: AISSemanticState) -> AISToken {
        switch state {
        case .draft: return tokens.actionNeutral
        case .pending: return tokens.actionCaution
        case .active: return tokens.actionConfirm
        case .completed: return tokens.actionPrimary
        case .archived: return AISToken(color: tokens.onSurfaceSecondary, iconName: "archivebox")
        case .error: return tokens.stateError
        case .warning: return tokens.stateWarning
        case .inactive: return tokens.stateUnavailable
        }
    }
}

// MARK: - State Legend

/// A legend explaining state colors and meanings.
///
/// ## Example
/// ```swift
/// AISStateLegend(states: [.draft, .pending, .active, .completed])
/// ```
///
public struct AISStateLegend: View {
    let states: [AISSemanticState]
    let columns: Int

    public init(
        states: [AISSemanticState] = AISSemanticState.allCases,
        columns: Int = 2
    ) {
        self.states = states
        self.columns = columns
    }

    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: AISSpacing.md), count: columns)
    }

    public var body: some View {
        LazyVGrid(columns: gridItems, spacing: AISSpacing.sm) {
            ForEach(states, id: \.self) { state in
                HStack(spacing: AISSpacing.sm) {
                    AISStateBadge(state, style: .dot, size: .medium)

                    Text(state.label)
                        .font(.caption)

                    Spacer()
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AISStateBadge_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: AISSpacing.xl) {
                // All states - standard style
                Group {
                    Text("Standard Style").font(.headline)
                    HStack(spacing: AISSpacing.sm) {
                        AISStateBadge(.draft)
                        AISStateBadge(.pending)
                        AISStateBadge(.active)
                        AISStateBadge(.completed)
                    }
                }

                // Pill style
                Group {
                    Text("Pill Style").font(.headline)
                    HStack(spacing: AISSpacing.sm) {
                        AISStateBadge(.active, style: .pill, size: .small)
                        AISStateBadge(.error, style: .pill, size: .small)
                        AISStateBadge(.warning, style: .pill, size: .small)
                    }
                }

                // Outlined style
                Group {
                    Text("Outlined Style").font(.headline)
                    HStack(spacing: AISSpacing.sm) {
                        AISStateBadge(.draft, style: .outlined)
                        AISStateBadge(.pending, style: .outlined)
                        AISStateBadge(.archived, style: .outlined)
                    }
                }

                // Compact and Dot styles
                Group {
                    Text("Compact & Dot Styles").font(.headline)
                    HStack(spacing: AISSpacing.md) {
                        AISStateBadge(.active, style: .compact)
                        AISStateBadge(.pending, style: .compact)
                        AISStateBadge(.error, style: .dot)
                        AISStateBadge(.warning, style: .dot)
                    }
                }

                // Progress indicator
                Group {
                    Text("State Progress").font(.headline)
                    AISStateProgress(
                        states: [.draft, .pending, .active, .completed],
                        currentState: .pending
                    )
                }

                // Legend
                Group {
                    Text("State Legend").font(.headline)
                    AISStateLegend(states: [.draft, .pending, .active, .completed, .error, .warning])
                }
            }
            .padding()
        }
        .withAISTokens()
    }
}
#endif
