import SwiftUI
import TipKit

@main
struct ReelMindApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var lockService = AppLockService.shared

    init() {
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()

                if lockService.isLocked {
                    AppLockView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: lockService.isLocked)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    lockService.lock()
                }
            }
        }
    }
}
