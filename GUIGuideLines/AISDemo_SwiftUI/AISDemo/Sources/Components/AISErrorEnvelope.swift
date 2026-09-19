// =============================================================================
// AISErrorEnvelope.swift
// Asternest Interface Standard (AIS) v1.0 - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// Provides standardized error handling and display following AIS error
// presentation guidelines. This component wraps operations that may fail
// and provides consistent error UI across the application.
//
// KEY REQUIREMENTS (AIS Conformance):
// 1. CONSISTENT ERROR DISPLAY: Same error format everywhere in the app
// 2. ERROR SEVERITY LEVELS: Different visual treatment for error types
// 3. ACTIONABLE ERRORS: Provide retry/dismiss/report actions when appropriate
// 4. ACCESSIBILITY: Error state must be announced to VoiceOver
// 5. RECOVERY GUIDANCE: Show users what they can do to recover
//
// DESIGN PATTERN:
// The "Error Envelope" pattern wraps content that may fail, showing either:
// - The successful content, OR
// - An appropriate error state with recovery options
//
// USAGE:
// ```swift
// AISErrorEnvelope(
//     state: viewModel.loadingState,
//     onRetry: { viewModel.reload() }
// ) {
//     // Content to show when successful
//     DataListView(items: viewModel.items)
// }
// ```
//
// =============================================================================

import SwiftUI

// MARK: - Error Severity

/// Severity levels for errors, determining visual treatment and urgency.
///
/// ## Severity Guidelines
/// - `.info`: Non-blocking informational messages
/// - `.warning`: Issues that don't prevent use but should be addressed
/// - `.error`: Failures that block the current operation
/// - `.critical`: System-wide failures requiring immediate attention
///
public enum AISErrorSeverity: String {
    /// Informational - doesn't block functionality
    /// Example: "Feature deprecated, will be removed in future version"
    case info = "Info"

    /// Warning - should be addressed but not blocking
    /// Example: "Connection slow, data may be stale"
    case warning = "Warning"

    /// Error - operation failed, user action may help
    /// Example: "Unable to load data. Check your connection."
    case error = "Error"

    /// Critical - system-level failure, may need support
    /// Example: "Database corrupted. Contact support."
    case critical = "Critical"
}

// MARK: - Error Action

/// An action that can be taken in response to an error.
///
/// ## Common Actions
/// - Retry: Attempt the operation again
/// - Dismiss: Close the error without action
/// - Report: Send error details to support
/// - Navigate: Go to a related screen (e.g., settings)
///
public struct AISErrorAction: Identifiable {
    public let id = UUID()

    /// Display label for the action button
    public let label: String

    /// SF Symbol icon name
    public let icon: String?

    /// Button type for styling (determines color/prominence)
    public let type: AISButtonType

    /// The action to perform when tapped
    public let action: () -> Void

    public init(
        label: String,
        icon: String? = nil,
        type: AISButtonType = .primary,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.icon = icon
        self.type = type
        self.action = action
    }

    // MARK: - Common Actions

    /// Creates a standard "Retry" action
    public static func retry(_ action: @escaping () -> Void) -> AISErrorAction {
        AISErrorAction(
            label: "Retry",
            icon: "arrow.clockwise",
            type: .primary,
            action: action
        )
    }

    /// Creates a standard "Dismiss" action
    public static func dismiss(_ action: @escaping () -> Void) -> AISErrorAction {
        AISErrorAction(
            label: "Dismiss",
            icon: "xmark",
            type: .neutral,
            action: action
        )
    }

    /// Creates a standard "Report" action
    public static func report(_ action: @escaping () -> Void) -> AISErrorAction {
        AISErrorAction(
            label: "Report Issue",
            icon: "exclamationmark.bubble",
            type: .caution,
            action: action
        )
    }

    /// Creates a standard "Go to Settings" action
    public static func settings(_ action: @escaping () -> Void) -> AISErrorAction {
        AISErrorAction(
            label: "Settings",
            icon: "gear",
            type: .secondary,
            action: action
        )
    }
}

// MARK: - Error Info

/// Complete error information for display purposes.
///
/// ## Properties
/// - `title`: Brief summary of the error
/// - `message`: Detailed explanation and guidance
/// - `severity`: Visual treatment level
/// - `code`: Optional error code for support reference
/// - `technicalDetails`: Optional debug info (shown in developer mode)
///
public struct AISErrorInfo: Identifiable {
    public let id = UUID()

    /// Brief summary (e.g., "Connection Failed")
    public let title: String

    /// Detailed message with recovery guidance
    public let message: String

    /// Error severity for visual treatment
    public let severity: AISErrorSeverity

