import SwiftUI

struct RootRouter: View {
    @EnvironmentObject private var session: SessionManager
    @EnvironmentObject private var lock: AppLockManager
    
    var body: some View {
        Group {
            switch session.route {
            case .splash:
                SplashView()

            case .auth:
                AuthFlowView()

            case .home:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.5), value: session.route)
    }
}
