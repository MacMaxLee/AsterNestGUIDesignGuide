// =============================================================================
// AISValueComponent.swift
// Asternest Interface Standard (AIS) v1.0 - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// Displays consequential values (monetary amounts, metrics, dates) with
// REQUIRED annotations as specified in AIS §3.1.
//
// KEY PRINCIPLE:
// A consequential value without context is misleading. If someone screenshots
// a figure and sends it to a colleague, what would they get wrong?
// The answer determines required annotations.
//
// REQUIRED ANNOTATIONS (domain-specific):
// - Currency code for monetary values
// - Unit of measure for metrics
// - Time period (as-of date, reporting period)
// - Basis (e.g., "excluding tax", "annualized")
//
// COMPILE-TIME ENFORCEMENT:
// The initializer REQUIRES annotation parameters, making it impossible
// to render an uncontextualized value. This is intentional (C-04).
//
// USAGE:
// ```swift
// // Monetary value with full context
// AISValueComponent(
//     value: revenue,
//     format: .currency(code: "USD"),
//     annotations: [
//         .period("Q3 2024"),
//         .basis("Gross revenue")
//     ]
// )
//
// // Metric with unit
// AISValueComponent(
//     value: temperature,
//     format: .number(decimals: 1),
//     unit: "°C",
//     annotations: [.asOf(Date())]
// )
// ```
//
// =============================================================================

import SwiftUI

// MARK: - Value Annotation

/// Annotations that provide essential context for consequential values.
/// Without these, a value could be misleading or misinterpreted.
///
/// ## Why Annotations Are Required
/// Consider: "$1,234,567" — Is this revenue or profit? Monthly or annual?
/// In USD or another currency? Before or after tax?
/// Annotations eliminate ambiguity.
///
public enum AISValueAnnotation: Identifiable, Equatable {
    /// Label describing what the value represents
    /// Example: "Revenue", "Total Users", "Conversion Rate"
    case label(String)

    /// Currency code (ISO 4217) — REQUIRED for monetary values
    /// Example: "USD", "EUR", "JPY"
    case currency(String)

    /// Unit of measure — REQUIRED for metrics
    /// Example: "kg", "miles", "°F", "%"
    case unit(String)

    /// Reporting period — When was this measured?
    /// Example: "Q3 2024", "FY 2023", "January 2024"
    case period(String)

    /// As-of timestamp — Point-in-time value
    /// Example: "As of Dec 31, 2024"
    case asOf(Date)

    /// Basis or methodology — How was this calculated?
    /// Example: "Excluding returns", "Annualized", "Pro forma"
    case basis(String)

    /// Comparison reference — What is this compared to?
    /// Example: "vs. prior year", "vs. budget"
    case comparison(String)

    /// Data source information
    /// Example: "Financial Report", "Survey Results"
    case source(String)

    /// Custom annotation for domain-specific context
    case custom(label: String, value: String)

    public var id: String {
        switch self {
        case .label(let l): return "label-\(l)"
        case .currency(let code): return "currency-\(code)"
        case .unit(let u): return "unit-\(u)"
        case .period(let p): return "period-\(p)"
        case .asOf(let d): return "asOf-\(d.timeIntervalSince1970)"
        case .basis(let b): return "basis-\(b)"
        case .comparison(let c): return "comparison-\(c)"
        case .source(let s): return "source-\(s)"
        case .custom(let l, let v): return "custom-\(l)-\(v)"
        }
    }

    /// Display text for the annotation
    public var displayText: String {
        switch self {
        case .label(let label):
            return label
        case .currency(let code):
            return code
        case .unit(let unit):
            return unit
        case .period(let period):
            return period
        case .asOf(let date):
            return "As of \(date.formatted(date: .abbreviated, time: .omitted))"
        case .basis(let basis):
            return basis
        case .comparison(let comp):
            return comp
        case .source(let source):
            return "Source: \(source)"
        case .custom(_, let value):
            return value
        }
    }
}

// MARK: - Value Format

