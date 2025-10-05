import SwiftUI

@main
struct AmanpayApp: App {
    @StateObject private var session = SessionManager()
    @StateObject private var lock = AppLockManager()   // ✅

    var body: some Scene {
        WindowGroup {
            RootRouter()
                .environmentObject(session)
                .environmentObject(lock)               // ✅ add this line
                .preferredColorScheme(.light)
        }
    }
}
