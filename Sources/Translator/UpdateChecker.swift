import Foundation

struct UpdateCheckResult {
    let message: String
}

enum UpdateChecker {
    static func check() async -> UpdateCheckResult {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "TranslatorLatestReleaseURL") as? String,
              !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let url = URL(string: urlString) else {
            return UpdateCheckResult(message: "Проверка обновлений не настроена: укажите TranslatorLatestReleaseURL в Info.plist.")
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return UpdateCheckResult(message: "Не удалось проверить обновления: сервер не ответил успешно.")
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
            let latestVersion = release.normalizedTag

            if latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                return UpdateCheckResult(message: "Доступна версия \(release.tagName). Откройте страницу релизов на GitHub и скачайте новый билд.")
            }

            return UpdateCheckResult(message: "Установлена актуальная версия \(currentVersion).")
        } catch {
            return UpdateCheckResult(message: "Не удалось проверить обновления: \(error.localizedDescription)")
        }
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
    }

    var normalizedTag: String {
        tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
    }
}