/// Formatting options for value display.
public enum AISValueFormat {
    /// Currency formatting with locale-aware symbols
    case currency(code: String, showSymbol: Bool = true)

    /// Percentage formatting
    case percent(decimals: Int = 0, showSign: Bool = false)

    /// Percentage formatting (alias for percent)
    case percentage

    /// Numeric formatting with decimal control
    case number(decimals: Int = 0, grouping: Bool = true)

    /// Integer formatting (no decimals)
    case integer

    /// Decimal formatting with specified places
    case decimal(places: Int)

    /// Scientific notation
    case scientific

    /// Compact notation for large numbers (1.2M, 3.4B)
    case compact

    /// Custom format string
    case custom(String)

    /// Raw string (no formatting)
    case raw
}

// MARK: - Value State

/// The state of a value, particularly for handling unavailable data.
///
/// IMPORTANT DISTINCTION (AIS §2.2):
/// - `.value(0)` = We have data, and the value is zero
/// - `.unavailable` = We have NO data (null, missing, not yet loaded)
///
/// These are semantically opposite and MUST be displayed differently.
///
public enum AISValueState<T> {
    /// Value is available
    case available(T)

    /// Value is unavailable (null, missing, not loaded)
    /// Reason explains WHY it's unavailable
    case unavailable

    /// Value is loading
    case loading

    /// Value has error
    case error(String)

    /// Alias for available
    static func value(_ value: T) -> AISValueState<T> {
        .available(value)
    }
}

// MARK: - Value Comparison

/// Configuration for comparing values and showing change indicators
public struct AISValueComparison {
    /// Previous value to compare against
    public let previousValue: Double

    /// Whether to show percentage change
    public let showPercentageChange: Bool

    /// Whether to show absolute change
    public let showAbsoluteChange: Bool

    public init(
        previousValue: Double,
        showPercentageChange: Bool = true,
        showAbsoluteChange: Bool = false
    ) {
        self.previousValue = previousValue
        self.showPercentageChange = showPercentageChange
        self.showAbsoluteChange = showAbsoluteChange
    }
}

// MARK: - Value Component

/// A semantic value display component that requires contextual annotations.
///
/// ## Type Parameter
/// - `T`: The numeric type being displayed (must be numeric)
///
/// ## Features
/// - Enforces annotation requirements at compile time (C-04)
/// - Handles unavailable values distinctly from zeros
/// - Supports multiple display sizes
/// - Includes trend indicators
/// - Accessible with VoiceOver support
///
/// ## Example
/// ```swift
/// AISValueComponent(
///     value: .value(revenue),
///     format: .currency(code: "USD"),
///     annotations: [
///         .period("Q3 2024"),
///         .basis("Gross revenue, excluding returns")
///     ],
///     trend: .up(percentage: 12.5)
/// )
/// ```
///
public struct AISValueComponent<T: Numeric>: View {
    // MARK: - Properties

    /// The value state (value, unavailable, loading, or error)
    let valueState: AISValueState<T>

    /// How to format the value for display
    let format: AISValueFormat

    /// REQUIRED annotations providing context
    /// Empty array will show warning in debug builds
    let annotations: [AISValueAnnotation]

    /// Optional label above the value
    let label: String?

    /// Display size
    let size: AISValueSize

    /// Optional trend indicator
    let trend: AISValueTrend?

    /// Whether to show annotations inline or below
    let inlineAnnotations: Bool

    /// Optional comparison with previous value
    let comparison: AISValueComparison?

    /// Text alignment
    let alignment: HorizontalAlignment

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - Initialization

