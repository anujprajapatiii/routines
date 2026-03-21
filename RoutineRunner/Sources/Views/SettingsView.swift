import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: RoutineStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("GitHub Repository") {
                    TextField("Owner (e.g. username)", text: $store.settings.repoOwner)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Repository name", text: $store.settings.repoName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Subfolder (optional)", text: $store.settings.subfolderPath)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Branch (optional)", text: $store.settings.branch)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Authentication") {
                    SecureField("Personal access token (optional)", text: $store.settings.accessToken)
                        .textInputAutocapitalization(.never)
                    Text("Required for private repos. Create at GitHub > Settings > Developer settings > Personal access tokens.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Sync") {
                    Toggle("Auto-sync on launch", isOn: $store.settings.autoSyncOnLaunch)

                    Button {
                        Task { await store.sync() }
                    } label: {
                        HStack {
                            Text("Sync Now")
                            Spacer()
                            if store.isSyncing {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(store.isSyncing || !store.settings.isConfigured)

                    if let error = store.lastSyncError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Preferences") {
                    Toggle("Haptic feedback", isOn: $store.settings.hapticsEnabled)
                }

                Section {
                    Text("\(store.routines.count) routine(s) loaded")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
