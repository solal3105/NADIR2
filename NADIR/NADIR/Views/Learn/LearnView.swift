import SwiftUI

/// Onglet Comprendre : pourquoi les conseils marchent (les murs qui
/// stockent la chaleur), la limite des nuits chaudes, l'essentiel en cinq
/// points et les sources.
struct LearnView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                walls
                noCoolNight
                summary
                goFurther
                sources
            }
            .padding(.bottom, 104)
        }
        .scrollIndicators(.hidden)
        .background(Color.black)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(text: "Comprendre", size: 38)
            paragraph(Text("Pas besoin de lire cette page pour bien faire. Elle explique simplement pourquoi les conseils de NADIR marchent."))
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 4)
        .riseIn(trigger: 0, delay: 0.05)
    }

    private var walls: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(text: "Vos murs stockent la chaleur", size: 26)
                .padding(.horizontal, 20)
                .padding(.top, 32)

            WallIllustration()
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
                .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 0) {
                paragraph(Text("Le jour, vos murs absorbent la chaleur, comme une éponge absorbe l’eau. La nuit, si vous ouvrez, ils la rendent à l’air frais et se refroidissent."))
                    .padding(.bottom, 24)

                VStack(alignment: .leading, spacing: 0) {
                    (
                        Text("−4,7").foregroundColor(.nadirGo).font(.nadirMono(60))
                            + Text(" °C").foregroundColor(.nadirDim).font(.nadirMono(16))
                    )
                    .tracking(-1.2)
                    paragraph(Text("C’est ce que l’on peut gagner au plus chaud de la journée, avec des murs lourds bien aérés la nuit."))
                        .padding(.top, 14)
                }
                .padding(.leading, 16)
                .overlay(alignment: .leading) { Color.nadirGo.frame(width: 2) }

                paragraph(Text("Sans air frais la nuit, des murs lourds ne servent à rien : ils restent chauds."))
                    .padding(.top, 20)

                DisclosureRow(title: "Pourquoi fait-il parfois plus chaud chez moi que dehors\u{00A0}?", showsBottomBorder: true) {
                    Text("Vos murs rendent la chaleur avec plusieurs heures de retard. En fin d’après-midi, ils peuvent encore chauffer votre logement alors que l’air du dehors commence à fraîchir.")
                }
                .padding(.top, 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
        }
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
        .padding(.top, 24)
    }

    private var noCoolNight: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                SectionTitle(text: "Quand la nuit reste chaude", size: 26)
                (
                    Text("Certaines nuits d’été restent chaudes, ")
                        .foregroundColor(.nadirHot).fontWeight(.semibold)
                        + Text("surtout quand l’air est humide. Ouvrir ne sert alors à rien. Gardez tout ")
                        + Text("fermé et à l’ombre").foregroundColor(.white)
                        + Text(", et attendez une nuit plus fraîche.")
                )
                .font(.nadirSans(15))
                .lineSpacing(4)
                .foregroundStyle(Color.nadirSoft)
                .padding(18)
                .border(Color.nadirHot, width: 1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
            .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
            .padding(.top, 24)

            adviceRow(
                title: "Et le ventilateur\u{00A0}?",
                body: "Il ne change pas la température de la pièce. Il fait s’évaporer votre transpiration plus vite, et c’est ce qui vous rafraîchit."
            )
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(text: "L’essentiel en cinq points", size: 26)
                .padding(.horizontal, 20)
                .padding(.top, 32)
                .padding(.bottom, 4)

            VStack(spacing: 0) {
                summaryRow(
                    "1", "Ouvrez dès qu’il fait 2 °C de moins dehors",
                    "Souvent en fin de nuit, mais l’heure change chaque jour."
                )
                summaryRow(
                    "2", "Fermez tout dès qu’il refait chaud dehors",
                    "Les fenêtres, et les volets si vous en avez."
                )
                summaryRow(
                    "3", "Vérifiez que l’air du dehors est sec",
                    "Un air frais mais humide ne rafraîchit pas vraiment."
                )
                summaryRow(
                    "4", "Faites un courant d’air si vous pouvez",
                    "Ouvrez des deux côtés du logement, en bas et en haut."
                )
                summaryRow(
                    "5", "Pendant une canicule humide, restez fermé et à l’ombre",
                    "Il n’y a rien à gagner à ouvrir."
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .overlay(alignment: .top) { Color.nadirLine2.frame(height: 1) }
        .padding(.top, 24)
    }

    private var goFurther: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "Pour aller plus loin")
                .padding(.bottom, 12)

            DisclosureRow(title: "Pourquoi refroidir les murs, et pas seulement l’air\u{00A0}?") {
                Text("L’air d’une pièce change de température en quelques minutes : il ne garde presque rien. Les murs mettent des heures à changer, et stockent ")
                    + Text("des milliers de fois plus").foregroundColor(.white)
                    + Text(" de chaleur.")
            }
            DisclosureRow(title: "Peut-on prévoir la température chez soi\u{00A0}?") {
                Text("Oui. Un modèle simple, nourri par les prévisions météo, prédit la température d’un logement à l’avance. Pour piloter un chauffage ou une climatisation, il peut réduire l’énergie consommée de ")
                    + Text("40 %").foregroundColor(.white)
                    + Text(".")
            }
            DisclosureRow(
                title: "Comment savoir si un geste marche vraiment\u{00A0}?",
                showsBottomBorder: true
            ) {
                Text("On compte les heures passées au-dessus d’une température de confort. Moins il y en a, plus le geste est efficace.")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
        .padding(.top, 24)
    }

    private var sources: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "Sources")
                .padding(.bottom, 12)
            Text("MIT CoolVent, OMS (NCBI NBK143285), Building & Environment 2021, Yam et al. 2007, Kolokotroni et al. 1998, PMC3708435, AIVC, arXiv 1806.08999, PMC10576096, AIRAH 2015.")
                .font(.nadirSans(13))
                .lineSpacing(4)
                .foregroundStyle(Color.nadirDim)
            Text("NADIR utilise un modèle simplifié. Il ne connaît pas l’isolation, le vitrage, l’étage ou l’environnement de votre logement : ses chiffres sont des ordres de grandeur, pas des mesures.")
                .font(.nadirSans(13))
                .lineSpacing(4)
                .foregroundStyle(Color.nadirDim)
                .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 32)
        .padding(.bottom, 8)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
        .padding(.top, 24)
    }

    // MARK: - Helpers

    private func paragraph(_ text: Text) -> some View {
        text
            .font(.nadirSans(16))
            .lineSpacing(4)
            .foregroundStyle(Color.nadirSoft)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func adviceRow(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.nadirSans(16, weight: .semibold))
                .foregroundStyle(.white)
            Text(body)
                .font(.nadirSans(15))
                .lineSpacing(3)
                .foregroundStyle(Color.nadirDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
    }

    private func summaryRow(_ number: String, _ title: String, _ hint: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Text(number)
                .font(.nadirSans(15, weight: .semibold))
                .foregroundStyle(Color.nadirGo)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.nadirSans(16, weight: .semibold))
                    .lineSpacing(2)
                    .foregroundStyle(.white)
                Text(hint)
                    .font(.nadirSans(14))
                    .lineSpacing(3)
                    .foregroundStyle(Color.nadirDim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 15)
        .overlay(alignment: .bottom) { Color.nadirLine.frame(height: 1) }
    }
}

