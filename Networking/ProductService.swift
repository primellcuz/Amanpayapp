import Foundation

// MARK: - Errors
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

// MARK: - Pagination model (DRF style)
private struct Page<T: Decodable>: Decodable {
    let count: Int?
    let next: String?
    let previous: String?
    let results: [T]
}

// MARK: - Service
final class ProductService {
    static let shared = ProductService()
    private init() {}

    // ✅ HTTPS domain
    private let baseURL = URL(string: "https://server.loadshub.com")!
    var base: URL { baseURL }

    // Custom URLSession with timeouts
    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = true
        cfg.timeoutIntervalForRequest = 30
        cfg.timeoutIntervalForResource = 60
        return URLSession(configuration: cfg)
    }()

    // MARK: - List products
    /// GET /api/products/?search=&ordering=&page=&page_size=
    func list(
        search: String? = nil,
        ordering: String? = nil,
        page: Int? = nil,
        pageSize: Int? = nil
    ) async throws -> [ProductDTO] {
        guard var comp = URLComponents(url: baseURL.appendingPathComponent("/api/products/"),
                                       resolvingAgainstBaseURL: false)
        else { throw ProductServiceError.invalidURL }

        var items: [URLQueryItem] = []
        if let s = search?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            items.append(.init(name: "search", value: s))
        }
        if let o = ordering?.trimmingCharacters(in: .whitespacesAndNewlines), !o.isEmpty {
            items.append(.init(name: "ordering", value: o))
        }
        if let p = page, p > 0 {
            items.append(.init(name: "page", value: String(p)))
        }
        if let ps = pageSize, ps > 0 {
            items.append(.init(name: "page_size", value: String(ps)))
        }
        if !items.isEmpty { comp.queryItems = items }

        guard let url = comp.url else { throw ProductServiceError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"

        // 🔐 Optional auth (agar kerak bo‘lsa)
        if let token = TokenStore.shared.readAccess() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw ProductServiceError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw ProductServiceError.http(http.statusCode, data) }

        // 🧠 Flexible decode: array yoki paginated
        do {
            if let arr = try? JSONDecoder().decode([ProductDTO].self, from: data) {
                return arr
            }
            let page = try JSONDecoder().decode(Page<ProductDTO>.self, from: data)
            return page.results
        } catch {
            throw ProductServiceError.decoding(error)
        }
    }

    // MARK: - Get single product
    /// GET /api/products/{id}/
    func get(id: Int) async throws -> ProductDTO {
        let url = baseURL.appendingPathComponent("/api/products/\(id)/")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        if let token = TokenStore.shared.readAccess() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ProductServiceError.invalidResponse
        }
        return try JSONDecoder().decode(ProductDTO.self, from: data)
    }
}
