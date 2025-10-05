import Foundation

enum APIError: Error {
    case invalidURL
    case badStatus(Int, String?)
    case decode
    case transport(Error)
}

struct APIClient {
    static let shared = APIClient()
    private init() {}

    private let base = AppConfig.apiBase   // <— HTTPS domen

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = true
        cfg.timeoutIntervalForRequest = 30
        cfg.timeoutIntervalForResource = 60
        return URLSession(configuration: cfg)
    }()

    func login(phone: String, password: String) async throws -> LoginSuccess {
        try await post("/api/auth/login/", body: LoginRequest(phone_number: phone, password: password))
    }

    func register(phone: String, first: String, last: String, password: String) async throws -> LoginSuccess {
        let req = RegisterRequest(phone_number: phone, first_name: first, last_name: last, password: password)
        return try await post("/api/auth/register/", body: req)
    }

    private func post<TReq: Encodable, TResp: Decodable>(_ path: String, body: TReq) async throws -> TResp {
        guard let url = URL(string: path, relativeTo: base) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let dataBody = try JSONEncoder().encode(body)
        req.httpBody = dataBody

        #if DEBUG
        debugLogRequest(req, body: dataBody)
        #endif

        do {
            let (data, resp) = try await session.data(for: req)
            #if DEBUG
            debugLogResponse(data: data, response: resp, error: nil)
            #endif

            guard let http = resp as? HTTPURLResponse else { throw APIError.transport(NSError(domain: "noresp", code: -1)) }
            if (200..<300).contains(http.statusCode) {
                return try JSONDecoder().decode(TResp.self, from: data)
            } else {
                let serverDetail = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.detail
                throw APIError.badStatus(http.statusCode, serverDetail)
            }
        } catch {
            #if DEBUG
            debugLogResponse(data: nil, response: nil, error: error)
            #endif
            if let e = error as? APIError { throw e }
            throw APIError.transport(error)
        }
    }
}

#if DEBUG
private func debugLogRequest(_ req: URLRequest, body: Data?) {
    print("➡️ \(req.httpMethod ?? "") \(req.url?.absoluteString ?? "")")
    if let body = body { print("Body:", String(data: body, encoding: .utf8) ?? "\(body.count) bytes") }
}
private func debugLogResponse(data: Data?, response: URLResponse?, error: Error?) {
    if let http = response as? HTTPURLResponse { print("⬅️ \(http.statusCode) \(http.url?.absoluteString ?? "")") }
    if let data = data, !data.isEmpty { print("Body:", String(data: data, encoding: .utf8) ?? "") }
    if let error = error { print("❌", error.localizedDescription) }
}
#endif
