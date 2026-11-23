import SwiftUI

public struct MainTabView: View {
    public init() {}

    public var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Vault", systemImage: "square.grid.2x2.fill")
                }

            PromptStudioView()
                .tabItem {
                    Label("Studio", systemImage: "sparkles")
                }

            AskVaultView()
                .tabItem {
                    Label("Ask AI", systemImage: "brain.head.profile")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(.accentColor)
    }
}
