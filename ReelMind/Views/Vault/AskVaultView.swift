import SwiftUI

public struct AskVaultView: View {
    @State public var viewModel = PromptVaultViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Vault Scope Selector (Personal vs Organization)
                    if !viewModel.organizations.isEmpty {
                        HStack {
                            Menu {
                                Button {
                                    viewModel.selectedOrganization = nil
                                } label: {
                                    HStack {
                                        Text("👤 Bóveda Personal")
                                        if viewModel.selectedOrganization == nil {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }

                                ForEach(viewModel.organizations) { org in
                                    Button {
                                        viewModel.selectedOrganization = org
                                    } label: {
                                        HStack {
                                            Text("🏢 \(org.name)")
                                            if viewModel.selectedOrganization?.id == org.id {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: viewModel.selectedOrganization == nil ? "person.crop.circle" : "building.2.crop.circle")
                                    Text(viewModel.selectedOrganization == nil ? "Ámbito: Bóveda Personal" : "Ámbito: \(viewModel.selectedOrganization!.name)")
                                        .font(.caption.bold())
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption2)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Capsule())
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }

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

                        if viewModel.questionInput.isEmpty {
                            Button {
                                viewModel.loadSampleQuestion()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "lightbulb")
                                    Text("💡 Probar pregunta de ejemplo")
                                }
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                            }
                            .padding(.top, 2)
                        }

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
                    } else if !viewModel.isAsking {
                        VStack(spacing: 8) {
                            Image(systemName: "sparkle.magnifyingglass")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)
                            Text("Tu asistente de conocimiento RAG")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            Text("Pregunta sobre cualquier truco o flujo de trabajo guardado para obtener una síntesis con fuentes citadas.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.top, 24)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Ask Vault")
            .task {
                await viewModel.loadOrganizations()
            }
        }
    }
}