    /// Creates a value component with required annotations.
    ///
    /// - Parameters:
    ///   - value: The value state to display
    ///   - format: How to format the numeric value
    ///   - annotations: REQUIRED context annotations (enforced at compile time)
    ///   - label: Optional label above the value
    ///   - size: Display size preset
    ///   - trend: Optional trend indicator
    ///   - inlineAnnotations: Show annotations inline vs below
    ///
    /// - Important: The `annotations` parameter is required by design (C-04).
    ///              If you truly have no annotations, you should reconsider
    ///              whether this value needs context, or use `.custom` annotation.
    ///
    public init(
        valueState: AISValueState<T>,
        format: AISValueFormat,
        annotations: [AISValueAnnotation],
        label: String? = nil,
        size: AISValueSize = .medium,
        trend: AISValueTrend? = nil,
        inlineAnnotations: Bool = false,
        comparison: AISValueComparison? = nil,
        alignment: HorizontalAlignment = .leading
    ) {
        self.valueState = valueState
        self.format = format
        self.annotations = annotations
        self.label = label
        self.size = size
        self.trend = trend
        self.inlineAnnotations = inlineAnnotations
        self.comparison = comparison
        self.alignment = alignment

        // Debug warning for missing annotations
        #if DEBUG
        if annotations.isEmpty {
            print("⚠️ AISValueComponent: No annotations provided. Values should have context per AIS §3.1")
        }
        #endif
    }

    /// Convenience initializer for direct numeric value
    public init(
        _ value: T,
        format: AISValueFormat,
        annotations: [AISValueAnnotation],
        label: String? = nil,
        size: AISValueSize = .medium,
        trend: AISValueTrend? = nil,
        inlineAnnotations: Bool = false,
        comparison: AISValueComparison? = nil,
        alignment: HorizontalAlignment = .leading
    ) {
        self.init(
            valueState: .available(value),
            format: format,
            annotations: annotations,
            label: label,
            size: size,
            trend: trend,
            inlineAnnotations: inlineAnnotations,
            comparison: comparison,
            alignment: alignment
        )
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: alignment, spacing: AISSpacing.xs) {
            // Optional label
            if let label = label {
                Text(label)
                    .font(size.labelFont)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }

            // Main value row
            HStack(alignment: .firstTextBaseline, spacing: AISSpacing.sm) {
                valueDisplay

                if let trend = trend {
                    trendIndicator(trend)
                }

                if let comp = comparison {
                    comparisonIndicator(comp)
                }

                if inlineAnnotations && !annotations.isEmpty {
                    annotationBadges
                }
            }

            // Annotations below (if not inline)
            if !inlineAnnotations && !annotations.isEmpty {
                annotationBadges
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Value Display

    @ViewBuilder
    private var valueDisplay: some View {
        switch valueState {
        case .available(let value):
            Text(formattedValue(value))
                .font(size.valueFont)
                .fontWeight(.semibold)
                .foregroundColor(tokens.onSurface)
                .monospacedDigit()

        case .unavailable:
            // MUST be visually distinct from zero (AIS §2.2)
            HStack(spacing: AISSpacing.xs) {
                Image(systemName: tokens.stateUnavailable.iconName)
                    .font(size.iconFont)
                Text("N/A")
                    .font(size.valueFont)
                    .italic()
            }
            .foregroundColor(tokens.stateUnavailable.color)

        case .loading:
            HStack(spacing: AISSpacing.xs) {
                ProgressView()
                    .scaleEffect(size == .small ? 0.7 : 0.9)
                Text("Loading...")
                    .font(size.labelFont)
            }
            .foregroundColor(tokens.onSurfaceSecondary)

        case .error(let message):
            HStack(spacing: AISSpacing.xs) {
                Image(systemName: tokens.stateError.iconName)
                Text(message)
                    .font(size.labelFont)
            }
            .foregroundColor(tokens.stateError.color)
        }
    }

    // MARK: - Formatting

    private func formattedValue(_ value: T) -> String {
        // Convert to Double for formatting
        guard let doubleValue = value as? Double ?? (value as? Int).map(Double.init) else {
            return "\(value)"
        }

        switch format {
        case .currency(let code, let showSymbol):
            var formatted = doubleValue.formatted(.currency(code: code))
            if !showSymbol {
                // Remove currency symbol, keep value
                formatted = doubleValue.formatted(.number.precision(.fractionLength(2)))
            }
            return formatted

        case .percent(let decimals, let showSign):
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            formatter.maximumFractionDigits = decimals
            formatter.positivePrefix = showSign ? "+" : ""
            return formatter.string(from: NSNumber(value: doubleValue / 100)) ?? "\(doubleValue)%"

        case .percentage:
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            formatter.maximumFractionDigits = 1
            return formatter.string(from: NSNumber(value: doubleValue)) ?? "\(doubleValue)%"

        case .number(let decimals, let grouping):
            let formatter = NumberFormatter()
            formatter.numberStyle = grouping ? .decimal : .none
            formatter.maximumFractionDigits = decimals
            return formatter.string(from: NSNumber(value: doubleValue)) ?? "\(doubleValue)"

        case .integer:
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: doubleValue)) ?? "\(Int(doubleValue))"

        case .decimal(let places):
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = places
            formatter.maximumFractionDigits = places
            return formatter.string(from: NSNumber(value: doubleValue)) ?? "\(doubleValue)"

        case .scientific:
            let formatter = NumberFormatter()
            formatter.numberStyle = .scientific
            formatter.maximumFractionDigits = 2
            return formatter.string(from: NSNumber(value: doubleValue)) ?? "\(doubleValue)"

        case .compact:
            return doubleValue.formatted(.number.notation(.compactName))

        case .custom(let formatString):
            return String(format: formatString, doubleValue)

        case .raw:
            return "\(value)"
        }
    }

