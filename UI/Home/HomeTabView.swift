import SwiftUI

// MARK: - Home
struct HomeTabView: View {
    @State private var query = ""
    @State private var isLoading = true
    @State private var lastUpdated: Date?
    @State private var items: [UIProduct] = []

    private let columns: [GridItem] = [.init(.flexible(), spacing: 14),
                                       .init(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TopBrandBar()
                    SearchBar(text: $query)

                    // ⬇️ FIX: use classic optional binding
                    if let d = lastUpdated {
                        Text("Oxirgi yangilanish: \(d.formatted(date: .omitted, time: .shortened))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    LazyVGrid(columns: columns, spacing: 14) {
                        if isLoading && items.isEmpty {
                            ForEach(0..<6, id: \.self) { _ in ShimmerCard() }
                        } else {
                            ForEach(filtered(items)) { p in
                                ProductCard(product: p)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                }
            }
            .background(
                LinearGradient(colors: [Color(.systemGroupedBackground), .white],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            )
            .refreshable { await reload() }
            .navigationBarHidden(true)
            .task { if items.isEmpty { await reload() } }
        }
    }

    private func filtered(_ src: [UIProduct]) -> [UIProduct] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return q.isEmpty ? src : src.filter {
            $0.title.lowercased().contains(q) || $0.subtitle.lowercased().contains(q)
        }
    }

    private func reload() async {
        await MainActor.run { isLoading = true }
        do {
            let raw = try await ProductsAPI.fetch()
            print("✅ Products: HTTP OK, bytes=\(raw.data.count)")
            if let decoded = try? JSONDecoder().decode([ProductsAPI.APIProduct].self, from: raw.data),
               !decoded.isEmpty {
                print("✅ Decoded count =", decoded.count)
                let mapped = decoded.map(UIProduct.init)
                await MainActor.run {
                    self.items = mapped
                    self.lastUpdated = Date()
                    self.isLoading = false
                }
            } else {
                print("⛔️ JSON decode failed or empty — keep loading")
            }
        } catch {
            print("⛔️ Fetch error:", error.localizedDescription)
        }
    }
}

// MARK: - Networking (raw fetch)
fileprivate enum ProductsAPI {
    struct APIProduct: Decodable, Identifiable {
        let id: Int
        let seller_id: Int
        let title: String
        let description: String
        let price: String
        let stock: Int
        let is_active: Bool
        let banner_main: String?
        let banner_second: String?
        let banner_third: String?
        let banner_fourth: String?
        let created_at: String
    }

    struct Raw {
        let data: Data
        let status: Int
    }

    static func fetch() async throws -> Raw {
        let url = URL(string: "https://server.loadshub.com/api/products/")!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("AmanPay-iOS/1.0", forHTTPHeaderField: "User-Agent")

        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = true
        cfg.timeoutIntervalForRequest  = 15
        cfg.timeoutIntervalForResource = 30

        let (data, resp) = try await URLSession(configuration: cfg).data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        print("🔎 Products GET status=\(http.statusCode) bytes=\(data.count)")
        guard (200...299).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        return .init(data: data, status: http.statusCode)
    }
}

// MARK: - UI model
fileprivate struct UIProduct: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let priceInt: Int
    let monthlyInt: Int
    let stock: Int
    let imageURL: URL?

    init(_ p: ProductsAPI.APIProduct) {
        id = p.id
        title = p.title
        subtitle = p.description
        priceInt = UIProduct.parsePrice(p.price)
        monthlyInt = max(1, priceInt / 12)
        stock = p.stock
        imageURL = URL(string: p.banner_main ?? p.banner_second ?? "")
    }

    private static func parsePrice(_ s: String) -> Int {
        let s2 = s.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        if let d = Double(s2) { return Int(d.rounded()) }
        if let i = Int(s2) { return i }
        return 0
    }
}

// MARK: - UI pieces (same as before)
private struct TopBrandBar: View {
    var body: some View {
        HStack {
            Button {} label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(8)
            }
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "creditcard.fill")
                Text("AmanPay").font(.callout.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Brand.primary)
            .clipShape(Capsule())
            .shadow(color: Brand.primary.opacity(0.35), radius: 10, x: 0, y: 6)
            Spacer()
            Button {} label: {
                Image(systemName: "bell.badge")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Brand.primary)
                    .padding(8)
            }
        }
        .padding(.horizontal, 16).padding(.top, 8)
    }
}

private struct SearchBar: View {
    @Binding var text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Mahsulot qidirish", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
            if !text.isEmpty {
                Button { withAnimation { text = "" } } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 12).padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }
}

private struct ProductCard: View {
    let product: UIProduct
    @State private var wish = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemGray6))
                    .frame(height: 150)
                    .overlay {
                        if let url = product.imageURL {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ShimmerView().clipShape(RoundedRectangle(cornerRadius: 16))
                                case .success(let img):
                                    img.resizable().scaledToFill()
                                        .frame(height: 150).clipped()
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable().scaledToFit()
                                        .frame(height: 80)
                                        .foregroundStyle(.secondary)
                                @unknown default: EmptyView()
                                }
                            }
                        } else {
                            Image(systemName: "photo")
                                .resizable().scaledToFit()
                                .frame(height: 80)
                                .foregroundStyle(.secondary)
                        }
                    }

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.white)
                    Text("Halol nasiya")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(8)

                HStack { Spacer()
                    Button { wish.toggle() } label: {
                        Image(systemName: wish ? "heart.circle.fill" : "heart.circle")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(wish ? .red : .white.opacity(0.9))
                            .shadow(radius: 4)
                    }
                    .padding(8)
                }
            }

            HStack(alignment: .firstTextBaseline) {
                Text("\(formatSom(product.priceInt)) so‘m")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                Spacer(minLength: 6)
                Text("\(formatSom(product.monthlyInt)) so‘m/oy")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Brand.primary)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Brand.primary.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(product.title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            HStack(spacing: 8) {
                Image(systemName: "star.fill").foregroundStyle(.yellow)
                Text("4.6").font(.footnote.weight(.semibold))
                Text("Omborda: \(product.stock) ta")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Button { UIImpactFeedbackGenerator(style: .soft).impactOccurred() } label: {
                Text("Savatga")
                    .font(.callout.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Brand.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 8)
    }

    private func formatSom(_ v: Int) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.groupingSeparator = " "
        nf.maximumFractionDigits = 0
        return nf.string(from: NSNumber(value: v)) ?? "\(v)"
    }
}

private struct ShimmerCard: View {
    var body: some View {
        VStack(spacing: 10) {
            ShimmerView().frame(height: 150).clipShape(RoundedRectangle(cornerRadius: 16))
            ShimmerView().frame(height: 16).clipShape(Capsule())
            ShimmerView().frame(height: 12).clipShape(Capsule())
            ShimmerView().frame(height: 38).clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 8)
    }
}

private struct ShimmerView: View {
    @State private var x: CGFloat = -1
    var body: some View {
        Rectangle()
            .fill(.gray.opacity(0.25))
            .overlay(
                LinearGradient(colors: [.clear, .white.opacity(0.75), .clear],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .rotationEffect(.degrees(20))
                    .offset(x: x * 240)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    x = 1.2
                }
            }
    }
}

