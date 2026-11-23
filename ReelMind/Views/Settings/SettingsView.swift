import SwiftUI

public struct SettingsView: View {
    @State public var viewModel = SettingsViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("ReelMind Server Configuration")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Server URL")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        TextField("https://reelmind.wacko87.es", text: $viewModel.serverURL)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Access PIN / Bearer Token")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        SecureField("Optional if local or configured in Unraid", text: $viewModel.apiToken)
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
                            Text("Test Connection")
                        }
                    }

                    if let message = viewModel.statusMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundColor(viewModel.connectionSuccess == true ? .green : .red)
                    }
                }

                Section(header: Text("About ReelMind iOS")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Native SwiftUI)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Architecture")
                        Spacer()
                        Text("MVVM + Swift 6 Concurrency")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Homelab Target")
                        Spacer()
                        Text("Unraid 7.3.1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
