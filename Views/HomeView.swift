import SwiftUI

struct HomeView: View {
    var body: some View {
        HomeTabView()
    }
}

#Preview {
    HomeView()
        .environmentObject(SessionManager())
        .preferredColorScheme(.light)
}

