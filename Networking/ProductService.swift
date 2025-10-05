import Foundation

enum ProductServiceError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case http(Int, Data)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:       return "Noto‘g‘ri URL."
        case .invalidResponse:  return "Noto‘g‘ri server javobi."
        case .http(let c, _):   return "Server xatosi: \(c)."
        case .decoding:         return "Ma’lumotni o‘qishda xato."
        }
    }
}

final class ProductService {
    static let shared = ProductService()
    private init() {}

    // ✅ HTTPS domen
    private let baseURL = URL(string: "https://server.loadshub.com")!

    // Yaxshi time-out’lar bilan sessiya
    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = true
        cfg.timeoutIntervalForRequest = 30
        cfg.timeoutIntervalForResource = 60
        return URLSession(configuration: cfg)
    }()

    // JSON decoder (snake_case → camelCase, ISO8601 + fractional seconds)
    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { dec in
            let c = try dec.singleValueContainer()
            let s = try c.decode(String.self)
            let f1 = ISO8601DateFormatter()
            f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let dt = f1.date(from: s) { return dt }
            return ISO8601DateFormatter().date(from: s) ?? Date()
        }
        return d
    }

    /// GET /api/products/  →  [ProductDTO]
    func list() async throws -> [ProductDTO] {
        let url = baseURL.appendingPathComponent("/api/products/")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        // Agar endpoint auth talab qilsa, token yuborish (zarur bo‘lsa).
        if let token = TokenStore.shared.readAccess() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw ProductServiceError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            throw ProductServiceError.http(http.statusCode, data)
        }

        do { return try decoder.decode([ProductDTO].self, from: data) }
        catch { throw ProductServiceError.decoding(error) }
    }
}
