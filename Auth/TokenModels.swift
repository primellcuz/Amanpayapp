import Foundation

struct TokenPair: Codable {
    let access: String
    let refresh: String
}

struct RefreshRequest: Codable { let refresh: String }
struct RefreshResponse: Codable { let access: String }
