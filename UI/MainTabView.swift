import SwiftUI

struct MainTabView: View {
    @State private var selected = 0
    @State private var cartCount = 0
    @EnvironmentObject private var lock: AppLockManager
    
    var body: some View {
        TabView(selection: $selected) {
            HomeView()
                .tabItem { Label("Bosh sahifa", systemImage: "house.fill") }
                .tag(0)

            // ShopsTabView – alohida faylda
            ShopsTabView()
                .tabItem { Label("Do‘konlar", systemImage: "bag.fill") }
                .tag(1)

            CartTabView()
                .tabItem { Label("Savat", systemImage: "cart.fill") }
                .badge(cartCount)   // 0 bo‘lsa ko‘rinmaydi
                .tag(2)

            PaymentsTabView()
                .tabItem { Label("To‘lovlar", systemImage: "creditcard.fill") }
                .tag(3)

            ProfileTabView()
                .tabItem { Label("Profil", systemImage: "person.crop.circle.fill") }
        }
        .tint(Brand.primary)
    }
}

struct CartTabView: View { var body: some View { Text("Savat").padding() } }
struct PaymentsTabView: View { var body: some View { Text("To‘lovlar").padding() } }
