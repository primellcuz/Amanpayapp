import Foundation
import SwiftUI
import Combine

@MainActor
final class SessionManager: ObservableObject {
    enum Route { case splash, auth, home }
    @Published var route: Route = .splash
    @Published var currentUser: UserDTO?

    private let store = TokenStore.shared

    func bootstrap(minimumSeconds: Double = 3) async {
        guard route == .splash else { return }

        async let next = decideNextRoute()
        try? await Task.sleep(nanoseconds: UInt64(minimumSeconds * 1_000_000_000))
        let finalRoute = await next

        if finalRoute == .home {
            if let saved = TokenStore.shared.readUser() {
                currentUser = saved
            } else {
                await loadCurrentUserFromServer()
            }
        }
        withAnimation(.easeInOut(duration: 0.5)) {
            route = finalRoute
        }
    }

    private func decideNextRoute() async -> Route {
        if store.readAccess() != nil || store.readRefresh() != nil {
            return .home
        }
        return .auth
    }
    
    private func loadCurrentUserFromServer() async {
        do {
            let u = try await UserService.shared.me()
            currentUser = u
            TokenStore.shared.save(user: u)
        } catch {
            print("⚠️ Profilni yuklashda xato: \(error.localizedDescription)")
        }
    }


    // LOGIN: muvaffaqiyat -> tokenlarni saqlash, user set, HOME
    func login(phone: String, password: String) async -> String? {
        do {
            let res = try await APIClient.shared.login(phone: phone, password: password)
            TokenStore.shared.save(access: res.access, refresh: res.refresh)
            TokenStore.shared.save(user: res.user)        
            currentUser = res.user
            withAnimation(.easeInOut(duration: 0.4)) { route = .home }
            return nil
        } catch let APIError.badStatus(code, detail) {
            if code == 401 || code == 400 {
                return "Telefon raqam yoki parol noto‘g‘ri."
            }
            return detail ?? "Server xatosi (\(code)). Keyinroq urinib ko‘ring."
        } catch APIError.transport {
            return "Internet bilan ulanishda muammo. Iltimos, qayta urinib ko‘ring."
        } catch {
            return "Kutilmagan xatolik. Qayta urinib ko‘ring."
        }
    }
    func register(phone: String, first: String, last: String, password: String) async -> String? {
            do {
                let res = try await APIClient.shared.register(phone: phone, first: first, last: last, password: password)
                TokenStore.shared.save(access: res.access, refresh: res.refresh)
                TokenStore.shared.save(user: res.user)
                currentUser = res.user
                withAnimation(.easeInOut(duration: 0.4)) { route = .home }
                return nil
            } catch let APIError.badStatus(code, detail) {
                return detail ?? "Ro‘yxatdan o‘tishda xatolik (kod: \(code))."
            } catch APIError.transport {
                return "Internet bilan ulanishda muammo. Iltimos, qayta urinib ko‘ring."
            } catch {
                return "Kutilmagan xatolik. Qayta urinib ko‘ring."
            }
        }

    func logout() {
        TokenStore.shared.clear()
        TokenStore.shared.clearUser()
        currentUser = nil
        withAnimation(.easeInOut(duration: 0.3)) { route = .auth }
    }

}

