import SwiftUI

public struct AskVaultView: View {
    @State public var viewModel = PromptVaultViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Ask your AI Vault", systemImage: "brain.head.profile")
                            .font(.headline)

                        Text("Ask any question about the tricks, prompts, or tools saved across your collection:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("e.g. Which tool creates cinematic 3D avatars?", text: $viewModel.questionInput)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))

                        Button {
                            Task {
                                await viewModel.askVault()
                            }
                        } label: {
                            HStack {
                                if viewModel.isAsking {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Searching & Reasoning...")
                                } else {
                                    Image(systemName: "magnifyingglass")
                                    Text("Ask Vault")
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(viewModel.questionInput.isEmpty || viewModel.isAsking ? Color.gray : Color.accentColor)
                            .clipShape(.rect(cornerRadius: 12))
                        }
                        .disabled(viewModel.questionInput.isEmpty || viewModel.isAsking)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 16))
                    .padding(.horizontal, 16)

                    // Answer
                    if let answer = viewModel.vaultAnswer {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Synthesized Answer", systemImage: "lightbulb.fill")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text(answer)
                                .font(.body)
                                .foregroundStyle(.primary)

                            if !viewModel.citations.isEmpty {
                                Divider()
                                Text("Citations & Sources:")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)

                                ForEach(viewModel.citations) { citation in
                                    HStack {
                                        Text(citation.platform.capitalized)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.12))
                                            .foregroundStyle(Color.accentColor)
                                            .clipShape(Capsule())
                                        Text(citation.title)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 16))
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Ask Vault")
        }
    }
}
