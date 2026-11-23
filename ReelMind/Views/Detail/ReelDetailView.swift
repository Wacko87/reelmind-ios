import SwiftUI

public struct ReelDetailView: View {
    @State public var viewModel: ReelDetailViewModel

    public init(reel: Reel) {
        self._viewModel = State(initialValue: ReelDetailViewModel(reel: reel))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header: Title, Platform, Duration & Difficulty
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(viewModel.reel.platform.capitalized)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.12))
                            .foregroundColor(.accentColor)
                            .clipShape(Capsule())

                        if let author = viewModel.reel.author {
                            Text("@\(author)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Picker("Status", selection: Binding(
                            get: { viewModel.reel.status },
                            set: { newStatus in
                                Task {
                                    await viewModel.updateStatus(to: newStatus)
                                }
                            }
                        )) {
                            Text("Pending").tag("pending")
                            Text("Tested").tag("tested")
                            Text("Favorite").tag("favorite")
                        }
                        .pickerStyle(.menu)
                    }

                    Text(viewModel.reel.title)
                        .font(.title2.bold())
                        .foregroundColor(.primary)

                    if let url = URL(string: viewModel.reel.url) {
                        Link(destination: url) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.right.square")
                                Text("Open original video")
                            }
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Summary
                VStack(alignment: .leading, spacing: 8) {
                    Label("Executive Summary", systemImage: "text.alignleft")
                        .font(.headline)
                    Text(viewModel.reel.summary)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 16)

                // AI Tools
                if !viewModel.reel.aiTools.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Mentioned AI Tools", systemImage: "wrench.and.screwdriver")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.reel.aiTools, id: \.self) { tool in
                                Text(tool)
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor.opacity(0.12))
                                    .foregroundColor(.accentColor)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)
                }

                // Steps
                if !viewModel.reel.keySteps.isEmpty {
                    StepsSectionView(steps: viewModel.reel.keySteps)
                        .padding(.horizontal, 16)
                }

                // Prompts
                if !viewModel.reel.prompts.isEmpty {
                    PromptsSectionView(prompts: viewModel.reel.prompts) { text in
                        viewModel.copyToClipboard(text: text)
                    }
                    .padding(.horizontal, 16)
                }

                // User Notes Editor
                VStack(alignment: .leading, spacing: 8) {
                    Label("Personal Notes & Learnings", systemImage: "note.text")
                        .font(.headline)

                    TextEditor(text: $viewModel.userNotes)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Button {
                        Task {
                            await viewModel.saveNotes()
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Save Notes")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Reel Breakdown")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Copied to Clipboard", isPresented: $viewModel.showCopiedAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}

// Simple FlowLayout for tags and tools
public struct FlowLayout: Layout {
    public var spacing: CGFloat

    public init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
        height = currentY + lineHeight
        return CGSize(width: width, height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
    }
}
