import SwiftUI

public struct PromptStudioView: View {
    @State public var viewModel = PromptVaultViewModel()

    public init() {}

    private let availableModels = [
        "Midjourney v6.1",
        "Flux 1.1 Pro",
        "DALL-E 3",
        "Claude / ChatGPT",
        "Stable Diffusion XL"
    ]

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Original Prompt", systemImage: "pencil.line")
                            .font(.headline)

                        TextEditor(text: $viewModel.promptInput)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))

                        HStack {
                            Text("Target Model:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Picker("Model", selection: $viewModel.targetModel) {
                                ForEach(availableModels, id: \.self) { model in
                                    Text(model).tag(model)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        Button {
                            Task {
                                await viewModel.optimize()
                            }
                        } label: {
                            HStack {
                                if viewModel.isOptimizing {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Generating Variations...")
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("Optimize with Gemini")
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(viewModel.promptInput.isEmpty || viewModel.isOptimizing ? Color.gray : Color.accentColor)
                            .clipShape(.rect(cornerRadius: 12))
                        }
                        .disabled(viewModel.promptInput.isEmpty || viewModel.isOptimizing)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 16))
                    .padding(.horizontal, 16)

                    // Results
                    if !viewModel.variations.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Generated Variations")
                                .font(.title3.bold())
                                .padding(.horizontal, 16)

                            ForEach(viewModel.variations) { variation in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(variation.label)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(Color.accentColor)
                                        Spacer()
                                        Button {
                                            viewModel.copyPrompt(variation.prompt)
                                        } label: {
                                            Label("Copy", systemImage: "doc.on.doc")
                                                .font(.caption)
                                        }
                                        .accessibilityLabel("Copy variation \(variation.label)")
                                    }

                                    Text(variation.prompt)
                                        .font(.system(.subheadline, design: .monospaced))
                                        .padding(10)
                                        .background(Color(.tertiarySystemGroupedBackground))
                                        .clipShape(.rect(cornerRadius: 8))

                                    if let explanation = variation.explanation {
                                        Text(explanation)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(16)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(.rect(cornerRadius: 14))
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Prompt Studio")
            .sensoryFeedback(.success, trigger: viewModel.copyAlert)
            .alert("Prompt Copied!", isPresented: $viewModel.copyAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
}
