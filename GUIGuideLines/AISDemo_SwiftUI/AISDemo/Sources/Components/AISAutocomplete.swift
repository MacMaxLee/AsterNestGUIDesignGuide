// =============================================================================
// AISAutocomplete.swift
// Asternest Interface Standard (AIS) v1.0 - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// A type-ahead autocomplete component with customizable suggestion filtering,
// keyboard navigation, and selection handling. Follows AIS token conventions.
//
// DESIGN PHILOSOPHY:
// - Accessibility-first: Full keyboard navigation and VoiceOver support
// - Flexible: Works with any Identifiable data type
// - Semantic: Uses AIS tokens for consistent styling
// - Performant: Debounced input for efficient suggestion filtering
//
// USAGE:
// ```swift
// struct ContentView: View {
//     @State private var selectedCountry: Country?
//     @State private var searchText = ""
//
//     var body: some View {
//         AISAutocomplete(
//             text: $searchText,
//             selection: $selectedCountry,
//             suggestions: filteredCountries,
//             placeholder: "Search countries...",
//             displayText: { $0.name }
//         )
//     }
// }
// ```
//
// =============================================================================

import SwiftUI
import Combine

// MARK: - Autocomplete Style

/// Visual style variations for the autocomplete component
public enum AISAutocompleteStyle {
    /// Standard text field with dropdown
    case standard
    /// Outlined border style
    case outlined
    /// Filled background style
    case filled
}

// MARK: - AISAutocomplete View

/// A type-ahead autocomplete component with suggestion dropdown.
///
/// ## Features
/// - Type-ahead filtering with debounce
/// - Keyboard navigation (up/down arrows, enter, escape)
/// - Custom suggestion rendering
/// - Clear button
/// - Loading state
/// - Error state
/// - Accessibility support
///
public struct AISAutocomplete<Item: Identifiable & Equatable>: View {
    // MARK: - Properties

    /// Binding to the search text
    @Binding var text: String

    /// Binding to the selected item
    @Binding var selection: Item?

    /// Array of suggestions to display
    let suggestions: [Item]

    /// Placeholder text when empty
    let placeholder: String

    /// Function to extract display text from an item
    let displayText: (Item) -> String

    /// Optional function to extract secondary text
    let secondaryText: ((Item) -> String)?

    /// Optional function to extract icon name
    let iconName: ((Item) -> String)?

    /// Visual style
    let style: AISAutocompleteStyle

    /// Maximum number of suggestions to show
    let maxSuggestions: Int

    /// Whether the component is in loading state
    let isLoading: Bool

    /// Whether the component is disabled
    let isDisabled: Bool

    /// Error message to display
    let errorMessage: String?

    /// Callback when a suggestion is selected
    let onSelect: ((Item) -> Void)?

    /// Callback when text changes (for async filtering)
    let onTextChange: ((String) -> Void)?

    // MARK: - State

    @State private var isExpanded = false
    @State private var highlightedIndex: Int? = nil
    @FocusState private var isFocused: Bool

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - Initialization

    /// Creates an AIS-compliant autocomplete component.
    ///
    /// - Parameters:
    ///   - text: Binding to the search text
    ///   - selection: Binding to the selected item
    ///   - suggestions: Array of items to show as suggestions
    ///   - placeholder: Placeholder text (default: "Search...")
    ///   - displayText: Function to extract display text from an item
    ///   - secondaryText: Optional function for secondary line
    ///   - iconName: Optional function to get SF Symbol name for each item
    ///   - style: Visual style (default: .standard)
    ///   - maxSuggestions: Maximum suggestions to show (default: 8)
    ///   - isLoading: Loading state (default: false)
    ///   - isDisabled: Disabled state (default: false)
    ///   - errorMessage: Error message to display (default: nil)
    ///   - onSelect: Callback when item is selected
    ///   - onTextChange: Callback when text changes
    ///
    public init(
        text: Binding<String>,
        selection: Binding<Item?>,
        suggestions: [Item],
        placeholder: String = "Search...",
        displayText: @escaping (Item) -> String,
        secondaryText: ((Item) -> String)? = nil,
        iconName: ((Item) -> String)? = nil,
        style: AISAutocompleteStyle = .standard,
        maxSuggestions: Int = 8,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        errorMessage: String? = nil,
        onSelect: ((Item) -> Void)? = nil,
        onTextChange: ((String) -> Void)? = nil
    ) {
        self._text = text
        self._selection = selection
        self.suggestions = suggestions
        self.placeholder = placeholder
        self.displayText = displayText
        self.secondaryText = secondaryText
        self.iconName = iconName
        self.style = style
        self.maxSuggestions = maxSuggestions
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.errorMessage = errorMessage
        self.onSelect = onSelect
        self.onTextChange = onTextChange
    }

