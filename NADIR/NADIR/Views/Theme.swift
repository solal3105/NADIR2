import SwiftUI

/// Palette NADIR — noir brutaliste, accents signifiants :
/// rouge = chaud, bleu = frais, vert = créneau favorable.
extension Color {
    static let nadirHot = Color(red: 1, green: 59 / 255, blue: 29 / 255)          // #ff3b1d
    static let nadirCold = Color(red: 62 / 255, green: 166 / 255, blue: 1)        // #3ea6ff
    static let nadirGo = Color(red: 90 / 255, green: 209 / 255, blue: 122 / 255)  // #5ad17a
    static let nadirDim = Color(white: 140 / 255)       // #8c8c8c
    static let nadirFaint = Color(white: 90 / 255)      // #5a5a5a
    static let nadirLine = Color(white: 36 / 255)       // #242424
    static let nadirLine2 = Color(white: 58 / 255)      // #3a3a3a
    static let nadirHairline = Color(white: 26 / 255)   // #1a1a1a
    static let nadirChartBackground = Color(white: 5 / 255)   // #050505
    static let nadirSwitchOff = Color(red: 57 / 255, green: 57 / 255, blue: 61 / 255)  // #39393d
}

extension Font {
    static func nadirMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static func nadirSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}

extension Double {
    /// Une décimale, virgule française : 4.7 → « 4,7 ».
    var oneDecimal: String {
        String(format: "%.1f", self).replacingOccurrences(of: ".", with: ",")
    }

    /// Entier arrondi : 26.0 → « 26 ».
    var noDecimal: String {
        String(format: "%.0f", self)
    }
}

/// Étiquette de section en petites capitales mono — « LE VERDICT », « ALARMES »…
struct Eyebrow: View {
    let text: String
    var color: Color = .nadirFaint

    var body: some View {
        Text(text.uppercased())
            .font(.nadirMono(11))
            .tracking(1.3)
            .foregroundStyle(color)
    }
}

/// Titre de section majuscules ultra-serré — « LE GESTE », « COMPRENDRE »…
struct SectionTitle: View {
    let text: String
    var size: CGFloat = 34

    var body: some View {
        Text(text.uppercased())
            .font(.nadirSans(size, weight: .heavy))
            .tracking(size * -0.035)
            .lineSpacing(size * -0.06)
            .foregroundStyle(.white)
    }
}
