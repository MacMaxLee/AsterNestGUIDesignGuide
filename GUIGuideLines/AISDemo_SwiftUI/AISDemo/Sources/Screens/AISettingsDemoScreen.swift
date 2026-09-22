// =============================================================================
// AISettingsDemoScreen.swift
// AI Provider Settings Configuration Demo
// =============================================================================

import SwiftUI

// MARK: - AI Provider Types

/// Cloud LLM provider types
enum CloudLLMProvider: String, CaseIterable, Identifiable {
    case claude = "Claude (Anthropic)"
    case chatgpt = "ChatGPT (OpenAI)"
    case gemini = "Gemini (Google)"

    var id: String { rawValue }

    var defaultEndpoint: String {
        switch self {
        case .claude: return "https://api.anthropic.com/v1/messages"
        case .chatgpt: return "https://api.openai.com/v1/chat/completions"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta/models"
        }
    }

    var defaultModel: String {
        switch self {
        case .claude: return "claude-3-5-sonnet-20241022"
        case .chatgpt: return "gpt-4o"
        case .gemini: return "gemini-1.5-pro"
        }
    }

    var iconName: String {
        switch self {
        case .claude: return "sparkles"
        case .chatgpt: return "bubble.left.and.bubble.right"
        case .gemini: return "diamond"
        }
    }

    var brandColor: Color {
        switch self {
        case .claude: return Color(red: 0.85, green: 0.47, blue: 0.02) // Amber
        case .chatgpt: return Color(red: 0.06, green: 0.73, blue: 0.51) // Green
        case .gemini: return Color(red: 0.23, green: 0.51, blue: 0.96) // Blue
        }
    }
}

/// Local AI provider types
enum LocalAIProvider: String, CaseIterable, Identifiable {
    case ollama = "Ollama"
    case lmStudio = "LM Studio"
    case custom = "Custom Endpoint"

    var id: String { rawValue }

    var defaultEndpoint: String {
        switch self {
        case .ollama: return "http://localhost:11434/api/generate"
        case .lmStudio: return "http://localhost:1234/v1/chat/completions"
        case .custom: return ""
        }
    }

    var iconName: String {
        switch self {
        case .ollama: return "memorychip"
        case .lmStudio: return "laptopcomputer"
        case .custom: return "gearshape"
        }
    }
}

// MARK: - Settings Models

/// Configuration for a cloud LLM provider
class CloudLLMConfig: ObservableObject, Identifiable {
    let id = UUID()
    let provider: CloudLLMProvider
    @Published var apiKey: String
    @Published var endpoint: String
    @Published var model: String
    @Published var isEnabled: Bool
    @Published var maxTokens: Int
    @Published var temperature: Double

    init(provider: CloudLLMProvider) {
        self.provider = provider
        self.apiKey = ""
        self.endpoint = provider.defaultEndpoint
        self.model = provider.defaultModel
        self.isEnabled = false
        self.maxTokens = 4096
        self.temperature = 0.3
    }

    var isConfigured: Bool {
        isEnabled && !apiKey.isEmpty
    }
}

/// Configuration for a local AI provider
class LocalAIConfig: ObservableObject, Identifiable {
    let id = UUID()
    let provider: LocalAIProvider
    @Published var endpoint: String
    @Published var model: String
    @Published var isEnabled: Bool
    @Published var maxTokens: Int
    @Published var contextLength: Int

    init(provider: LocalAIProvider) {
        self.provider = provider
        self.endpoint = provider.defaultEndpoint
        self.model = "llama3.2"
        self.isEnabled = false
        self.maxTokens = 4096
        self.contextLength = 8192
    }
}

/// On-device AI configuration
class OnDeviceAIConfig: ObservableObject {
    @Published var useAppleVision: Bool = true
    @Published var preferredLanguage: String = "en"
}

/// Preferred processing tier
enum PreferredTier: String, CaseIterable, Identifiable {
    case onDevice = "On-Device First"
    case local = "Local AI First"
    case cloud = "Cloud AI First"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .onDevice: return "Fastest, works offline (Apple Vision)"
        case .local: return "Private, runs on your machine (Ollama / LM Studio)"
        case .cloud: return "Most accurate, requires internet (Claude / ChatGPT)"
        }
    }

    var iconName: String {
        switch self {
        case .onDevice: return "iphone"
        case .local: return "desktopcomputer"
        case .cloud: return "cloud"
        }
    }
}

