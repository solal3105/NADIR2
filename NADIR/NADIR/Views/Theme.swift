import SwiftUI

/// Palette NADIR — noir brutaliste, accents signifiants :
/// rouge = chaud, bleu = frais, vert = créneau favorable.
extension Color {
    static let nadirHot = Color(red: 1, green: 59 / 255, blue: 29 / 255)          // #ff3b1d
    static let nadirCold = Color(red: 62 / 255, green: 166 / 255, blue: 1)        // #3ea6ff
    static let nadirGo = Color(red: 90 / 255, green: 209 / 255, blue: 122 / 255)  // #5ad17a
    static let nadirSoft = Color(white: 196 / 255)      // #c4c4c4 : texte courant
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

    /// Écart en degrés pour une phrase : « 4,2 °C », « 4 °C ».
    var degreesText: String {
        let value = oneDecimal.hasSuffix(",0") ? String(oneDecimal.dropLast(2)) : oneDecimal
        return "\(value)\u{00A0}°C"
    }
}

extension String {
    /// Première lettre en majuscule : « demain vers 16 h » → « Demain vers 16 h ».
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}

/// Petit titre de section, en gris : « Me prévenir », « Qui est derrière ? »…
struct Eyebrow: View {
    let text: String
    var color: Color = .nadirDim

    var body: some View {
        Text(text)
            .font(.nadirSans(14, weight: .semibold))
            .foregroundStyle(color)
    }
}

/// Grand titre de section, gras et serré : « Mode d’emploi », « Comprendre »…
struct SectionTitle: View {
    let text: String
    var size: CGFloat = 30

    var body: some View {
        Text(text)
            .font(.nadirSans(size, weight: .heavy))
            .tracking(size * -0.03)
            .foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
    }
}
