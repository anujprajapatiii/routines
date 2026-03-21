import Foundation

struct GitSyncService {
    struct GitHubFile: Decodable {
        let name: String
        let type: String
        let download_url: String?
    }

    /// Fetch all .md files from a GitHub repo directory
    func fetchMarkdownFiles(
        owner: String,
        repo: String,
        path: String,
        token: String?
    ) async throws -> [(name: String, content: String)] {
        // List directory contents
        var urlString = "https://api.github.com/repos/\(owner)/\(repo)/contents"
        if !path.isEmpty {
            urlString += "/\(path)"
        }

        guard let url = URL(string: urlString) else {
            throw SyncError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SyncError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw SyncError.repoNotFound
            } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw SyncError.unauthorized
            }
            throw SyncError.httpError(httpResponse.statusCode)
        }

        let files = try JSONDecoder().decode([GitHubFile].self, from: data)
        let mdFiles = files.filter { $0.type == "file" && $0.name.hasSuffix(".md") }

        // Download each .md file
        var results: [(String, String)] = []
        for file in mdFiles {
            guard let downloadURL = file.download_url,
                  let url = URL(string: downloadURL) else { continue }

            var fileRequest = URLRequest(url: url)
            if let token = token {
                fileRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            let (fileData, _) = try await URLSession.shared.data(for: fileRequest)
            if let content = String(data: fileData, encoding: .utf8) {
                results.append((file.name, content))
            }
        }

        return results
    }

    enum SyncError: LocalizedError {
        case invalidURL
        case networkError
        case repoNotFound
        case unauthorized
        case httpError(Int)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid repository URL."
            case .networkError: return "Network error. Check your connection."
            case .repoNotFound: return "Repository not found. Check owner/repo name."
            case .unauthorized: return "Unauthorized. Check your access token."
            case .httpError(let code): return "HTTP error \(code)."
            }
        }
    }
}
