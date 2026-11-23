import SwiftUI

public struct SettingsView: View {
    @State public var viewModel = SettingsViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                // Section 1: AI Engine Configuration (Zero-Server / App Store Friendly)
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Google Gemini API Key")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)

                        SecureField("AIzaSy...", text: $viewModel.geminiApiKey)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onChange(of: viewModel.geminiApiKey) { _, _ in
                                viewModel.saveSettings()
                            }
                    }

                    if let url = URL(string: "https://aistudio.google.com/app/apikey") {
                        Link(destination: url) {
                            HStack(spacing: 6) {
                                Image(systemName: "key.fill")
                                Text("Get Free Gemini Key (1 click)")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.accentColor)
                        }
                    }

                    Picker("AI Model", selection: $viewModel.geminiModel) {
                        Text("Gemini 2.5 Flash (Recommended)").tag("gemini-2.5-flash")
                        Text("Gemini 2.5 Pro (Deep Reasoning)").tag("gemini-2.5-pro")
                    }
                    .onChange(of: viewModel.geminiModel) { _, _ in
                        viewModel.saveSettings()
                    }

                    Button {
                        Task {
                            await viewModel.testConnection()
                        }
                    } label: {
                        HStack {
                            if viewModel.isTesting {
                                ProgressView()
                                    .padding(.trailing, 4)
                            }
                            Text("Verify AI Engine")
                        }
                    }

                    if let message = viewModel.statusMessage {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.connectionSuccess == true ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            Text(message)
                        }
                        .font(.footnote)
                        .foregroundColor(viewModel.connectionSuccess == true ? .green : .red)
                    }
                } header: {
                    Text("AI Intelligence Engine")
                } footer: {
                    Text("ReelMind runs 100% locally on your iPhone using your private Gemini Key. Your data never touches any third-party server.")
                }

                // Section 2: Advanced Homelab Mode (Optional)
                Section(header: Text("Advanced Setup")) {
                    Toggle("Self-Hosted Server Mode", isOn: $viewModel.useServerMode)
                        .onChange(of: viewModel.useServerMode) { _, _ in
                            viewModel.saveSettings()
                        }

                    if viewModel.useServerMode {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Server URL")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            TextField("https://api.yourdomain.com", text: $viewModel.serverURL)
                                .keyboardType(.URL)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .onChange(of: viewModel.serverURL) { _, _ in
                                    viewModel.saveSettings()
                                }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Access PIN / Token")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            SecureField("Optional PIN", text: $viewModel.apiToken)
                                .onChange(of: viewModel.apiToken) { _, _ in
                                    viewModel.saveSettings()
                                }
                        }
                    }
                }

                // Section 3: About
                Section(header: Text("About ReelMind")) {
                    HStack {
                        Text("Mode")
                        Spacer()
                        Text(viewModel.useServerMode ? "Remote Server" : "Local Device (On-Device)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Architecture")
                        Spacer()
                        Text("Swift 6 + SwiftData")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Privacy")
                        Spacer()
                        Text("Zero Data Collection")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
