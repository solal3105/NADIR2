import SwiftUI

/// Onglet Comprendre : la physique derrière le geste — les murs éponges,
/// la limite honnête, le résumé en cinq points et les sources.
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
            Eyebrow(text: "La physique")
            SectionTitle(text: "Comprendre", size: 44)
                .padding(.top, 10)
            paragraph(Text("Vous n'avez besoin de rien de tout ça pour bien faire."))
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 4)
        .riseIn(trigger: 0, delay: 0.05)
    }

    private var walls: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(text: "Ce qui se passe\ndans vos murs")
                .padding(.horizontal, 20)
                .padding(.top, 32)

            WallIllustration()
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
                .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 0) {
                paragraph(Text("Le jour, vos murs absorbent la chaleur comme une éponge absorbe l'eau. La nuit, ils la relâchent, si vous ouvrez les fenêtres."))
                    .padding(.bottom, 24)

                VStack(alignment: .leading, spacing: 0) {
                    (
                        Text("−4,7").foregroundColor(.nadirGo).font(.nadirMono(60))
                            + Text(" °C").foregroundColor(.nadirDim).font(.nadirMono(16))
                    )
                    .tracking(-1.2)
                    paragraph(Text("C'est ce qu'on gagne avec des murs lourds, bien ventilés la nuit."))
                        .padding(.top, 14)
                }
                .padding(.leading, 16)
                .overlay(alignment: .leading) { Color.nadirGo.frame(width: 2) }

                paragraph(Text("Des murs lourds sans air frais la nuit ne servent à rien : ils n'ont rien à absorber."))
                    .padding(.top, 20)

                DisclosureRow(title: "En détail", showsBottomBorder: true) {
                    Text("Vos murs retardent la chaleur de plusieurs heures. C'est pour ça qu'il fait parfois plus chaud chez vous en fin d'après-midi qu'il ne fait dehors à ce moment-là.")
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
                SectionTitle(text: "Sans nuit fraîche,\nrien à stocker")
                (
                    Text("Certaines nuits d'été restent chaudes, ")
                        .foregroundColor(.nadirHot).fontWeight(.semibold)
                        + Text("surtout quand l'air est humide. Ouvrir ne sert alors à rien : il n'y a pas d'air frais à faire entrer. Restez ")
                        + Text("fermé et à l'ombre").foregroundColor(.white)
                        + Text(", et attendez une nuit plus fraîche.")
                )
                .font(.nadirSans(15))
                .lineSpacing(4)
                .foregroundStyle(Color.nadirDim)
                .padding(18)
                .border(Color.nadirHot, width: 1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
            .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
            .padding(.top, 24)

            adviceRow(
                title: "Le ventilateur",
                body: "Il ne change pas la température de la pièce. Il accélère l'évaporation de votre sueur, et c'est ça qui vous rafraîchit."
            )
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(text: "Le résumé,\nen cinq points")
                .padding(.horizontal, 20)
                .padding(.top, 32)
                .padding(.bottom, 4)

            VStack(spacing: 0) {
                summaryRow(
                    "1", "Ouvrez dès que dehors est 2 °C plus frais",
                    "souvent en fin de nuit, mais ça change chaque jour"
                )
                summaryRow(
                    "2", "Fermez tout dès que ça se réchauffe dehors",
                    "fenêtres, et volets si vous en avez"
                )
                summaryRow(
                    "3", "Vérifiez aussi que l'air est sec dehors",
                    "un air frais mais humide ne rafraîchit pas vraiment"
                )
                summaryRow(
                    "4", "Si possible, un courant d'air : deux façades, du bas vers le haut",
                    "ouvrez des deux côtés du logement"
                )
                summaryRow(
                    "5", "Par canicule humide, restez fermé et à l'ombre",
                    "il n'y a rien à gagner"
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
            HStack(spacing: 12) {
                Text("+").foregroundStyle(.white)
                Text("POUR ALLER PLUS LOIN")
            }
            .font(.nadirMono(11))
            .tracking(1.3)
            .foregroundStyle(Color.nadirDim)
            .padding(.bottom, 16)

            DisclosureRow(title: "Pourquoi refroidir les murs, pas juste l'air ?", verticalPadding: 12) {
                Text("L'air d'une pièce change de température en quelques minutes : il ne stocke presque rien. Les murs, eux, mettent des heures à changer, et stockent ")
                    + Text("des milliers de fois plus").foregroundColor(.white)
                    + Text(" de chaleur.")
            }
            DisclosureRow(title: "Peut-on prévoir la température à l'avance ?", verticalPadding: 12) {
                Text("Oui : un modèle simple, basé sur la météo à venir, prédit la température chez vous à l'avance. Utilisé pour piloter le chauffage ou la climatisation, il peut réduire l'énergie consommée de ")
                    + Text("40 %").foregroundColor(.white)
                    + Text(".")
            }
            DisclosureRow(
                title: "Comment sait-on si un geste fonctionne vraiment ?",
                verticalPadding: 12, showsBottomBorder: true
            ) {
                Text("On additionne le temps passé au-dessus d'un seuil de confort. Plus la somme est basse, plus la stratégie est efficace.")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
        .padding(.top, 24)
    }

    private var sources: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("D'OÙ ÇA VIENT · LITTÉRATURE VÉRIFIÉE")
                .font(.nadirMono(10))
                .tracking(1)
                .foregroundStyle(Color.nadirFaint)
                .padding(.bottom, 14)
            Text("MIT CoolVent · OMS / NCBI NBK143285 · Building & Environment 2021 · Yam et al. 2007 · Kolokotroni et al. 1998 · PMC3708435 · AIVC · arXiv 1806.08999 · PMC10576096 · AIRAH 2015.")
                .font(.nadirMono(11))
                .lineSpacing(8)
                .foregroundStyle(Color.nadirDim)
            Text("Modèle simplifié : impossible d'avoir toutes les données d'un logement réel. Les chiffres varient selon l'isolation, le vitrage, l'étage, l'environnement. Ce sont des estimations, des ordres de grandeur, pas des mesures.")
                .font(.nadirMono(10))
                .lineSpacing(5)
                .foregroundStyle(Color.nadirLine2)
                .padding(.top, 18)
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
            .font(.nadirSans(15))
            .lineSpacing(4)
            .foregroundStyle(Color.nadirDim)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func adviceRow(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.nadirSans(17, weight: .bold))
                .tracking(-0.17)
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
                .font(.nadirMono(12))
                .foregroundStyle(Color.nadirGo)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.nadirSans(15))
                    .lineSpacing(2)
                    .foregroundStyle(.white)
                Text(hint)
                    .font(.nadirMono(11))
                    .lineSpacing(3)
                    .foregroundStyle(Color.nadirFaint)
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

            label("JOUR · ABSORBE", x: 70, y: 143)
            label("NUIT · RESTITUE", x: 170, y: 143)
        }
        .frame(width: width, height: width * 152 / 240)
        .accessibilityLabel("Le jour, le mur absorbe la chaleur ; la nuit, il la restitue à l'air frais.")
    }
}