// MARK: - AI Settings Demo Screen

struct AISettingsDemoScreen: View {
    @Environment(\.aisTokens) private var tokens

    // Settings state
    @State private var cloudProviders: [CloudLLMConfig] = CloudLLMProvider.allCases.map { CloudLLMConfig(provider: $0) }
    @State private var localProviders: [LocalAIConfig] = LocalAIProvider.allCases.map { LocalAIConfig(provider: $0) }
    @State private var onDeviceConfig = OnDeviceAIConfig()
    @State private var preferredTier: PreferredTier = .onDevice
    @State private var enableFallback: Bool = true

    // UI state
    @State private var selectedTab: Int = 0
    @State private var hasChanges: Bool = false
    @State private var showingSaveAlert: Bool = false
    @State private var showingResetAlert: Bool = false

    // Connection test state
    @State private var testingConnectionFor: String? = nil
    @State private var connectionTestResult: (provider: String, success: Bool, message: String)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AISSpacing.xl) {
                // Header
                headerSection

                // Tab selector
                tabSelector

                // Tab content
                tabContent

                // Footer
                footerSection
            }
            .padding(AISSpacing.lg)
        }
        .navigationTitle("AI Settings")
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                if hasChanges {
                    Button(action: saveSettings) {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                }

                Button(action: { showingResetAlert = true }) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .alert("Settings Saved", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your AI provider settings have been saved.")
        }
        .alert("Reset to Defaults?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) { resetSettings() }
        } message: {
            Text("This will clear all API keys and settings. This action cannot be undone.")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AISSpacing.sm) {
            HStack(spacing: AISSpacing.md) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundColor(tokens.actionPrimary.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Provider Settings")
                        .font(.title2.bold())
                    Text("Configure API keys and AI service endpoints")
                        .font(.subheadline)
                        .foregroundColor(tokens.onSurfaceSecondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tokens.surfaceSecondary)
        .cornerRadius(AISRadius.lg)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "Cloud AI", icon: "cloud", index: 0)
            tabButton(title: "Local AI", icon: "desktopcomputer", index: 1)
            tabButton(title: "On-Device", icon: "iphone", index: 2)
        }
        .background(tokens.surfaceSecondary)
        .cornerRadius(AISRadius.md)
    }

    private func tabButton(title: String, icon: String, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            HStack(spacing: AISSpacing.sm) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline.weight(selectedTab == index ? .semibold : .regular))
            .foregroundColor(selectedTab == index ? .white : tokens.onSurface)
            .padding(.vertical, AISSpacing.sm)
            .padding(.horizontal, AISSpacing.md)
            .frame(maxWidth: .infinity)
            .background(selectedTab == index ? tokens.actionPrimary.color : Color.clear)
            .cornerRadius(AISRadius.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            cloudProvidersTab
        case 1:
            localProvidersTab
        case 2:
            onDeviceTab
        default:
            cloudProvidersTab
        }
    }

    // MARK: - Cloud Providers Tab

    private var cloudProvidersTab: some View {
        VStack(alignment: .leading, spacing: AISSpacing.lg) {
            sectionHeader(
                title: "Cloud LLM Providers",
                subtitle: "Configure API keys for cloud-based AI services",
                icon: "cloud"
            )

            ForEach($cloudProviders) { $config in
                cloudProviderCard(config: $config)
            }

            preferredTierSelector
        }
    }

    private func cloudProviderCard(config: Binding<CloudLLMConfig>) -> some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            // Header row
            HStack {
                // Provider icon
                Image(systemName: config.wrappedValue.provider.iconName)
                    .font(.title2)
                    .foregroundColor(config.wrappedValue.provider.brandColor)
                    .frame(width: 40, height: 40)
                    .background(config.wrappedValue.provider.brandColor.opacity(0.1))
                    .cornerRadius(AISRadius.md)

                VStack(alignment: .leading, spacing: 2) {
                    Text(config.wrappedValue.provider.rawValue)
                        .font(.headline)
                    Text(config.wrappedValue.isConfigured ? "Configured" : "Not configured")
                        .font(.caption)
                        .foregroundColor(config.wrappedValue.isConfigured ? tokens.actionConfirm.color : tokens.onSurfaceSecondary)
                }

                Spacer()

                Toggle("", isOn: config.isEnabled)
                    .labelsHidden()
                    .onChange(of: config.wrappedValue.isEnabled) { _, _ in hasChanges = true }
            }

            if config.wrappedValue.isEnabled {
                Divider()

                // API Key field
                VStack(alignment: .leading, spacing: AISSpacing.xs) {
                    Text("API Key")
                        .font(.caption)
                        .foregroundColor(tokens.onSurfaceSecondary)
                    SecureField("Enter API key", text: config.apiKey)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: config.wrappedValue.apiKey) { _, _ in hasChanges = true }
                }

                // Model field
                VStack(alignment: .leading, spacing: AISSpacing.xs) {
                    Text("Model")
                        .font(.caption)
                        .foregroundColor(tokens.onSurfaceSecondary)
                    TextField("Model name", text: config.model)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: config.wrappedValue.model) { _, _ in hasChanges = true }
                }

                // Test button and result
                VStack(alignment: .trailing, spacing: AISSpacing.sm) {
                    HStack {
                        Spacer()
                        Button(action: { testCloudConnection(config.wrappedValue) }) {
                            HStack(spacing: AISSpacing.xs) {
                                if testingConnectionFor == config.wrappedValue.provider.rawValue {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "network")
                                }
                                Text("Test Connection")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(testingConnectionFor != nil)
                    }

                    // Show result for this provider
                    if let result = connectionTestResult, result.provider == config.wrappedValue.provider.rawValue {
                        HStack(spacing: AISSpacing.xs) {
                            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.success ? .green : .red)
                            Text(result.message)
                                .font(.caption)
                                .foregroundColor(result.success ? .green : .red)
                        }
                        .padding(AISSpacing.sm)
                        .frame(maxWidth: .infinity)
                        .background(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(AISRadius.sm)
                    }
                }
            }
        }
        .padding()
        .background(tokens.surface)
        .cornerRadius(AISRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AISRadius.lg)
                .stroke(tokens.onSurface.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Local Providers Tab

    private var localProvidersTab: some View {
        VStack(alignment: .leading, spacing: AISSpacing.lg) {
            sectionHeader(
                title: "Local AI Providers",
                subtitle: "Configure locally-hosted AI models (Ollama, LM Studio)",
                icon: "desktopcomputer"
            )

            // Info banner
            HStack(spacing: AISSpacing.md) {
                Image(systemName: "info.circle")
                    .foregroundColor(tokens.stateInfo.color)
                Text("Local AI runs on your machine for privacy and offline use. Ensure your local AI server is running before testing.")
                    .font(.caption)
            }
            .padding()
            .background(tokens.stateInfo.color.opacity(0.1))
            .cornerRadius(AISRadius.md)

            ForEach($localProviders) { $config in
                localProviderCard(config: $config)
            }
        }
    }

    private func localProviderCard(config: Binding<LocalAIConfig>) -> some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            // Header row
            HStack {
                Image(systemName: config.wrappedValue.provider.iconName)
                    .font(.title2)
                    .foregroundColor(tokens.actionPrimary.color)
                    .frame(width: 40, height: 40)
                    .background(tokens.actionPrimary.color.opacity(0.1))
                    .cornerRadius(AISRadius.md)

                VStack(alignment: .leading, spacing: 2) {
                    Text(config.wrappedValue.provider.rawValue)
                        .font(.headline)
                    Text(config.wrappedValue.isEnabled ? "Enabled" : "Disabled")
                        .font(.caption)
                        .foregroundColor(config.wrappedValue.isEnabled ? tokens.actionConfirm.color : tokens.onSurfaceSecondary)
                }

                Spacer()

                Toggle("", isOn: config.isEnabled)
                    .labelsHidden()
                    .onChange(of: config.wrappedValue.isEnabled) { _, _ in hasChanges = true }
            }

            if config.wrappedValue.isEnabled {
                Divider()

                // Endpoint field
                VStack(alignment: .leading, spacing: AISSpacing.xs) {
                    Text("API Endpoint")
                        .font(.caption)
                        .foregroundColor(tokens.onSurfaceSecondary)
                    TextField("http://localhost:11434", text: config.endpoint)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: config.wrappedValue.endpoint) { _, _ in hasChanges = true }
                }

                // Model field
                VStack(alignment: .leading, spacing: AISSpacing.xs) {
                    Text("Model Name")
                        .font(.caption)
                        .foregroundColor(tokens.onSurfaceSecondary)
                    TextField("llama3.2", text: config.model)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: config.wrappedValue.model) { _, _ in hasChanges = true }
                }

                // Test button and result
                VStack(alignment: .trailing, spacing: AISSpacing.sm) {
                    HStack {
                        Spacer()
                        Button(action: { testLocalConnection(config.wrappedValue) }) {
                            HStack(spacing: AISSpacing.xs) {
                                if testingConnectionFor == config.wrappedValue.provider.rawValue {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "network")
                                }
                                Text("Test Connection")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(testingConnectionFor != nil)
                    }

                    // Show result for this provider
                    if let result = connectionTestResult, result.provider == config.wrappedValue.provider.rawValue {
                        HStack(spacing: AISSpacing.xs) {
                            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.success ? .green : .red)
                            Text(result.message)
                                .font(.caption)
                                .foregroundColor(result.success ? .green : .red)
                        }
                        .padding(AISSpacing.sm)
                        .frame(maxWidth: .infinity)
                        .background(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(AISRadius.sm)
                    }
                }
            }
        }
        .padding()
        .background(tokens.surface)
        .cornerRadius(AISRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AISRadius.lg)
                .stroke(tokens.onSurface.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - On-Device Tab

    private var onDeviceTab: some View {
        VStack(alignment: .leading, spacing: AISSpacing.lg) {
            sectionHeader(
                title: "On-Device AI",
                subtitle: "Configure built-in OCR and vision capabilities",
                icon: "iphone"
            )

            // Apple Vision toggle
            Toggle(isOn: $onDeviceConfig.useAppleVision) {
                HStack(spacing: AISSpacing.md) {
                    Image(systemName: "apple.logo")
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(AISRadius.md)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Vision")
                            .font(.headline)
                        Text("On-device text recognition (macOS/iOS)")
                            .font(.caption)
                            .foregroundColor(tokens.onSurfaceSecondary)
                    }
                }
            }
            .toggleStyle(.switch)
            .padding()
            .background(tokens.surface)
            .cornerRadius(AISRadius.lg)
            .onChange(of: onDeviceConfig.useAppleVision) { _, _ in hasChanges = true }

            // Language selector
            sectionHeader(
                title: "Language",
                subtitle: "Preferred language for OCR recognition",
                icon: "globe"
            )

            Picker("Recognition Language", selection: $onDeviceConfig.preferredLanguage) {
                Text("English").tag("en")
                Text("Chinese").tag("zh")
                Text("Japanese").tag("ja")
                Text("Korean").tag("ko")
                Text("Spanish").tag("es")
                Text("French").tag("fr")
                Text("German").tag("de")
            }
            .pickerStyle(.menu)
            .padding()
            .background(tokens.surface)
            .cornerRadius(AISRadius.lg)
            .onChange(of: onDeviceConfig.preferredLanguage) { _, _ in hasChanges = true }

            // Fallback settings
            sectionHeader(
                title: "Fallback Behavior",
                subtitle: "How to handle extraction failures",
                icon: "arrow.triangle.2.circlepath"
            )

            Toggle(isOn: $enableFallback) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable Automatic Fallback")
                        .font(.headline)
                    Text("Automatically try next provider if current one fails")
                        .font(.caption)
                        .foregroundColor(tokens.onSurfaceSecondary)
                }
            }
            .toggleStyle(.switch)
            .padding()
            .background(tokens.surface)
            .cornerRadius(AISRadius.lg)
            .onChange(of: enableFallback) { _, _ in hasChanges = true }
        }
    }

    // MARK: - Preferred Tier Selector

    private var preferredTierSelector: some View {
        VStack(alignment: .leading, spacing: AISSpacing.md) {
            sectionHeader(
                title: "Preferred Processing Tier",
                subtitle: "Choose which AI tier to use first",
                icon: "list.number"
            )

            VStack(spacing: AISSpacing.sm) {
                ForEach(PreferredTier.allCases) { tier in
                    Button(action: { preferredTier = tier; hasChanges = true }) {
                        HStack(spacing: AISSpacing.md) {
                            Image(systemName: preferredTier == tier ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(preferredTier == tier ? tokens.actionPrimary.color : tokens.onSurfaceSecondary)

                            Image(systemName: tier.iconName)
                                .foregroundColor(tokens.actionPrimary.color)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(tier.rawValue)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(tokens.onSurface)
                                Text(tier.description)
                                    .font(.caption)
                                    .foregroundColor(tokens.onSurfaceSecondary)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(preferredTier == tier ? tokens.actionPrimary.color.opacity(0.1) : tokens.surface)
                        .cornerRadius(AISRadius.md)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundColor(tokens.onSurfaceSecondary)
            Text("~/Library/Application Support/AIS/ai_settings.json")
                .font(.caption.monospaced())
                .foregroundColor(tokens.onSurfaceSecondary)

            Spacer()

            Button(action: {}) {
                Label("Export/Import", systemImage: "square.and.arrow.up.on.square")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(tokens.surfaceSecondary)
        .cornerRadius(AISRadius.md)
    }

    // MARK: - Helper Views

    private func sectionHeader(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: AISSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(tokens.actionPrimary.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(tokens.onSurfaceSecondary)
            }
        }
    }

    // MARK: - Actions

    private func saveSettings() {
        // In a real app, save to UserDefaults or file
        hasChanges = false
        showingSaveAlert = true
    }

    private func resetSettings() {
        cloudProviders = CloudLLMProvider.allCases.map { CloudLLMConfig(provider: $0) }
        localProviders = LocalAIProvider.allCases.map { LocalAIConfig(provider: $0) }
        onDeviceConfig = OnDeviceAIConfig()
        preferredTier = .onDevice
        enableFallback = true
        hasChanges = false
    }

    private func testCloudConnection(_ config: CloudLLMConfig) {
        let providerName = config.provider.rawValue
        testingConnectionFor = providerName
        connectionTestResult = nil

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

            await MainActor.run {
                testingConnectionFor = nil

                if config.apiKey.isEmpty {
                    connectionTestResult = (providerName, false, "No API key configured")
                    return
                }

                // Validate API key format
                var isValid = false
                var message = ""

                switch config.provider {
                case .claude:
                    isValid = config.apiKey.hasPrefix("sk-ant-")
                    message = isValid ? "API key format valid. Ready to use." : "API key should start with 'sk-ant-'"
                case .chatgpt:
                    isValid = config.apiKey.hasPrefix("sk-")
                    message = isValid ? "API key format valid. Ready to use." : "API key should start with 'sk-'"
                case .gemini:
                    isValid = config.apiKey.count > 20
                    message = isValid ? "API key format valid. Ready to use." : "API key appears too short"
                }

                connectionTestResult = (providerName, isValid, message)
            }
        }
    }

    private func testLocalConnection(_ config: LocalAIConfig) {
        let providerName = config.provider.rawValue
        testingConnectionFor = providerName
        connectionTestResult = nil

        Task {
            let success = await testEndpoint(config.endpoint)

            await MainActor.run {
                testingConnectionFor = nil

                if success {
                    connectionTestResult = (providerName, true, "\(providerName) is running at \(config.endpoint)")
                } else {
                    connectionTestResult = (providerName, false, "Could not connect to \(config.endpoint). Make sure \(providerName) is running.")
                }
            }
        }
    }

    private func testEndpoint(_ urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else { return false }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 5.0

            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode < 500
            }
            return false
        } catch {
            return false
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AISettingsDemoScreen()
    }
    .environment(\.aisTokens, AISTokenSet.light)
}
