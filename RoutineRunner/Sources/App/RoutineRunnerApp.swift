import SwiftUI

@main
struct RoutineRunnerApp: App {
    @StateObject private var store = RoutineStore()
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some Scene {
        WindowGroup {
            RoutineListView()
                .environmentObject(store)
                .preferredColorScheme(isDarkMode ? .dark : nil)
        }
    }
}
