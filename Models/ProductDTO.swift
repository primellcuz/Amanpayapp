import Foundation

struct ProductDTO: Codable, Identifiable {
    let id: Int
    let seller_id: Int?
    let title: String
    let description: String?
    let price: String
    let stock: Int?
    let is_active: Bool?
    let images: [String]?
    let primary_index: Int?
    let created_at: String?

    var priceDecimal: Decimal { Decimal(string: price) ?? .zero }
    var priceSomText: String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.groupingSeparator = " "
        nf.maximumFractionDigits = 0
        return (nf.string(from: priceDecimal as NSDecimalNumber) ?? price) + " so‘m"
    }

    func primaryImageURL(baseURL: URL) -> URL? {
        guard let images, !images.isEmpty else { return nil }
        let i = (0..<images.count).contains(primary_index ?? 0) ? (primary_index ?? 0) : 0
        let path = images[i]
        if let url = URL(string: path), url.scheme != nil { return url }
        var comp = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        comp.path = path.hasPrefix("/") ? path : "/" + path
        return comp.url
    }
}
