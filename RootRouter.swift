import SwiftUI

struct RootRouter: View {
    @EnvironmentObject private var session: SessionManager
    @EnvironmentObject private var lock: AppLockManager

    var body: some View {
        ZStack {
            switch session.route {
            case .splash: SplashView()
            case .auth:   AuthFlowView()
            case .home:   MainTabView()
            }
            if lock.isLocked {                        // ✅ global overlay
                LockScreenView()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: lock.isLocked)
        .animation(.easeInOut(duration: 0.5), value: session.route)
    }
}