    /// Optional error code for support reference
    public let code: String?

    /// Optional technical details (for debugging)
    public let technicalDetails: String?

    /// Available actions for the user
    public let actions: [AISErrorAction]

    public init(
        title: String,
        message: String,
        severity: AISErrorSeverity = .error,
        code: String? = nil,
        technicalDetails: String? = nil,
        actions: [AISErrorAction] = []
    ) {
        self.title = title
        self.message = message
        self.severity = severity
        self.code = code
        self.technicalDetails = technicalDetails
        self.actions = actions
    }

    // MARK: - Common Errors

    /// Creates a network connection error
    public static func networkError(
        onRetry: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) -> AISErrorInfo {
        var actions = [AISErrorAction.retry(onRetry)]
        if let dismiss = onDismiss {
            actions.append(.dismiss(dismiss))
        }

        return AISErrorInfo(
            title: "Connection Failed",
            message: "Unable to connect to the server. Please check your internet connection and try again.",
            severity: .error,
            code: "NET_001",
            actions: actions
        )
    }

    /// Creates a data loading error
    public static func loadError(
        _ message: String? = nil,
        onRetry: @escaping () -> Void
    ) -> AISErrorInfo {
        AISErrorInfo(
            title: "Failed to Load",
            message: message ?? "Unable to load the requested data. Please try again.",
            severity: .error,
            code: "LOAD_001",
            actions: [.retry(onRetry)]
        )
    }

    /// Creates an authentication error
    public static func authError(
        onLogin: @escaping () -> Void
    ) -> AISErrorInfo {
        AISErrorInfo(
            title: "Session Expired",
            message: "Your session has expired. Please log in again to continue.",
            severity: .warning,
            code: "AUTH_001",
            actions: [
                AISErrorAction(
                    label: "Log In",
                    icon: "person.crop.circle",
                    type: .primary,
                    action: onLogin
                )
            ]
        )
    }

    /// Creates a validation error
    public static func validationError(
        _ message: String,
        onDismiss: @escaping () -> Void
    ) -> AISErrorInfo {
        AISErrorInfo(
            title: "Validation Error",
            message: message,
            severity: .warning,
            actions: [.dismiss(onDismiss)]
        )
    }
}

// MARK: - Loading State

/// Represents the state of an async operation that may fail.
///
/// ## States
/// - `.idle`: Not started
/// - `.loading`: In progress
/// - `.success`: Completed successfully with data
/// - `.failure`: Failed with error info
///
/// ## Generic Type
/// - `T`: The type of data returned on success
///
/// ## Example
/// ```swift
/// @Published var state: AISLoadingState<[Product]> = .idle
///
/// func load() async {
///     state = .loading
///     do {
///         let products = try await api.fetchProducts()
///         state = .success(products)
///     } catch {
///         state = .failure(AISErrorInfo.networkError(onRetry: { Task { await load() } }))
///     }
/// }
/// ```
///
public enum AISLoadingState<T> {
    /// Operation not yet started
    case idle

    /// Operation in progress
    case loading

    /// Operation completed successfully
    case success(T)

    /// Operation failed with error
    case failure(AISErrorInfo)

    /// Whether the operation is currently loading
    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    /// The success value, if in success state
    public var value: T? {
        if case .success(let value) = self { return value }
        return nil
    }

    /// The error info, if in failure state
    public var error: AISErrorInfo? {
        if case .failure(let error) = self { return error }
        return nil
    }
}

// MARK: - Error Envelope View

/// A view that wraps content with standardized error handling.
///
/// ## Features
/// - Shows loading indicator during async operations
/// - Displays appropriate error UI on failure
/// - Shows content on success
/// - Provides retry/dismiss actions
/// - Accessible with VoiceOver announcements
///
/// ## Example
/// ```swift
/// struct ProductListView: View {
///     @StateObject var viewModel = ProductViewModel()
///
///     var body: some View {
///         AISErrorEnvelope(
///             state: viewModel.loadingState,
///             onRetry: { Task { await viewModel.load() } }
///         ) { products in
///             ForEach(products) { product in
///                 ProductRow(product: product)
///             }
///         }
///         .task { await viewModel.load() }
///     }
/// }
/// ```
///
public struct AISErrorEnvelope<T, Content: View>: View {
    // MARK: - Properties

    /// The loading state to observe
    let state: AISLoadingState<T>

    /// Default retry action (used if error doesn't provide one)
    let onRetry: (() -> Void)?

    /// Content to display on success
    let content: (T) -> Content

    /// Optional custom loading view
    let loadingView: AnyView?

