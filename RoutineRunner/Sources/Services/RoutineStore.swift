import Foundation
import SwiftUI

@MainActor
final class RoutineStore: ObservableObject {
    @Published var routines: [Routine] = []
    @Published var isSyncing = false
    @Published var lastSyncError: String?

    @Published var settings = AppSettings()
    private let syncService = GitSyncService()

    private var routinesDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Routines")
    }

    init() {
        ensureDirectoryExists()
        loadRoutines()
    }

    func loadRoutines() {
        let fileManager = FileManager.default
        ensureDirectoryExists()

        guard let files = try? fileManager.contentsOfDirectory(
            at: routinesDirectory,
            includingPropertiesForKeys: nil
        ) else {
            routines = []
            return
        }

        routines = files
            .filter { $0.pathExtension == "md" }
            .compactMap { url -> Routine? in
                guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
                return MarkdownParser.parse(content, fileName: url.lastPathComponent)
            }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func sync(historyStore: RoutineHistoryStore? = nil) async {
        guard settings.isConfigured else {
            lastSyncError = "Configure your GitHub repo in Settings first."
            return
        }

        isSyncing = true
        lastSyncError = nil

        do {
            let files = try await syncService.fetchMarkdownFiles(
                owner: settings.repoOwner,
                repo: settings.repoName,
                path: settings.subfolderPath,
                branch: settings.branch,
                token: settings.accessToken.isEmpty ? nil : settings.accessToken
            )

            // Clear old files and write new ones
            let fileManager = FileManager.default
            if let existing = try? fileManager.contentsOfDirectory(at: routinesDirectory, includingPropertiesForKeys: nil) {
                for file in existing where file.pathExtension == "md" {
                    try? fileManager.removeItem(at: file)
                }
            }

            for (name, content) in files {
                let fileURL = routinesDirectory.appendingPathComponent(name)
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
            }

            loadRoutines()

            // Prune history for routines that were deleted from the repo
            if let historyStore {
                let activeFileNames = Set(routines.map(\.fileName))
                historyStore.pruneOrphanedRecords(keeping: activeFileNames)
            }
        } catch {
            lastSyncError = error.localizedDescription
        }

        isSyncing = false
    }

    private func ensureDirectoryExists() {
        try? FileManager.default.createDirectory(at: routinesDirectory, withIntermediateDirectories: true)
    }

    /// A pre-populated store for SwiftUI previews.
    static var preview: RoutineStore {
        let store = RoutineStore()
        store.routines = [
            Routine(title: "Morning Routine", steps: [
                Step(title: "Meditation", duration: 300, notes: [Note(text: "Focus on breathing")]),
                Step(title: "Stretching", duration: 600),
                Step(title: "Journaling", duration: 900, notes: [Note(text: "Write 3 gratitudes")]),
            ], fileName: "morning.md"),
            Routine(title: "Evening Wind-Down", steps: [
                Step(title: "Screen off", duration: 60),
                Step(title: "Reading", duration: 1200),
                Step(title: "Breathing exercise", duration: 300),
            ], fileName: "evening.md"),
        ]
        return store
    }
}