    // MARK: - Trend Indicator

    @ViewBuilder
    private func trendIndicator(_ trend: AISValueTrend) -> some View {
        HStack(spacing: 2) {
            Image(systemName: trend.iconName)
            if let percentage = trend.percentage {
                Text("\(percentage, specifier: "%.1f")%")
                    .font(size.labelFont)
            }
        }
        .foregroundColor(trend.color(using: tokens))
        .font(size.iconFont)
    }

    // MARK: - Comparison Indicator

    @ViewBuilder
    private func comparisonIndicator(_ comparison: AISValueComparison) -> some View {
        if case .available(let value) = valueState {
            let currentValue = (value as? Double) ?? Double(value as? Int ?? 0)
            let change = currentValue - comparison.previousValue
            let percentChange = comparison.previousValue != 0 ? (change / comparison.previousValue) * 100 : 0

            HStack(spacing: 2) {
                if change > 0 {
                    Image(systemName: "arrow.up")
                        .foregroundColor(tokens.actionConfirm.color)
                } else if change < 0 {
                    Image(systemName: "arrow.down")
                        .foregroundColor(tokens.stateError.color)
                } else {
                    Image(systemName: "minus")
                        .foregroundColor(tokens.onSurfaceSecondary)
                }

                if comparison.showPercentageChange {
                    Text("\(abs(percentChange), specifier: "%.1f")%")
                        .font(size.labelFont)
                        .foregroundColor(change >= 0 ? tokens.actionConfirm.color : tokens.stateError.color)
                }
            }
            .font(size.iconFont)
        }
    }

    // MARK: - Annotations

    private var annotationBadges: some View {
        FlowLayout(spacing: AISSpacing.xs) {
            ForEach(annotations) { annotation in
                Text(annotation.displayText)
                    .font(.caption2)
                    .padding(.horizontal, AISSpacing.xs)
                    .padding(.vertical, 2)
                    .background(tokens.surfaceSecondary)
                    .cornerRadius(AISRadius.sm)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        var parts: [String] = []

        if let label = label {
            parts.append(label)
        }

        switch valueState {
        case .available(let value):
            parts.append(formattedValue(value))
        case .unavailable:
            parts.append("Unavailable: No data")
        case .loading:
            parts.append("Loading")
        case .error(let message):
            parts.append("Error: \(message)")
        }

        if let trend = trend {
            parts.append(trend.accessibilityDescription)
        }

        parts.append(contentsOf: annotations.map { $0.displayText })

        return parts.joined(separator: ", ")
    }
}

// MARK: - Value Size

/// Size presets for value display
public enum AISValueSize {
    case small
    case medium
    case large
    case hero

    var valueFont: Font {
        switch self {
        case .small: return .callout
        case .medium: return .title3
        case .large: return .title
        case .hero: return .largeTitle
        }
    }

    var labelFont: Font {
        switch self {
        case .small: return .caption2
        case .medium: return .caption
        case .large: return .subheadline
        case .hero: return .headline
        }
    }

    var iconFont: Font {
        switch self {
        case .small: return .caption
        case .medium: return .callout
        case .large: return .body
        case .hero: return .title3
        }
    }
}

// MARK: - Value Trend

/// Trend indicator for value changes
public enum AISValueTrend {
    case up(percentage: Double? = nil)
    case down(percentage: Double? = nil)
    case neutral

    var iconName: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "arrow.right"
        }
    }

