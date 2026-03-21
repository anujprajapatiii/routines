import Foundation
import SwiftUI

final class AppSettings: ObservableObject {
    @AppStorage("repoOwner") var repoOwner: String = ""
    @AppStorage("repoName") var repoName: String = ""
    @AppStorage("accessToken") var accessToken: String = ""
    @AppStorage("subfolderPath") var subfolderPath: String = ""
    @AppStorage("branch") var branch: String = ""
    @AppStorage("autoSyncOnLaunch") var autoSyncOnLaunch: Bool = true
    @AppStorage("isDarkMode") var isDarkMode: Bool = false

    var isConfigured: Bool {
        !repoOwner.isEmpty && !repoName.isEmpty
    }
}
