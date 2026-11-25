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
                            .foregroundStyle(.secondary)

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
                            .foregroundStyle(Color.accentColor)
                        }
                    }

                    Picker("AI Model", selection: $viewModel.geminiModel) {
                        Text("Gemini 3.5 Flash Lite (Recommended)").tag("gemini-3.5-flash-lite")
                        Text("Gemini 3.8 Flash (Balanced)").tag("gemini-3.8-flash")
                        Text("Gemini 3.1 Flash Lite").tag("gemini-3.1-flash-lite")
                        Text("Gemini 3.8 Pro (Deep Reasoning)").tag("gemini-3.8-pro")
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
                    .disabled(viewModel.isTesting)

                    if let message = viewModel.statusMessage {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.connectionSuccess == true ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            Text(message)
                        }
                        .font(.footnote)
                        .foregroundStyle(viewModel.connectionSuccess == true ? .green : .red)
                    }
                } header: {
                    Text("AI Intelligence Engine")
                } footer: {
                    Text("ReelMind runs 100% locally on your iPhone using your private Gemini Key. Your data never touches any third-party server.")
                }

                // Section 2: Advanced Homelab Mode (Optional)
                Section {
                    Toggle("Self-Hosted Server Mode", isOn: $viewModel.useServerMode)
                        .onChange(of: viewModel.useServerMode) { _, _ in
                            viewModel.saveSettings()
                        }

                    if viewModel.useServerMode {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Server URL")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            TextField("https://reels.wacko87.es", text: $viewModel.serverURL)
                                .keyboardType(.URL)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .onChange(of: viewModel.serverURL) { _, _ in
                                    viewModel.saveSettings()
                                }
                        }

                        Picker("Acceso al Servidor", selection: $viewModel.authMode) {
                            Text("Iniciar Sesión").tag(0)
                            Text("Crear Cuenta").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 4)

                        if viewModel.authMode == 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Access PIN / Token")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                SecureField("PIN personal (ej. 3004)", text: $viewModel.apiToken)
                                    .onChange(of: viewModel.apiToken) { _, _ in
                                        viewModel.saveSettings()
                                    }
                            }

                            Button {
                                Task {
                                    await viewModel.testServerConnection()
                                }
                            } label: {
                                HStack {
                                    if viewModel.isTestingServer {
                                        ProgressView()
                                            .padding(.trailing, 4)
                                    }
                                    Text("Verify Server Connection")
                                }
                            }
                            .disabled(viewModel.isTestingServer)
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Nombre de Usuario")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                TextField("ej. carlos", text: $viewModel.registerUsername)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("PIN de Acceso")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                SecureField("Mínimo 4 caracteres", text: $viewModel.registerPIN)
                            }

                            Button {
                                Task {
                                    await viewModel.registerAccount()
                                }
                            } label: {
                                HStack {
                                    if viewModel.isRegistering {
                                        ProgressView()
                                            .padding(.trailing, 4)
                                    }
                                    Text("Crear Cuenta e Iniciar Sesión")
                                }
                            }
                            .disabled(viewModel.isRegistering)
                        }

                        if let msg = viewModel.serverStatusMessage {
                            HStack(spacing: 6) {
                                Image(systemName: viewModel.serverConnectionSuccess == true ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                Text(msg)
                            }
                            .font(.footnote)
                            .foregroundStyle(viewModel.serverConnectionSuccess == true ? .green : .red)
                        }
                    }
                } header: {
                    Text("Advanced Setup")
                } footer: {
                    Text("Server mode connects to your Unraid instance (reels.wacko87.es), downloading the actual video with yt-dlp to extract text on screen (OCR), prompts, and audio with 100% fidelity.")
                }

                // Section 3: Security & Privacy
                Section {
                    Toggle("Lock with Face ID / Passcode", isOn: Binding(
                        get: { AppLockService.shared.isBiometricEnabled },
                        set: { AppLockService.shared.isBiometricEnabled = $0 }
                    ))

                    HStack {
                        Label("Keychain Protection", systemImage: "lock.shield.fill")
                        Spacer()
                        Text("Active (Secure Enclave)")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    HStack {
                        Label("Data Sandbox", systemImage: "iphone")
                        Spacer()
                        Text("On-Device Only")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Security & Privacy")
                } footer: {
                    Text("When enabled, ReelMind requires Face ID, Touch ID, or your device passcode every time the app is opened.")
                }

                // Section 4: Vault Data & Backups
                Section(header: Text("Vault Management")) {
                    Button {
                        Task {
                            await viewModel.prepareExport()
                        }
                    } label: {
                        Label("Export Vault as Markdown", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        viewModel.showRestoreConfirmation = true
                    } label: {
                        Label("Restore Sample Reels", systemImage: "arrow.counterclockwise")
                    }
                }

                // Section 4: About
                Section(header: Text("About ReelMind")) {
                    HStack {
                        Text("Mode")
                        Spacer()
                        Text(viewModel.useServerMode ? "Remote Server" : "Local Device (On-Device)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Architecture")
                        Spacer()
                        Text("Swift 6 + MVVM")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Privacy")
                        Spacer()
                        Text("Zero Data Collection")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $viewModel.showExportSheet) {
                NavigationStack {
                    ScrollView {
                        Text(viewModel.exportedMarkdown)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .navigationTitle("Vault Backup")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { viewModel.showExportSheet = false }
                        }
                        ToolbarItem(placement: .primaryAction) {
                            ShareLink(item: viewModel.exportedMarkdown) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                }
            }
            .confirmationDialog("Restore Initial Samples?", isPresented: $viewModel.showRestoreConfirmation, titleVisibility: .visible) {
                Button("Restore Samples", role: .destructive) {
                    Task {
                        await viewModel.restoreSampleVault()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reload the initial tutorial reels into your local vault.")
            }
        }
    }
}
