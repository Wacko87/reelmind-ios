import SwiftUI

public struct DashboardView: View {
    @State public var viewModel = ReelListViewModel()
    @State private var showingIngestionSheet = false

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Folder Filter Bar
                FolderFilterBar(
                    folders: viewModel.folders,
                    selectedFolderId: $viewModel.selectedFolderId
                )
                .padding(.top, 4)

                // Tool Filter Bar (if available)
                if !viewModel.availableTools.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            Button {
                                viewModel.selectedTool = nil
                            } label: {
                                Text("All Tools")
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(viewModel.selectedTool == nil ? Color(.label) : Color(.tertiarySystemFill))
                                    .foregroundStyle(viewModel.selectedTool == nil ? Color(.systemBackground) : .primary)
                                    .clipShape(Capsule())
                            }
                            .accessibilityLabel("Show all AI tools")

                            ForEach(viewModel.availableTools, id: \.self) { tool in
                                Button {
                                    viewModel.selectedTool = (viewModel.selectedTool == tool) ? nil : tool
                                } label: {
                                    Text(tool)
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(viewModel.selectedTool == tool ? Color.accentColor : Color(.tertiarySystemFill))
                                        .foregroundStyle(viewModel.selectedTool == tool ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .accessibilityLabel("Filter by tool \(tool)")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    }
                }

                // Main Content List
                if viewModel.isLoading && viewModel.reels.isEmpty {
                    Spacer()
                    ProgressView("Loading ReelMind Vault...")
                        .font(.subheadline)
                    Spacer()
                } else if viewModel.filteredReels.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No Reels in this view")
                            .font(.headline)
                        Text("Tap + to ingest a reel or video from Instagram, TikTok or YouTube.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.filteredReels) { reel in
                            NavigationLink(value: reel) {
                                ReelCardView(reel: reel) {
                                    Task {
                                        await viewModel.toggleFavorite(for: reel)
                                    }
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteReel(id: reel.id)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.loadData()
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("ReelMind")
            .navigationDestination(for: Reel.self) { reel in
                ReelDetailView(reel: reel)
            }
            .searchable(text: $viewModel.searchQuery, prompt: "Search reels, tools, prompts...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingIngestionSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                    }
                    .accessibilityLabel("Add new reel to vault")
                }
            }
            .sheet(isPresented: $showingIngestionSheet) {
                IngestionSheetView {
                    Task {
                        await viewModel.loadData()
                    }
                }
            }
            .task {
                await viewModel.loadData()
            }
        }
    }
}
