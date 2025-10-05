import SwiftUI

enum Brand {
    static let primary   = Color("BrandPrimary", bundle: .main)   // e.g. #0070F0
    static let secondary = Color("BrandSecondary", bundle: .main) // e.g. #00B2FF
    static let ink       = Color("BrandInk", bundle: .main)       // #0B1D2A
    static let bgTop     = Color("BrandBGTop", bundle: .main)     // #F7FAFF
    static let bgBottom  = Color("BrandBGBottom", bundle: .main)  // #ECF3FB
}

// Safe fallbacks if asset colors aren’t added yet
extension Color {
    init(_ name: String, bundle: Bundle) {
        self = Color(name, bundle: bundle, fallback: nil) ?? Color.primaryFallback(name)
    }
    private static func primaryFallback(_ name: String) -> Color {
        switch name {
        case "BrandPrimary":   return Color(red: 0.0, green: 0.44, blue: 0.94)   // #0070F0
        case "BrandSecondary": return Color(red: 0.0, green: 0.70, blue: 1.0)    // #00B2FF
        case "BrandInk":       return Color(red: 0.04, green: 0.11, blue: 0.16)  // #0B1D2A
        case "BrandBGTop":     return Color(red: 0.97, green: 0.98, blue: 1.0)   // #F7FAFF
        case "BrandBGBottom":  return Color(red: 0.93, green: 0.95, blue: 0.98)  // #ECF3FB
        default: return .blue
        }
    }
}
private extension Color {
    init?(_ name: String, bundle: Bundle, fallback: Void?) {
        if UIColor(named: name, in: bundle, compatibleWith: nil) != nil {
            self = Color(name, bundle: bundle)
        } else {
            return nil
        }
    }
}
