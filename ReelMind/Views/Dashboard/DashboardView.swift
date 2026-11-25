import SwiftUI
import TipKit

public struct DashboardView: View {
    @State public var viewModel = ReelListViewModel()
    @State private var showingIngestionSheet = false
    @State private var showNewOrgAlert = false
    @State private var newOrgName = ""
    @State private var showInviteMemberAlert = false
    @State private var inviteUsername = ""
    private let shareTip = ShareExtensionTip()

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // TipKit Coach Mark for Share Extension
                TipView(shareTip)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                // Onboarding / AI Setup Banner if API key is missing
                if !GeminiService.shared.hasApiKey {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Activate Free Gemini AI")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                                Text("Tap here to add your free Gemini key in 1 click & analyze reels.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(.tertiary)
                        }
                        .padding(12)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(.rect(cornerRadius: 12))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }

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
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Section("Espacio de Trabajo") {
                            Button {
                                Task {
                                    await viewModel.switchOrganization(to: nil)
                                }
                            } label: {
                                HStack {
                                    Text("👤 Bóveda Personal")
                                    if viewModel.selectedOrganization == nil {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }

                        if !viewModel.organizations.isEmpty {
                            Section("Organizaciones") {
                                ForEach(viewModel.organizations) { org in
                                    Button {
                                        Task {
                                            await viewModel.switchOrganization(to: org)
                                        }
                                    } label: {
                                        HStack {
                                            Text("🏢 \(org.name)")
                                            if viewModel.selectedOrganization?.id == org.id {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if let currentOrg = viewModel.selectedOrganization {
                            Section("Equipo \(currentOrg.name)") {
                                Button {
                                    inviteUsername = ""
                                    showInviteMemberAlert = true
                                } label: {
                                    Label("Invitar Miembro (@usuario)...", systemImage: "person.badge.plus")
                                }
                            }
                        }

                        Section {
                            Button {
                                newOrgName = ""
                                showNewOrgAlert = true
                            } label: {
                                Label("Nueva Organización...", systemImage: "plus.rectangle.on.folder")
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: viewModel.selectedOrganization == nil ? "person.crop.circle" : "building.2.crop.circle")
                            Text(viewModel.selectedOrganization?.name ?? "Personal")
                                .font(.subheadline.weight(.semibold))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.secondarySystemFill))
                        .clipShape(Capsule())
                    }
                }

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
            .alert("Nueva Organización", isPresented: $showNewOrgAlert) {
                TextField("Nombre del equipo (ej: Equipo IA)", text: $newOrgName)
                Button("Crear") {
                    let name = newOrgName
                    Task {
                        await viewModel.createOrganization(name: name)
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Crea una organización para compartir una bóveda de trucos y herramientas con otros miembros.")
            }
            .alert("Invitar Miembro", isPresented: $showInviteMemberAlert) {
                TextField("Nombre de usuario (ej: carlos)", text: $inviteUsername)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Invitar") {
                    let user = inviteUsername
                    Task {
                        _ = await viewModel.inviteMember(username: user)
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Introduce el nombre del usuario registrado para darle acceso a esta bóveda.")
            }
            .sheet(isPresented: $showingIngestionSheet) {
                IngestionSheetView(orgId: viewModel.selectedOrganization?.id) {
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
