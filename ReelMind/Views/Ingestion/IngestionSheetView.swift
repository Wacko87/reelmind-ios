import SwiftUI

public struct IngestionSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State public var viewModel = IngestionViewModel()
    public let onCompleted: () -> Void

    public init(onCompleted: @escaping () -> Void) {
        self.onCompleted = onCompleted
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles.rectangle.stack")
                            .font(.system(size: 40))
                            .foregroundColor(.accentColor)
                        Text("Add Video / Reel to Vault")
                            .font(.title3.bold())
                        Text("Paste a link from Instagram, TikTok, YouTube Shorts or X to extract prompts, tools and steps with Gemini.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.top, 16)

                    // URL Input field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("URL of video or infographic")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.secondary)
                            TextField("https://www.instagram.com/reel/...", text: $viewModel.urlInput)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .keyboardType(.URL)

                            if !viewModel.urlInput.isEmpty {
                                Button {
                                    viewModel.urlInput = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 16)

                    // Paste from clipboard button
                    Button {
                        if let clipboard = UIPasteboard.general.string {
                            viewModel.urlInput = clipboard
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.clipboard")
                            Text("Paste from Clipboard")
                        }
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.accentColor)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                    }

                    // Action Button
                    Button {
                        Task {
                            let success = await viewModel.analyze()
                            if success {
                                onCompleted()
                                dismiss()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isAnalyzing {
                                ProgressView()
                                    .tint(.white)
                                Text("Analyzing with Gemini...")
                            } else {
                                Image(systemName: "wand.and.stars")
                                Text("Analyze & Extract Knowledge")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(viewModel.urlInput.isEmpty || viewModel.isAnalyzing ? Color.gray : Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(viewModel.urlInput.isEmpty || viewModel.isAnalyzing)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Ingest Reel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