    /// Optional custom empty state view (when T is a collection and empty)
    let emptyView: AnyView?

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - Initialization

    /// Creates an error envelope with the specified state and content.
    ///
    /// - Parameters:
    ///   - state: The loading state to observe
    ///   - onRetry: Default retry action
    ///   - content: Content builder for success state
    ///
    public init(
        state: AISLoadingState<T>,
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.state = state
        self.onRetry = onRetry
        self.content = content
        self.loadingView = nil
        self.emptyView = nil
    }

    /// Creates an error envelope with custom loading and empty views.
    ///
    /// - Parameters:
    ///   - state: The loading state to observe
    ///   - onRetry: Default retry action
    ///   - loadingView: Custom loading view
    ///   - emptyView: Custom empty state view
    ///   - content: Content builder for success state
    ///
    public init<LoadingView: View, EmptyView: View>(
        state: AISLoadingState<T>,
        onRetry: (() -> Void)? = nil,
        @ViewBuilder loadingView: () -> LoadingView,
        @ViewBuilder emptyView: () -> EmptyView,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.state = state
        self.onRetry = onRetry
        self.content = content
        self.loadingView = AnyView(loadingView())
        self.emptyView = AnyView(emptyView())
    }

    // MARK: - Body

    public var body: some View {
        switch state {
        case .idle:
            idleView

        case .loading:
            if let custom = loadingView {
                custom
            } else {
                defaultLoadingView
            }

        case .success(let value):
            content(value)

        case .failure(let error):
            AISErrorView(
                error: error,
                onRetry: onRetry
            )
        }
    }

    // MARK: - Default Views

    private var idleView: some View {
        Color.clear
    }

