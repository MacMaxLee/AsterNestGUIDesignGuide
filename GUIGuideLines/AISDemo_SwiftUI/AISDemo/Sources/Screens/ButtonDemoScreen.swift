// =============================================================================
// ButtonDemoScreen.swift
// AIS Demo App - SwiftUI Implementation
// =============================================================================
//
// PURPOSE:
// Demonstrates all AISButton variations including types, styles, sizes,
// and states. This screen serves as both a showcase and a reference for
// correct button usage in AIS-compliant applications.
//
// =============================================================================

import SwiftUI

struct ButtonDemoScreen: View {
    // MARK: - State

    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    // MARK: - Environment

    @Environment(\.aisTokens) private var tokens

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AISSpacing.xl) {
                // Header
                headerSection

                // Button Types Section
                buttonTypesSection

                // Button Styles Section
                buttonStylesSection

                // Button Sizes Section
                buttonSizesSection

                // Button States Section
                buttonStatesSection

                // Full Width Section
                fullWidthSection

                // Icon-Only Section
                iconOnlySection
            }
            .padding(AISSpacing.lg)
        }
        .navigationTitle("Buttons")
        .alert("Button Tapped", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            Text("AIS Semantic Buttons")
                .font(.title2.bold())

            Text("Buttons are categorized by their semantic meaning, not appearance. Choose the button type based on what the action MEANS.")
                .font(.body)
                .foregroundColor(tokens.onSurfaceSecondary)
        }
    }

    private var buttonTypesSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Button Types", description: "Each type has a specific semantic meaning")

            VStack(spacing: AISSpacing.sm) {
                buttonRow("Primary", description: "Main action (Save, Submit)", type: .primary)
                buttonRow("Confirm", description: "Affirmative (Approve, Accept)", type: .confirm)
                buttonRow("Caution", description: "Significant change (Edit, Modify)", type: .caution)
                buttonRow("Destructive", description: "Harmful action (Delete, Remove)", type: .destructive)
                buttonRow("Neutral", description: "Non-committal (Cancel, Close)", type: .neutral)
                buttonRow("Secondary", description: "Alternative action", type: .secondary)
            }
        }
    }

    private var buttonStylesSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Button Styles", description: "Visual variations for different contexts")

            HStack(spacing: AISSpacing.md) {
                VStack(spacing: AISSpacing.sm) {
                    Text("Filled").font(.caption).foregroundColor(tokens.onSurfaceSecondary)
                    AISButton("Filled", type: .primary, style: .filled) {
                        showButtonTapped("Filled Primary")
                    }
                }

                VStack(spacing: AISSpacing.sm) {
                    Text("Outlined").font(.caption).foregroundColor(tokens.onSurfaceSecondary)
                    AISButton("Outlined", type: .primary, style: .outlined) {
                        showButtonTapped("Outlined Primary")
                    }
                }

                VStack(spacing: AISSpacing.sm) {
                    Text("Text").font(.caption).foregroundColor(tokens.onSurfaceSecondary)
                    AISButton("Text", type: .primary, style: .text) {
                        showButtonTapped("Text Primary")
                    }
                }
            }
        }
    }

    private var buttonSizesSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Button Sizes", description: "Small, Medium (default), and Large")

            HStack(spacing: AISSpacing.md) {
                VStack(spacing: AISSpacing.sm) {
                    Text("Small").font(.caption).foregroundColor(tokens.onSurfaceSecondary)
                    AISButton("Small", type: .primary, size: .small) {
                        showButtonTapped("Small")
                    }
                }

                VStack(spacing: AISSpacing.sm) {
                    Text("Medium").font(.caption).foregroundColor(tokens.onSurfaceSecondary)
                    AISButton("Medium", type: .primary, size: .medium) {
                        showButtonTapped("Medium")
                    }
                }

                VStack(spacing: AISSpacing.sm) {
                    Text("Large").font(.caption).foregroundColor(tokens.onSurfaceSecondary)
                    AISButton("Large", type: .primary, size: .large) {
                        showButtonTapped("Large")
                    }
                }
            }
        }
    }

    private var buttonStatesSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Button States", description: "Loading and disabled states")

            HStack(spacing: AISSpacing.md) {
                VStack(spacing: AISSpacing.sm) {
                    Text("Normal").font(.caption).foregroundColor(tokens.onSurfaceSecondary)
                    AISButton("Normal", type: .primary) {
                        showButtonTapped("Normal")
                    }
                }

                VStack(spacing: AISSpacing.sm) {
                    Text("Loading").font(.caption).foregroundColor(tokens.onSurfaceSecondary)
                    AISButton("Loading", type: .primary, isLoading: true) { }
                }

                VStack(spacing: AISSpacing.sm) {
                    Text("Disabled").font(.caption).foregroundColor(tokens.onSurfaceSecondary)
                    AISButton("Disabled", type: .primary, isDisabled: true) { }
                }
            }

            // Interactive loading demo
            HStack(spacing: AISSpacing.md) {
                AISButton(
                    isLoading ? "Processing..." : "Start Operation",
                    type: .confirm,
                    isLoading: isLoading
                ) {
                    startLoadingDemo()
                }

                if isLoading {
                    AISButton("Cancel", type: .neutral) {
                        isLoading = false
                    }
                }
            }
        }
    }

    private var fullWidthSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Full Width", description: "Buttons that expand to fill container")

            AISButton("Full Width Primary", type: .primary, fullWidth: true) {
                showButtonTapped("Full Width")
            }

            AISButton("Full Width Outlined", type: .confirm, style: .outlined, fullWidth: true) {
                showButtonTapped("Full Width Outlined")
            }
        }
    }

    private var iconOnlySection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader("Icon-Only Buttons", description: "Compact buttons for toolbars")

            HStack(spacing: AISSpacing.md) {
                AISButton.icon("plus", type: .primary, accessibilityLabel: "Add item") {
                    showButtonTapped("Add")
                }

                AISButton.icon("pencil", type: .caution, accessibilityLabel: "Edit item") {
                    showButtonTapped("Edit")
                }

                AISButton.icon("trash", type: .destructive, accessibilityLabel: "Delete item") {
                    showButtonTapped("Delete")
                }

                AISButton.icon("xmark", type: .neutral, accessibilityLabel: "Close") {
                    showButtonTapped("Close")
                }
            }
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

    private func buttonRow(_ title: String, description: String, type: AISButtonType) -> some View {
        HStack {
            AISButton(title, type: type) {
                showButtonTapped(title)
            }

            Text(description)
                .font(.caption)
                .foregroundColor(tokens.onSurfaceSecondary)

            Spacer()
        }
    }

    // MARK: - Actions

    private func showButtonTapped(_ name: String) {
        alertMessage = "\(name) button was tapped"
        showAlert = true
    }

    private func startLoadingDemo() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isLoading = false
            alertMessage = "Operation completed!"
            showAlert = true
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ButtonDemoScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ButtonDemoScreen()
        }
        .withAISTokens()
    }
}
#endif
