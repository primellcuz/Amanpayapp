import Foundation

final class UserService {
    static let shared = UserService()
    private init() {}

    private let base = AppConfig.apiBase   // https://server.loadshub.com

    /// Ko‘p backendlarda profil epilari turlicha bo‘ladi.
    /// Avval /api/auth/me/ ni sinab ko‘ramiz, bo‘lmasa /api/users/me/, keyin /api/auth/user/
    func me() async throws -> UserDTO {
        let candidates = ["/api/auth/me/", "/api/users/me/", "/api/auth/user/"]
        var lastError: Error?

        for path in candidates {
            do {
                guard let url = URL(string: path, relativeTo: base) else { continue }
                var req = URLRequest(url: url)
                req.httpMethod = "GET"
                req.setValue("application/json", forHTTPHeaderField: "Accept")
                if let token = TokenStore.shared.readAccess() {
                    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }

                let (data, resp) = try await URLSession.shared.data(for: req)
                guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    continue
                }
                return try JSONDecoder().decode(UserDTO.self, from: data)
            } catch {
                lastError = error
            }
        }
        throw lastError ?? NSError(domain: "UserService", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "Profilni olishning imkoni bo‘lmadi"])
    }
}