    private var defaultLoadingView: some View {
        VStack(spacing: AISSpacing.md) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(tokens.onSurfaceSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error View

/// A standalone error display view.
///
/// ## Features
/// - Displays error title, message, and code
/// - Shows appropriate icon based on severity
/// - Provides action buttons
/// - Expandable technical details (debug mode)
/// - VoiceOver accessible
///
/// ## Example
/// ```swift
/// AISErrorView(
///     error: .networkError(onRetry: { reload() }),
///     onRetry: { reload() }
/// )
/// ```
///
public struct AISErrorView: View {
    // MARK: - Properties

    let error: AISErrorInfo
    let onRetry: (() -> Void)?

    @Environment(\.aisTokens) private var tokens

    @State private var showTechnicalDetails = false

    public init(error: AISErrorInfo, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }

    // MARK: - Computed Properties

    /// Returns the appropriate token for the error severity
    private var severityToken: AISToken {
        switch error.severity {
        case .info:
            return tokens.stateInfo
        case .warning:
            return tokens.stateWarning
        case .error:
            return tokens.stateError
        case .critical:
            return tokens.actionDestructive
        }
    }

    /// Returns the icon for the error severity
    private var severityIcon: String {
        switch error.severity {
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "exclamationmark.circle.fill"
        case .critical:
            return "exclamationmark.octagon.fill"
        }
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: AISSpacing.lg) {
            // Icon
            Image(systemName: severityIcon)
                .font(.system(size: 50))
                .foregroundColor(severityToken.color)

            // Title and message
            VStack(spacing: AISSpacing.sm) {
                Text(error.title)
                    .font(.title2.bold())
                    .foregroundColor(tokens.onSurface)

                Text(error.message)
                    .font(.body)
                    .foregroundColor(tokens.onSurfaceSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)

                // Error code
                if let code = error.code {
                    Text("Error Code: \(code)")
                        .font(.caption.monospaced())
                        .foregroundColor(tokens.onSurfaceSecondary)
                        .padding(.top, AISSpacing.xs)
                        .textSelection(.enabled)
                }
            }

            // Technical details (expandable)
            if let details = error.technicalDetails {
                DisclosureGroup(
                    isExpanded: $showTechnicalDetails,
                    content: {
                        Text(details)
                            .font(.caption.monospaced())
                            .foregroundColor(tokens.onSurfaceSecondary)
                            .padding(AISSpacing.sm)
                            .background(tokens.surfaceSecondary)
                            .cornerRadius(AISRadius.sm)
                            .textSelection(.enabled)
                    },
                    label: {
                        Text("Technical Details")
                            .font(.caption)
                            .foregroundColor(tokens.onSurfaceSecondary)
                    }
                )
            }

            // Action buttons
            if !error.actions.isEmpty {
                actionButtons
            } else if let retry = onRetry {
                // Default retry button if no actions provided
                AISButton("Try Again", type: .primary, icon: "arrow.clockwise") {
                    retry()
                }
            }
        }
        .padding(AISSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(error.severity.rawValue) alert: \(error.title). \(error.message)")
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: AISSpacing.sm) {
            ForEach(error.actions) { action in
                AISButton(
                    action.label,
                    type: action.type,
                    icon: action.icon,
                    showIcon: action.icon != nil
                ) {
                    action.action()
                }
            }
        }
    }
}

// MARK: - Inline Error View

/// A compact inline error view for form fields and small spaces.
///
/// ## Example
/// ```swift
/// VStack {
///     TextField("Email", text: $email)
///
///     if let error = emailError {
///         AISInlineError(message: error)
///     }
/// }
/// ```
///
public struct AISInlineError: View {
    let message: String
    let severity: AISErrorSeverity

    @Environment(\.aisTokens) private var tokens

    public init(
        message: String,
        severity: AISErrorSeverity = .error
    ) {
        self.message = message
        self.severity = severity
    }

    private var token: AISToken {
        switch severity {
        case .info: return tokens.stateInfo
        case .warning: return tokens.stateWarning
        case .error: return tokens.stateError
        case .critical: return tokens.actionDestructive
        }
    }

    public var body: some View {
        Label {
            Text(message)
                .font(.caption)
        } icon: {
            Image(systemName: token.iconName)
                .font(.caption)
        }
        .foregroundColor(token.color)
        .textSelection(.enabled)
        .accessibilityLabel("\(severity.rawValue) message: \(message)")
    }
}

// MARK: - Error Banner View

/// A banner-style error view for non-blocking notifications.
///
/// ## Features
/// - Slides in from top or bottom
/// - Auto-dismisses after timeout (optional)
/// - Swipe to dismiss
/// - Action button support
///
/// ## Example
/// ```swift
/// .overlay(alignment: .top) {
///     if showError {
///         AISErrorBanner(
///             error: .networkError(onRetry: { }),
///             onDismiss: { showError = false }
///         )
///         .transition(.move(edge: .top).combined(with: .opacity))
///     }
/// }
/// ```
///
public struct AISErrorBanner: View {
    let error: AISErrorInfo
    let onDismiss: () -> Void
    let autoDismissAfter: TimeInterval?

    @Environment(\.aisTokens) private var tokens
    @State private var offset: CGFloat = 0

    public init(
        error: AISErrorInfo,
        autoDismissAfter: TimeInterval? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.error = error
        self.autoDismissAfter = autoDismissAfter
        self.onDismiss = onDismiss
    }

    private var severityToken: AISToken {
        switch error.severity {
        case .info: return tokens.stateInfo
        case .warning: return tokens.stateWarning
        case .error: return tokens.stateError
        case .critical: return tokens.actionDestructive
        }
    }

    public var body: some View {
        HStack(spacing: AISSpacing.md) {
            Image(systemName: severityToken.iconName)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text(error.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                Text(error.message)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            .textSelection(.enabled)

            Spacer()

            // Copy button
            Button {
                let textToCopy = "\(error.title): \(error.message)"
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(textToCopy, forType: .string)
                #endif
            } label: {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
            .help("Copy message")

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(AISSpacing.md)
        .background(severityToken.color)
        .cornerRadius(AISRadius.md)
        .shadow(radius: 4)
        .padding(.horizontal, AISSpacing.md)
        .offset(y: offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height < 0 {
                        offset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height < -50 {
                        onDismiss()
                    } else {
                        withAnimation {
                            offset = 0
                        }
                    }
                }
        )
        .onAppear {
            if let delay = autoDismissAfter {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    onDismiss()
                }
            }
        }
        .accessibilityLabel("Alert: \(error.title). \(error.message)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Swipe up or tap X to dismiss")
    }
}

// MARK: - Preview

#if DEBUG
struct AISErrorEnvelope_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AISSpacing.xl) {
            // Error view
            AISErrorView(
                error: .networkError(
                    onRetry: { print("Retry") },
                    onDismiss: { print("Dismiss") }
                )
            )

            Divider()

            // Inline errors
            VStack(alignment: .leading, spacing: AISSpacing.sm) {
                AISInlineError(message: "Email is required", severity: .error)
                AISInlineError(message: "Password is weak", severity: .warning)
                AISInlineError(message: "Optional field", severity: .info)
            }

            Divider()

            // Banner preview
            AISErrorBanner(
                error: AISErrorInfo(
                    title: "Connection Lost",
                    message: "Attempting to reconnect...",
                    severity: .warning
                ),
                onDismiss: { print("Dismissed") }
            )
        }
        .padding()
        .withAISTokens()
    }
}
#endif