    var percentage: Double? {
        switch self {
        case .up(let p), .down(let p): return p
        case .neutral: return nil
        }
    }

    func color(using tokens: AISTokenSet) -> Color {
        switch self {
        case .up: return tokens.actionConfirm.color
        case .down: return tokens.stateError.color
        case .neutral: return tokens.onSurfaceSecondary
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .up(let p):
            if let p = p { return "Up \(p)%" }
            return "Trending up"
        case .down(let p):
            if let p = p { return "Down \(p)%" }
            return "Trending down"
        case .neutral:
            return "No change"
        }
    }
}

// MARK: - Flow Layout Helper

/// A simple flow layout for annotation badges
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        let containerWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX)
        }

        return (positions, CGSize(width: maxWidth, height: currentY + lineHeight))
    }
}

// MARK: - Editable Value Input

/// An editable value input component with annotations and validation.
///
/// ## Purpose
/// While `AISValueComponent` is for display only, `AISValueInput` allows
/// users to enter and edit numeric values with full AIS annotation support.
///
/// ## Features
/// - Two-way binding for value editing
/// - Format-aware parsing and display
/// - Validation with error feedback
/// - Required annotations (C-04 compliance)
/// - Keyboard type optimization
/// - Focus state management
///
/// ## Example
/// ```swift
/// @State private var amount: Double = 0
///
/// AISValueInput(
///     value: $amount,
///     format: .currency(code: "USD"),
///     annotations: [.period("Q3 2024")],
///     label: "Budget Amount",
///     placeholder: "Enter amount"
/// )
/// ```
///
public struct AISValueInput<T: Numeric & LosslessStringConvertible>: View {
    // MARK: - Properties

    /// Binding to the value being edited
    @Binding var value: T

    /// How to format/parse the value
    let format: AISValueFormat

    /// REQUIRED annotations providing context
    let annotations: [AISValueAnnotation]

    /// Label above the input
    let label: String?

    /// Placeholder text when empty
    let placeholder: String

    /// Display size
    let size: AISValueSize

    /// Whether the input is disabled
    let isDisabled: Bool

    /// Optional validation closure
    let validation: ((T) -> String?)?

    /// Called when value changes
    let onValueChange: ((T) -> Void)?

    // MARK: - State

    @State private var textValue: String = ""
    @State private var isEditing: Bool = false
    @State private var validationError: String?
    @FocusState private var isFocused: Bool

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - Initialization