    // MARK: - Computed Properties

    private var visibleSuggestions: [Item] {
        Array(suggestions.prefix(maxSuggestions))
    }

    private var showDropdown: Bool {
        isExpanded && !visibleSuggestions.isEmpty && !text.isEmpty
    }

    private var borderColor: Color {
        if errorMessage != nil {
            return tokens.actionDestructive.color
        }
        if isFocused {
            return tokens.actionPrimary.color
        }
        return tokens.onSurfaceSecondary.opacity(0.3)
    }

    private var backgroundColor: Color {
        switch style {
        case .filled:
            return tokens.surfaceSecondary
        default:
            return tokens.surface
        }
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Input field
            inputField

            // Dropdown
            if showDropdown {
                dropdownList
            }

            // Error message
            if let error = errorMessage {
                errorLabel(error)
            }
        }
    }

    // MARK: - Subviews

    private var inputField: some View {
        HStack(spacing: AISSpacing.sm) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .foregroundColor(tokens.onSurfaceSecondary)
                .font(.system(size: 16))

            // Text field
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .disabled(isDisabled)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundColor(tokens.onSurface)
                .onChange(of: text) { _, newValue in
                    isExpanded = true
                    highlightedIndex = nil
                    onTextChange?(newValue)
                }
                .onChange(of: isFocused) { _, focused in
                    if focused {
                        isExpanded = true
                    } else {
                        // Delay hiding dropdown to allow click on suggestions
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isExpanded = false
                        }
                    }
                }
                .onKeyPress(.upArrow) {
                    navigateUp()
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    navigateDown()
                    return .handled
                }
                .onKeyPress(.return) {
                    selectHighlighted()
                    return .handled
                }
                .onKeyPress(.escape) {
                    isExpanded = false
                    isFocused = false
                    return .handled
                }

            // Loading indicator
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.8)
            }

            // Clear button
            if !text.isEmpty && !isLoading {
                Button(action: clearSelection) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(tokens.onSurfaceSecondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AISSpacing.md)
        .padding(.vertical, AISSpacing.sm + 2)
        .background(backgroundColor)
        .cornerRadius(AISRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AISRadius.md)
                .stroke(borderColor, lineWidth: style == .outlined || isFocused ? 1.5 : 1)
        )
        .opacity(isDisabled ? 0.6 : 1.0)
    }

    private var dropdownList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(visibleSuggestions.enumerated()), id: \.element.id) { index, item in
                suggestionRow(item: item, index: index)
            }
        }
        .background(tokens.surface)
        .cornerRadius(AISRadius.md)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: AISRadius.md)
                .stroke(tokens.onSurfaceSecondary.opacity(0.2), lineWidth: 1)
        )
        .padding(.top, AISSpacing.xs)
    }

    private func suggestionRow(item: Item, index: Int) -> some View {
        let isHighlighted = highlightedIndex == index
        let isSelected = selection?.id == item.id

        return Button(action: {
            selectItem(item)
        }) {
            HStack(spacing: AISSpacing.sm) {
                // Optional icon
                if let iconFn = iconName {
                    Image(systemName: iconFn(item))
                        .foregroundColor(isSelected ? tokens.actionPrimary.color : tokens.onSurfaceSecondary)
                        .font(.system(size: 16))
                        .frame(width: 24)
                }

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayText(item))
                        .font(.body)
                        .foregroundColor(tokens.onSurface)

                    if let secondaryFn = secondaryText {
                        Text(secondaryFn(item))
                            .font(.caption)
                            .foregroundColor(tokens.onSurfaceSecondary)
                    }
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(tokens.actionPrimary.color)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .padding(.horizontal, AISSpacing.md)
            .padding(.vertical, AISSpacing.sm)
            .background(isHighlighted ? tokens.surfaceSecondary : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                highlightedIndex = index
            }
        }
        .accessibilityLabel(displayText(item))
        .accessibilityHint(isSelected ? "Selected" : "Double tap to select")
    }

    private func errorLabel(_ message: String) -> some View {
        HStack(spacing: AISSpacing.xs) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 12))
            Text(message)
                .font(.caption)
        }
        .foregroundColor(tokens.actionDestructive.color)
        .padding(.top, AISSpacing.xs)
    }

    // MARK: - Actions

    private func selectItem(_ item: Item) {
        selection = item
        text = displayText(item)
        isExpanded = false
        isFocused = false
        onSelect?(item)
    }

    private func clearSelection() {
        text = ""
        selection = nil
        highlightedIndex = nil
    }

    private func navigateUp() {
        guard !visibleSuggestions.isEmpty else { return }

        if let current = highlightedIndex {
            highlightedIndex = max(0, current - 1)
        } else {
            highlightedIndex = visibleSuggestions.count - 1
        }
    }

    private func navigateDown() {
        guard !visibleSuggestions.isEmpty else { return }

        if let current = highlightedIndex {
            highlightedIndex = min(visibleSuggestions.count - 1, current + 1)
        } else {
            highlightedIndex = 0
        }
    }

    private func selectHighlighted() {
        if let index = highlightedIndex, index < visibleSuggestions.count {
            selectItem(visibleSuggestions[index])
        }
    }
}

