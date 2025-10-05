import SwiftUI

struct ShopsTabView: View {
    @State private var query = ""
    @State private var shops: [Shop] = Shop.mock

    private var filtered: [Shop] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return q.isEmpty ? shops : shops.filter { $0.name.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Brand.bgTop, Brand.bgBottom],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // MARK: Title
                        HStack {
                            Text("Do‘konlar")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(Brand.ink)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // MARK: Search
                        SearchBar(text: $query, placeholder: "Do‘kon qidirish")
                            .padding(.horizontal, 16)

                        // MARK: List of shops (cards)
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { shop in
                                NavigationLink {
                                    // TODO: Do‘kon ichki sahifasi
                                    Text(shop.name).padding()
                                } label: {
                                    ShopRow(shop: shop)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - UI Components
private struct SearchBar: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
            if !text.isEmpty {
                Button { withAnimation(.easeInOut(duration: 0.15)) { text = "" } } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ShopRow: View {
    let shop: Shop

    var body: some View {
        HStack(spacing: 12) {
            // Logo
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemGray6))
                if let url = shop.logoURL {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView().scaleEffect(0.8)
                    }
                    .padding(8)
                } else {
                    Image(systemName: shop.systemIcon ?? "bag.fill")
                        .resizable().scaledToFit()
                        .padding(10)
                        .foregroundStyle(Brand.primary)
                }
            }
            .frame(width: 44, height: 44)

            // Name + badge
            VStack(alignment: .leading, spacing: 6) {
                Text(shop.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .imageScale(.small)
                    Text("Halol nasiya")
                        .font(.footnote.weight(.semibold))
                }
                .foregroundStyle(Color.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.12))
                .clipShape(Capsule())
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
    }
}

// MARK: - Model
private struct Shop: Identifiable {
    let id = UUID()
    let name: String
    let systemIcon: String?
    let logoURL: URL?

    static let mock: [Shop] = [
        Shop(name: "Alif Shop",          systemIcon: "bag.fill",      logoURL: nil),
        Shop(name: "Texnika do‘konlari", systemIcon: "laptopcomputer", logoURL: nil),
        Shop(name: "Kiyim-kechak",       systemIcon: "tshirt.fill",    logoURL: nil),
        Shop(name: "Maishiy texnika",    systemIcon: "washer.fill",    logoURL: nil),
        Shop(name: "Avto bozor",         systemIcon: "car.fill",       logoURL: nil)
    ]
}

#Preview {
    ShopsTabView()
        .preferredColorScheme(.light)
        .environmentObject(SessionManager())
}
