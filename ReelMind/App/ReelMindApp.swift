import SwiftUI
import TipKit

@main
struct ReelMindApp: App {
    init() {
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