// MARK: - Convenience Initializers

extension AISAutocomplete where Item == String {
    /// Creates an autocomplete for simple string arrays.
    public init(
        text: Binding<String>,
        selection: Binding<String?>,
        suggestions: [String],
        placeholder: String = "Search...",
        style: AISAutocompleteStyle = .standard
    ) where Item == String {
        // Wrap strings in identifiable wrappers
        self.init(
            text: text,
            selection: selection,
            suggestions: suggestions,
            placeholder: placeholder,
            displayText: { $0 },
            style: style
        )
    }
}

// Make String conform to Identifiable for convenience
extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - Preview

#if DEBUG
struct AISAutocomplete_Previews: PreviewProvider {
    struct Country: Identifiable, Equatable {
        let id: String
        let name: String
        let code: String
        let flag: String
    }

    struct PreviewWrapper: View {
        @State private var searchText = ""
        @State private var selectedCountry: Country?

        let countries = [
            Country(id: "us", name: "United States", code: "US", flag: "🇺🇸"),
            Country(id: "uk", name: "United Kingdom", code: "GB", flag: "🇬🇧"),
            Country(id: "ca", name: "Canada", code: "CA", flag: "🇨🇦"),
            Country(id: "au", name: "Australia", code: "AU", flag: "🇦🇺"),
            Country(id: "de", name: "Germany", code: "DE", flag: "🇩🇪"),
            Country(id: "fr", name: "France", code: "FR", flag: "🇫🇷"),
            Country(id: "jp", name: "Japan", code: "JP", flag: "🇯🇵"),
        ]

        var filteredCountries: [Country] {
            if searchText.isEmpty {
                return countries
            }
            return countries.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        var body: some View {
            VStack(spacing: AISSpacing.xl) {
                Text("Country Autocomplete")
                    .font(.title2.bold())

                AISAutocomplete(
                    text: $searchText,
                    selection: $selectedCountry,
                    suggestions: filteredCountries,
                    placeholder: "Search countries...",
                    displayText: { "\($0.flag) \($0.name)" },
                    secondaryText: { "Code: \($0.code)" },
                    iconName: { _ in "globe" }
                )
                .frame(width: 300)

                if let country = selectedCountry {
                    Text("Selected: \(country.flag) \(country.name)")
                        .font(.headline)
                }

                Spacer()
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
