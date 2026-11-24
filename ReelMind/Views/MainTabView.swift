import SwiftUI

public struct MainTabView: View {
    @AppStorage("selectedTab") private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Vault", systemImage: "square.grid.2x2.fill")
                }
                .tag(0)

            PromptStudioView()
                .tabItem {
                    Label("Studio", systemImage: "sparkles")
                }
                .tag(1)

            AskVaultView()
                .tabItem {
                    Label("Ask AI", systemImage: "brain.head.profile")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.accentColor)
    }
}
