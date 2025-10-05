import Foundation

struct ProductDTO: Identifiable, Codable, Hashable {
    let id: Int
    let sellerId: Int
    let title: String
    let description: String
    let price: String        // server: "12000.00"
    let stock: Int
    let isActive: Bool
    let bannerMain: URL?
    let bannerSecond: URL?
    let bannerThird: URL?
    let bannerFourth: URL?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case sellerId       = "seller_id"
        case title, description, price, stock
        case isActive       = "is_active"
        case bannerMain     = "banner_main"
        case bannerSecond   = "banner_second"
        case bannerThird    = "banner_third"
        case bannerFourth   = "banner_fourth"
        case createdAt      = "created_at"
    }
}

extension ProductDTO {
    var priceDecimal: Decimal? { Decimal(string: price) }

    /// Masalan: "12 000 so‘m"
    var formattedSom: String {
        guard let dec = priceDecimal else { return price + " so‘m" }
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.groupingSeparator = " "
        nf.maximumFractionDigits = 0
        let base = nf.string(from: dec as NSDecimalNumber) ?? price
        return base + " so‘m"
    }
}
