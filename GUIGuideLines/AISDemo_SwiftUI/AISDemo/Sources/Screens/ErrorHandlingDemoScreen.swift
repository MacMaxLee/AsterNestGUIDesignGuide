// =============================================================================
// ErrorHandlingDemoScreen.swift
// AIS Demo App - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// Demonstrates the AISErrorEnvelope and related error handling components.
// Shows different error severities, states, and recovery options.
//
// =============================================================================

import SwiftUI

struct ErrorHandlingDemoScreen: View {
    // MARK: - State

    @State private var loadingState: AISLoadingState<[String]> = .idle
    @State private var showBanner = false
    @State private var bannerError: AISErrorInfo?

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AISSpacing.xl) {
                // Header
                headerSection

                // Error Severities
                errorSeveritiesSection

                // Inline Errors
                inlineErrorsSection

                // Error Envelope Demo
                errorEnvelopeSection

                // Error Banner Demo
                errorBannerSection
            }
            .padding(AISSpacing.lg)
        }
        .navigationTitle("Error Handling")
        .overlay(alignment: .top) {
            if showBanner, let error = bannerError {
                AISErrorBanner(
                    error: error,
                    autoDismissAfter: 5,
                    onDismiss: { showBanner = false }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, AISSpacing.md)
            }
        }
        .animation(.spring(response: 0.3), value: showBanner)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            Text("AIS Error Handling")
                .font(.title2.bold())

            Text("Consistent error display with appropriate severity levels, actionable recovery options, and accessibility support.")
                .font(.body)
                .foregroundColor(tokens.onSurfaceSecondary)
        }
    }

    private var errorSeveritiesSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Error Severities", description: "Different visual treatment for error types")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AISSpacing.md) {
                severityCard(.info, title: "Info", description: "Non-blocking informational message")
                severityCard(.warning, title: "Warning", description: "Should be addressed but not blocking")
                severityCard(.error, title: "Error", description: "Operation failed, user action may help")
                severityCard(.critical, title: "Critical", description: "System failure, may need support")
            }
        }
    }

    private var inlineErrorsSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Inline Errors", description: "Compact errors for form fields")

            VStack(alignment: .leading, spacing: AISSpacing.md) {
                // Simulated form with inline errors
                formFieldWithError(
                    label: "Email",
                    value: "invalid-email",
                    error: "Please enter a valid email address",
                    severity: .error
                )

                formFieldWithError(
                    label: "Password",
                    value: "weak",
                    error: "Password should be at least 8 characters",
                    severity: .warning
                )

                formFieldWithError(
                    label: "Username",
                    value: "user123",
                    error: "This username is available",
                    severity: .info
                )
            }
            .padding()
            .background(tokens.surfaceSecondary)
            .cornerRadius(AISRadius.md)
        }
    }

    private var errorEnvelopeSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Error Envelope", description: "Wraps content with loading/error states")

            // State buttons
            HStack(spacing: AISSpacing.sm) {
                AISButton("Idle", type: .neutral, style: .outlined, size: .small) {
                    loadingState = .idle
                }

                AISButton("Loading", type: .secondary, style: .outlined, size: .small) {
                    loadingState = .loading
                }

                AISButton("Success", type: .confirm, style: .outlined, size: .small) {
                    loadingState = .success(["Item 1", "Item 2", "Item 3"])
                }

                AISButton("Error", type: .destructive, style: .outlined, size: .small) {
                    loadingState = .failure(.networkError(
                        onRetry: { loadingState = .loading; simulateLoad() },
                        onDismiss: { loadingState = .idle }
                    ))
                }
            }

            // Envelope content
            AISErrorEnvelope(
                state: loadingState,
                onRetry: { loadingState = .loading; simulateLoad() }
            ) { items in
                VStack(alignment: .leading, spacing: AISSpacing.sm) {
                    ForEach(items, id: \.self) { item in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(tokens.actionConfirm.color)
                            Text(item)
                        }
                        .padding(AISSpacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(tokens.surface)
                        .cornerRadius(AISRadius.sm)
                    }
                }
            }
            .frame(minHeight: 200)
            .padding()
            .background(tokens.surfaceSecondary)
            .cornerRadius(AISRadius.md)
        }
    }

    private var errorBannerSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Error Banners", description: "Non-blocking notifications")

            HStack(spacing: AISSpacing.sm) {
                AISButton("Info Banner", type: .secondary, size: .small) {
                    showBannerWithSeverity(.info)
                }

                AISButton("Warning Banner", type: .caution, size: .small) {
                    showBannerWithSeverity(.warning)
                }

                AISButton("Error Banner", type: .destructive, size: .small) {
                    showBannerWithSeverity(.error)
                }
            }

            Text("Banners slide in from top and can be dismissed by swiping up or tapping X. Auto-dismiss after 5 seconds.")
                .font(.caption)
                .foregroundColor(tokens.onSurfaceSecondary)
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: AISSpacing.xs) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.caption)
                .foregroundColor(tokens.onSurfaceSecondary)
        }
    }

    private func severityCard(_ severity: AISErrorSeverity, title: String, description: String) -> some View {
        let token: AISToken = {
            switch severity {
            case .info: return tokens.stateInfo
            case .warning: return tokens.stateWarning
            case .error: return tokens.stateError
            case .critical: return tokens.actionDestructive
            }
        }()

        return VStack(alignment: .leading, spacing: AISSpacing.sm) {
            HStack {
                Image(systemName: token.iconName)
                    .foregroundColor(token.color)
                Text(title)
                    .font(.subheadline.bold())
            }

            Text(description)
                .font(.caption)
                .foregroundColor(tokens.onSurfaceSecondary)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(token.color.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: AISRadius.md)
                .stroke(token.color.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(AISRadius.md)
    }

    private func formFieldWithError(
        label: String,
        value: String,
        error: String,
        severity: AISErrorSeverity
    ) -> some View {
        let errorColor = severity == .error ? tokens.stateError.color :
                         severity == .warning ? tokens.stateWarning.color :
                         tokens.stateInfo.color

        let iconName = severity == .error ? tokens.stateError.iconName :
                       severity == .warning ? tokens.stateWarning.iconName :
                       tokens.stateInfo.iconName

        return VStack(alignment: .leading, spacing: AISSpacing.xs) {
            Text(label)
                .font(.caption)
                .foregroundColor(tokens.onSurfaceSecondary)

            HStack {
                Text(value)
                    .padding(AISSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(tokens.surface)
                    .cornerRadius(AISRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AISRadius.sm)
                            .stroke(errorColor, lineWidth: 1)
                    )
            }

            // Copyable error message
            HStack(spacing: AISSpacing.xs) {
                Image(systemName: iconName)
                    .font(.caption)
                Text(error)
                    .font(.caption)
                    .textSelection(.enabled)
            }
            .foregroundColor(errorColor)
        }
    }

    // MARK: - Actions

    private func simulateLoad() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Random success/failure for demo
            if Bool.random() {
                loadingState = .success(["Item 1", "Item 2", "Item 3"])
            } else {
                loadingState = .failure(.networkError(
                    onRetry: { loadingState = .loading; simulateLoad() },
                    onDismiss: { loadingState = .idle }
                ))
            }
        }
    }

    private func showBannerWithSeverity(_ severity: AISErrorSeverity) {
        let error: AISErrorInfo
        switch severity {
        case .info:
            error = AISErrorInfo(
                title: "Update Available",
                message: "A new version of the app is available.",
                severity: .info
            )
        case .warning:
            error = AISErrorInfo(
                title: "Connection Slow",
                message: "Data may take longer to load.",
                severity: .warning
            )
        case .error:
            error = AISErrorInfo(
                title: "Sync Failed",
                message: "Unable to sync your changes. Will retry automatically.",
                severity: .error
            )
        case .critical:
            error = AISErrorInfo(
                title: "Database Error",
                message: "Please contact support for assistance.",
                severity: .critical
            )
        }

        bannerError = error
        showBanner = true
    }
}

// MARK: - Preview

#if DEBUG
struct ErrorHandlingDemoScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ErrorHandlingDemoScreen()
        }
        .withAISTokens()
    }
}
#endif
