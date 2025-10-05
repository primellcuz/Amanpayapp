import Foundation

struct LoginRequest: Codable {
    let phone_number: String
    let password: String
}

struct RegisterRequest: Codable {
    let phone_number: String
    let first_name: String
    let last_name: String
    let password: String
}

struct LoginSuccess: Codable {
    let refresh: String
    let access: String
    let user: UserDTO
}

struct UserDTO: Codable, Identifiable {
    let id: Int
    let phone_number: String
    let first_name: String?
    let last_name: String?
    let email: String?
}

struct ErrorResponse: Codable { let detail: String }
