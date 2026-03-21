import SwiftUI

@main
struct RoutineRunnerApp: App {
    @StateObject private var store = RoutineStore()
    @StateObject private var historyStore = RoutineHistoryStore()
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some Scene {
        WindowGroup {
            RoutineListView()
                .environmentObject(store)
                .environmentObject(historyStore)
                .preferredColorScheme(isDarkMode ? .dark : nil)
        }
    }
}
