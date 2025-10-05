import SwiftUI

struct HomeTabView: View {
    @State private var query = ""

    private let products: [HPProduct] = HPProduct.mock
    private let columns = [GridItem(.flexible(), spacing: 14),
                           GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Top bar
                    HStack {
                        Button { /* TODO: dismiss yoki menyu */ } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.primary)
                                .padding(8)
                        }
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "creditcard.fill")
                            Text("AmanPay").font(.callout.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Brand.primary)
                        .clipShape(Capsule())
                        Spacer()
                        Color.clear.frame(width: 34, height: 34)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Qidiruv
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("Mahsulot qidirish", text: $query)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                        if !query.isEmpty {
                            Button { withAnimation { query = "" } } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 16)

                    // Grid
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(filtered) { item in
                            HPProductCard(product: item)
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
            .navigationBarHidden(true)
        }
    }

    private var filtered: [HPProduct] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return q.isEmpty ? products : products.filter { $0.title.lowercased().contains(q) }
    }
}

// MARK: - Product Card
private struct HPProductCard: View {
    let product: HPProduct
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemGray6))
                if let url = product.imageURL {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFit()
                    } placeholder: { ProgressView() }
                    .padding(8)
                } else {
                    Image(systemName: "photo")
                        .resizable().scaledToFit().padding(18)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 150)

            // Agar sizda umumiy extension Int.formattedSom bor bo‘lsa, shuni ishlating:
            // Text(product.price.formattedSom)
            // Aks holda, quyidagi lokal funksiya bilan ishlayveradi:
            Text(formatSom(product.price))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)

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

// MARK: - Model (mock)
private struct HPProduct: Identifiable {
    let id = UUID()
    let title: String
    let price: Int
    let imageURL: URL?

    static let mock: [HPProduct] = [
        HPProduct(title: "Apple iPhone 13, 128GB", price: 7_580_000,
                  imageURL: URL(string: "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-13-select-2021")),
        HPProduct(title: "Samsung Galaxy A16, 6/128GB", price: 2_599_000,
                  imageURL: URL(string: "https://images.samsung.com/is/image/samsung/p6pim/levant/sm-a165/gallery/")),
        HPProduct(title: "Xiaomi Redmi 13C, 4/128GB", price: 2_199_000,
                  imageURL: URL(string: "https://i01.appmifile.com/webfile/globalimg/products/pc/redmi-13c/section01.png")),
        HPProduct(title: "BYD e2 (Autozone)", price: 239_100_000,
                  imageURL: URL(string: "https://icdn.dantri.com.vn/2023/06/14/byd-e2-1-1686714981090.jpg"))
    ]
}

// MARK: - Lokal format helper (extension o‘rniga, to‘qnashuv bo‘lmasin)
private func formatSom(_ value: Int) -> String {
    let nf = NumberFormatter()
    nf.groupingSize = 3
    nf.usesGroupingSeparator = true
    nf.groupingSeparator = " "
    nf.numberStyle = .decimal
    let num = nf.string(from: NSNumber(value: value)) ?? "\(value)"
    return num + " so‘m"
}