    /// Creates an editable value input.
    ///
    /// - Parameters:
    ///   - value: Binding to the numeric value
    ///   - format: How to format/parse the value
    ///   - annotations: REQUIRED context annotations
    ///   - label: Optional label above input
    ///   - placeholder: Placeholder text
    ///   - size: Display size preset
    ///   - isDisabled: Whether input is disabled
    ///   - validation: Optional validation closure returning error message
    ///   - onValueChange: Called when value changes
    ///
    public init(
        value: Binding<T>,
        format: AISValueFormat,
        annotations: [AISValueAnnotation],
        label: String? = nil,
        placeholder: String = "Enter value",
        size: AISValueSize = .medium,
        isDisabled: Bool = false,
        validation: ((T) -> String?)? = nil,
        onValueChange: ((T) -> Void)? = nil
    ) {
        self._value = value
        self.format = format
        self.annotations = annotations
        self.label = label
        self.placeholder = placeholder
        self.size = size
        self.isDisabled = isDisabled
        self.validation = validation
        self.onValueChange = onValueChange
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: AISSpacing.xs) {
            // Label
            if let label = label {
                Text(label)
                    .font(size.labelFont)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }

            // Input field
            HStack(spacing: AISSpacing.sm) {
                // Currency/unit prefix if applicable
                if let prefix = formatPrefix {
                    Text(prefix)
                        .font(size.valueFont)
                        .foregroundColor(tokens.onSurfaceSecondary)
                }

                // Text field - use roundedBorder style for better macOS support
                TextField(placeholder, text: $textValue, onEditingChanged: { editing in
                    isEditing = editing
                    if !editing {
                        // When focus is lost, reformat the display
                        textValue = formattedValueString
                    }
                }, onCommit: {
                    // Validate on commit
                    parseAndValidate(textValue)
                })
                .font(size.valueFont)
                .textFieldStyle(.roundedBorder)
                .disabled(isDisabled)
                #if os(iOS)
                .keyboardType(keyboardType)
                #endif
                .onChange(of: textValue) { _, newValue in
                    if isEditing {
                        parseAndValidate(newValue)
                    }
                }

                // Currency/unit suffix if applicable
                if let suffix = formatSuffix {
                    Text(suffix)
                        .font(size.valueFont)
                        .foregroundColor(tokens.onSurfaceSecondary)
                }

                // Clear button
                if !textValue.isEmpty && !isDisabled {
                    Button {
                        textValue = ""
                        if let zero = T("0") {
                            value = zero
                            validationError = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(tokens.onSurfaceSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Validation error - make it selectable/copyable
            if let error = validationError {
                HStack(spacing: AISSpacing.xs) {
                    Image(systemName: tokens.stateError.iconName)
                    Text(error)
                        .textSelection(.enabled)
                }
                .font(.caption)
                .foregroundColor(tokens.stateError.color)
            }

            // Annotations
            if !annotations.isEmpty {
                annotationsView
            }
        }
        .onAppear {
            textValue = formattedValueString
        }
        .opacity(isDisabled ? 0.6 : 1.0)
    }

    // MARK: - Computed Properties

    private var borderColor: Color {
        if validationError != nil {
            return tokens.stateError.color
        } else if isFocused {
            return tokens.actionPrimary.color
        } else {
            return tokens.onSurface.opacity(0.2)
        }
    }

    private var formatPrefix: String? {
        switch format {
        case .currency(let code, let showSymbol):
            if showSymbol {
                return currencySymbol(for: code)
            }
            return nil
        default:
            return nil
        }
    }

    private var formatSuffix: String? {
        switch format {
        case .percent, .percentage:
            return "%"
        default:
            return nil
        }
    }

    #if os(iOS)
    private var keyboardType: UIKeyboardType {
        switch format {
        case .currency, .number, .decimal, .compact:
            return .decimalPad
        case .percent, .percentage, .integer:
            return .numberPad
        default:
            return .decimalPad
        }
    }
    #endif

    private var rawValueString: String {
        if let doubleValue = value as? Double {
            return String(doubleValue)
        } else if let intValue = value as? Int {
            return String(intValue)
        }
        return String(describing: value)
    }

    private var formattedValueString: String {
        guard let doubleValue = Double("\(value)") else {
            return String(describing: value)
        }

        switch format {
        case .currency(_, _):
            return String(format: "%.2f", doubleValue)
        case .percent(let decimals, _):
            return String(format: "%.\(decimals)f", doubleValue)
        case .percentage:
            return String(format: "%.0f", doubleValue)
        case .number(let decimals, _):
            return String(format: "%.\(decimals)f", doubleValue)
        case .decimal(let places):
            return String(format: "%.\(places)f", doubleValue)
        case .integer:
            return String(format: "%.0f", doubleValue)
        case .scientific:
            return String(format: "%e", doubleValue)
        case .compact:
            return formatCompact(doubleValue)
        case .custom(let pattern):
            return String(format: pattern, doubleValue)
        case .raw:
            return String(describing: value)
        }
    }

    private func currencySymbol(for code: String) -> String {
        switch code.uppercased() {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "CNY": return "¥"
        default: return code
        }
    }

    private func formatCompact(_ value: Double) -> String {
        let absValue = abs(value)
        switch absValue {
        case 1_000_000_000...:
            return String(format: "%.1f", value / 1_000_000_000)
        case 1_000_000...:
            return String(format: "%.1f", value / 1_000_000)
        case 1_000...:
            return String(format: "%.1f", value / 1_000)
        default:
            return String(format: "%.0f", value)
        }
    }

    // MARK: - Parsing & Validation

    private func parseAndValidate(_ text: String) {
        // Remove formatting characters
        let cleanText = text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "£", with: "")
            .replacingOccurrences(of: "%", with: "")

        if cleanText.isEmpty {
            if let zero = T("0") {
                value = zero
                validationError = nil
            }
            return
        }

        // Parse the value
        if let parsedValue = T(cleanText) {
            value = parsedValue

            // Run validation
            if let validate = validation {
                validationError = validate(parsedValue)
            } else {
                validationError = nil
            }

            onValueChange?(parsedValue)
        } else {
            validationError = "Invalid number format"
        }
    }

    // MARK: - Annotations View

    private var annotationsView: some View {
        FlowLayout(spacing: AISSpacing.xs) {
            ForEach(annotations) { annotation in
                Text(annotation.displayText)
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)
                    .padding(.horizontal, AISSpacing.xs)
                    .padding(.vertical, 2)
                    .background(tokens.surfaceSecondary)
                    .cornerRadius(AISRadius.sm)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AISValueComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AISSpacing.xl) {
            // Currency value
            AISValueComponent(
                125430.50,
                format: .currency(code: "USD"),
                annotations: [
                    .period("Q3 2024"),
                    .basis("Gross revenue")
                ],
                label: "Revenue",
                size: .large,
                trend: .up(percentage: 12.5)
            )

            Divider()

            // Percentage
            AISValueComponent(
                85.7,
                format: .percent(decimals: 1),
                annotations: [.asOf(Date())],
                label: "Completion Rate"
            )

            Divider()

            // Unavailable value
            AISValueComponent<Double>(
                valueState: .unavailable,
                format: .number(),
                annotations: [.period("Q3 2024")],
                label: "Metric"
            )
        }
        .padding()
        .withAISTokens()
    }
}

struct AISValueInput_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var amount: Double = 1250.50
        @State private var percentage: Double = 75
        @State private var quantity: Double = 100

        var body: some View {
            VStack(spacing: AISSpacing.xl) {
                // Currency input
                AISValueInput(
                    value: $amount,
                    format: .currency(code: "USD"),
                    annotations: [.period("Q3 2024"), .basis("Budget allocation")],
                    label: "Budget Amount",
                    placeholder: "Enter amount"
                )

                Divider()

                // Percentage input with validation
                AISValueInput(
                    value: $percentage,
                    format: .percentage,
                    annotations: [.custom(label: "Range", value: "0-100%")],
                    label: "Completion Rate",
                    placeholder: "Enter percentage",
                    validation: { value in
                        if value < 0 { return "Value cannot be negative" }
                        if value > 100 { return "Value cannot exceed 100%" }
                        return nil
                    }
                )

                Divider()

                // Disabled input
                AISValueInput(
                    value: $quantity,
                    format: .integer,
                    annotations: [.label("Calculated")],
                    label: "Auto-calculated Quantity",
                    isDisabled: true
                )
            }
            .padding()
            .withAISTokens()
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
#endif
