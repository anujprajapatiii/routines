import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: RoutineStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
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
                } header: {
                    Text("GitHub Repository")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }

                Section {
                    SecureField("Personal access token (optional)", text: $store.settings.accessToken)
                        .textInputAutocapitalization(.never)
                    Text("Required for private repos. Create at GitHub → Settings → Developer settings → Personal access tokens.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                } header: {
                    Text("Authentication")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }

                Section {
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
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Sync")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }

                Section {
                    Toggle("Haptic feedback", isOn: $store.settings.hapticsEnabled)
                } header: {
                    Text("Preferences")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }

                Section {
                    Text("\(store.routines.count) routine(s) loaded")
                        .font(.subheadline)
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
