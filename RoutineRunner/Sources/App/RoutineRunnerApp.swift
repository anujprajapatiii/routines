import SwiftUI

@main
struct RoutineRunnerApp: App {
    @StateObject private var store = RoutineStore()

    var body: some Scene {
        WindowGroup {
            RoutineListView()
                .environmentObject(store)
        }
    }
}
