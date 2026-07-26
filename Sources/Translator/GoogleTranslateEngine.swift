import Foundation

struct GoogleTranslation {
    let text: String
    /// Язык, который Google определил у исходного текста (при sl=auto).
    let detectedSource: String?
}

/// Онлайн-перевод через бесплатную неофициальную точку Google Translate.
/// Не требует ключей и регистрации, но нужен интернет.
/// Текст уходит в теле POST-запроса — так помещаются длинные тексты.
struct GoogleTranslateEngine {
    enum EngineError: LocalizedError {
        case badURL
        case badResponse
        case httpStatus(Int)

        var errorDescription: String? {
            switch self {
            case .badURL: return "Не удалось сформировать запрос."
            case .badResponse: return "Сервис вернул неожиданный ответ."
            case .httpStatus(let code): return "Сервис ответил ошибкой HTTP \(code)."
            }
        }
    }

    func translate(_ text: String, from source: String, to target: String) async throws -> GoogleTranslation {
        var components = URLComponents(string: "https://translate.googleapis.com/translate_a/single")!
        components.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl", value: source),
            URLQueryItem(name: "tl", value: target),
            URLQueryItem(name: "dt", value: "t"),
        ]
        guard let url = components.url else { throw EngineError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        var body = URLComponents()
        body.queryItems = [URLQueryItem(name: "q", value: text)]
        request.httpBody = body.percentEncodedQuery?.data(using: .utf8)
        request.timeoutInterval = 8

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw EngineError.httpStatus(http.statusCode)
        }

        // Ответ — вложенный JSON-массив: [[["Привет","Hello",...], ...], null, "en", ...]
        let json = try JSONSerialization.jsonObject(with: data)
        guard let root = json as? [Any], let segments = root.first as? [Any] else {
            throw EngineError.badResponse
        }

        var result = ""
        for segment in segments {
            if let parts = segment as? [Any], let translated = parts.first as? String {
                result += translated
            }
        }
        guard !result.isEmpty else { throw EngineError.badResponse }

        let detected = root.count > 2 ? root[2] as? String : nil
        return GoogleTranslation(text: result, detectedSource: detected)
    }
}