/// Le jour, le mur absorbe la chaleur ; la nuit, il la restitue à l'air
/// frais. Port de l'illustration du design (viewbox 240 × 152).
struct WallIllustration: View {
    var width: CGFloat = 210

    var body: some View {
        Canvas { context, size in
            let s = size.width / 240
            func point(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * s, y: y * s) }
            func arrow(_ x1: Double, _ y: Double, _ x2: Double, tipX: Double, color: Color) {
                var line = Path()
                line.move(to: point(x1, y))
                line.addLine(to: point(x2, y))
                context.stroke(line, with: .color(color), lineWidth: 2 * s)
                var tip = Path()
                tip.move(to: point(tipX, y))
                tip.addLine(to: point(tipX - 10, y - 5))
                tip.addLine(to: point(tipX - 10, y + 5))
                tip.closeSubpath()
                context.fill(tip, with: .color(color))
            }
            func label(_ string: String, x: Double, y: Double) {
                context.draw(
                    Text(string).font(.nadirMono(10 * s)).foregroundStyle(Color.nadirDim),
                    at: point(x, y), anchor: .center
                )
            }

            // Soleils : le jour chauffe, la nuit est claire.
            context.fill(
                Path(ellipseIn: CGRect(x: 26 * s, y: 24 * s, width: 20 * s, height: 20 * s)),
                with: .color(.nadirHot)
            )
            context.fill(
                Path(ellipseIn: CGRect(x: 196 * s, y: 26 * s, width: 16 * s, height: 16 * s)),
                with: .color(.white)
            )

            // Le mur, hachuré.
            context.stroke(
                Path(CGRect(x: 104 * s, y: 24 * s, width: 32 * s, height: 104 * s)),
                with: .color(.white), lineWidth: 2 * s
            )
            var hatches = Path()
            for (y1, y2) in [(118.0, 94.0), (92.0, 68.0), (66.0, 42.0)] {
                hatches.move(to: point(108, y1))
                hatches.addLine(to: point(132, y2))
            }
            context.stroke(hatches, with: .color(.white.opacity(0.35)), lineWidth: 1.5 * s)

            // Le jour absorbe (rouge), la nuit restitue (bleu).
            for y in [62.0, 86.0, 110.0] {
                arrow(54, y, 92, tipX: 100, color: .nadirHot)
                arrow(140, y, 178, tipX: 186, color: .nadirCold)
            }

            label("le jour", x: 70, y: 143)
            label("la nuit", x: 170, y: 143)
        }
        .frame(width: width, height: width * 152 / 240)
        .accessibilityLabel("Le jour, le mur absorbe la chaleur. La nuit, il la rend à l’air frais.")
    }
}
