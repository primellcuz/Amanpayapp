import SwiftUI
import Foundation

struct HomeView: View {
    @EnvironmentObject private var session: SessionManager

    @State private var query: String = ""
    @State private var items: [ProductDTO] = []
    @State private var isLoading = false
    @State private var errorText: String?

    private let columns: [GridItem] = [
        .init(.flexible(), spacing: 14),
        .init(.flexible(), spacing: 14)
    ]
    private let baseURL = URL(string: "https://server.loadshub.com")!

    var body: some View {
        NavigationStack {
            ZStack {
                // Fon
                LinearGradient(colors: [Brand.bgTop, Brand.bgBottom],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        // MARK: Header
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "creditcard.fill")
                                Text("AmanPay")
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(Brand.primary)

                            Spacer()

                            if session.currentUser != nil {
                                Menu {
                                    Button("Chiqish") { session.logout() }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.title3)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // MARK: Qidiruv
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                            TextField("Mahsulot qidirish", text: $query)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                            if !query.isEmpty {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) { query = "" }
                                } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 16)

                        // Xatolik
                        if let err = errorText {
                            Text(err)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 16)
                        }

                        // MARK: Grid (Product kartalari)
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(items) { p in
                                ProductCardDTO(product: p, baseURL: baseURL)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)

                        if isLoading {
                            ProgressView().padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        // Birinchi ochilganda yuklash
        .task { await fetchProducts() }
        // Qidiruv o'zgarsa qayta yuklash (oddiy)
        .task(id: query) { await fetchProducts() }
    }

    private func fetchProducts() async {
        isLoading = true
        errorText = nil
        do {
            // Build URL: /api/products/?search=&ordering=-id
            var comp = URLComponents(url: baseURL.appendingPathComponent("/api/products/"),
                                     resolvingAgainstBaseURL: false)
            var q: [URLQueryItem] = []
            let s = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if !s.isEmpty { q.append(URLQueryItem(name: "search", value: s)) }
            q.append(URLQueryItem(name: "ordering", value: "-id"))
            comp?.queryItems = q

            guard let url = comp?.url else { throw URLError(.badURL) }
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            if let token = TokenStore.shared.readAccess() {
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            let decoded = try JSONDecoder().decode([ProductDTO].self, from: data)
            withAnimation { items = decoded }
        } catch {
            errorText = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Product karta (DTO uchun)
private struct ProductCardDTO: View {
    let product: ProductDTO
    let baseURL: URL

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Rasm
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemGray6))

                if let url = product.primaryImageURL(baseURL: baseURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFit()
                                .transition(.opacity)
                        case .empty:
                            ProgressView().scaleEffect(0.8)
                        case .failure(_):
                            Image(systemName: "photo")
                                .resizable().scaledToFit().padding(18)
                                .foregroundStyle(.secondary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding(8)
                } else {
                    Image(systemName: "photo")
                        .resizable().scaledToFit().padding(18)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 150)

            // Narx
            Text(product.priceSomText)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)

            // Sarlavha
            Text(product.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
    }
}

#Preview {
    HomeView()
        .environmentObject(SessionManager())
        .preferredColorScheme(.light)
}

