import SwiftUI

/// Onglet Mode d'emploi : les quatre moments de l'été, les deux questions à
/// se poser avant d'ouvrir, le courant d'air, puis l'aération le reste de
/// l'année.
struct GuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                stepCard(
                    glyph: .openNight,
                    kicker: "Quand il fait 2 °C de moins dehors que chez vous",
                    kickerColor: .nadirCold,
                    title: "Ouvrez grand",
                    body: Text("L’air frais refroidit vos murs pendant la nuit. Ce sont eux qui garderont votre logement frais demain.")
                ) {
                    DisclosureRow(
                        title: "Pourquoi l’heure change chaque nuit\u{00A0}?",
                        verticalPadding: 10, borderColor: .nadirHairline
                    ) {
                        Text("Le plus frais de la nuit arrive souvent juste avant le lever du soleil, mais cela dépend de la météo. C’est pour ça que NADIR recalcule l’heure chaque jour.")
                    }
                }

                stepCard(
                    glyph: .closeShutters,
                    kicker: "Quand il recommence à faire chaud dehors",
                    kickerColor: .nadirHot,
                    title: "Fermez tout",
                    body: Text("Fermez les fenêtres, et les ")
                        + Text("volets").foregroundColor(.white)
                        + Text(" si vous en avez. La fraîcheur de la nuit reste ainsi à l’intérieur.")
                ) {
                    DisclosureRow(
                        title: "Volets ou rideaux\u{00A0}?",
                        verticalPadding: 10, borderColor: .nadirHairline
                    ) {
                        Text("Un volet arrête le soleil avant la vitre. Un rideau l’arrête après, quand la chaleur est déjà entrée.")
                    }
                }

                stepCard(
                    glyph: .stayClosed,
                    kicker: "Tant qu’il fait plus chaud dehors",
                    kickerColor: .nadirHot,
                    title: "Restez fermé",
                    body: Text("Ouvrir ferait entrer de l’air plus chaud que le vôtre.")
                ) {
                    DisclosureRow(
                        title: "Et si j’ai trop chaud\u{00A0}?",
                        verticalPadding: 10, borderColor: .nadirHairline
                    ) {
                        Text("Un ventilateur ne refroidit pas la pièce, mais il vous rafraîchit, ")
                            + Text("vous").foregroundColor(.white)
                            + Text(". Utilisez-le sans hésiter.")
                    }
                }

                stepCard(
                    glyph: .reopen,
                    kicker: "Quand il refait 2 °C de moins dehors",
                    kickerColor: .nadirCold,
                    title: "Rouvrez",
                    body: Text("C’est la même règle que la veille. L’heure exacte est dans ")
                        + Text("Aujourd’hui").foregroundColor(.white)
                        + Text(".")
                ) {
                    EmptyView()
                }

                beforeOpening
                crossDraft
                restOfTheYear
            }
            .padding(.bottom, 104)
        }
        .scrollIndicators(.hidden)
        .background(Color.black)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(text: "Mode d’emploi", size: 38)
            Text("En été, tout se joue sur deux moments : quand ouvrir, et quand fermer. NADIR vous donne les heures dans Aujourd’hui.")
                .font(.nadirSans(16))
                .lineSpacing(3)
                .foregroundStyle(Color.nadirSoft)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 28)
        .riseIn(trigger: 0, delay: 0.05)
    }

    private func stepCard(
        glyph: WindowIcon.Glyph,
        kicker: String,
        kickerColor: Color,
        title: String,
        body: Text,
        @ViewBuilder detail: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 15) {
                WindowIcon(glyph: glyph)
                VStack(alignment: .leading, spacing: 4) {
                    Text(kicker)
                        .font(.nadirSans(14, weight: .medium))
                        .foregroundStyle(kickerColor)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(title)
                        .font(.nadirSans(24, weight: .heavy))
                        .tracking(-0.6)
                        .foregroundStyle(.white)
                }
            }
            body
                .font(.nadirSans(15))
                .lineSpacing(3)
                .foregroundStyle(Color.nadirSoft)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)
            detail()
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
    }

    private var beforeOpening: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(
                "Avant d’ouvrir, deux questions",
                intro: "En dehors de ces quatre moments, posez-vous ces deux questions."
            )

            VStack(spacing: 0) {
                ledgerRow(
                    number: "1",
                    title: "Fait-il au moins 2 °C de moins dehors\u{00A0}?",
                    detail: "En dessous, ouvrir ne change presque rien."
                )
                ledgerRow(
                    number: "2",
                    title: "L’air du dehors est-il sec\u{00A0}?",
                    detail: "Un air frais mais humide ne rafraîchit pas vraiment : il colle."
                )
            }
            .overlay(alignment: .top) { Color.nadirLine2.frame(height: 1) }

            Text("Oui aux deux : ouvrez. Sinon, attendez.")
                .font(.nadirSans(15, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.top, 20)
        }
    }

    private func ledgerRow(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.nadirSans(15, weight: .semibold))
                .foregroundStyle(Color.nadirGo)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.nadirSans(16, weight: .semibold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.nadirSans(14))
                    .lineSpacing(3)
                    .foregroundStyle(Color.nadirDim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .overlay(alignment: .bottom) { Color.nadirLine.frame(height: 1) }
    }

    private var crossDraft: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(
                "Faire un courant d’air",
                intro: "Une fenêtre ouverte laisse entrer un peu d’air. Un courant d’air en fait entrer beaucoup plus."
            )
            .padding(.top, 16)

            VStack(spacing: 0) {
                adviceRow(
                    title: "Ouvrez des deux côtés",
                    body: "Si vous avez des fenêtres sur deux côtés, ouvrez-les en même temps : l’air entre d’un côté et sort de l’autre. Sinon, laissez au moins les portes intérieures ouvertes."
                )
                adviceRow(
                    title: "Ouvrez en bas et en haut",
                    body: "Avec un étage ou une fenêtre de toit, ouvrez aussi en haut. L’air chaud sort par le haut et aspire l’air frais par le bas."
                )
                adviceRow(
                    title: "Tenez compte du vent",
                    body: "Ouvrez en priorité la fenêtre qui fait face au vent."
                )
            }
            .padding(.horizontal, 20)
        }
    }

    private var restOfTheYear: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(
                "Le reste de l’année, aérer",
                intro: "Quand il ne fait pas chaud, il faut quand même aérer chaque jour pour chasser l’humidité. NADIR vous indique alors le moment le plus doux de la journée."
            )
            .padding(.top, 16)

            VStack(spacing: 0) {
                adviceRow(
                    title: "Aérez peu de temps, mais en grand",
                    body: "Quelques minutes fenêtres grandes ouvertes suffisent à renouveler l’air. Une fenêtre entrouverte toute la journée refroidit les murs sans mieux aérer."
                )
                adviceRow(
                    title: "Aérez au plus doux",
                    body: "Plus il fait doux dehors, moins votre logement perd de chaleur. C’est souvent en début d’après-midi."
                )
                adviceRow(
                    title: "Baissez le chauffage pendant ce temps",
                    body: "Inutile de chauffer l’air qui sort par la fenêtre."
                )
            }
            .padding(.horizontal, 20)
        }
    }

    private func sectionHeader(_ title: String, intro: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(text: title, size: 26)
            Text(intro)
                .font(.nadirSans(15))
                .lineSpacing(3)
                .foregroundStyle(Color.nadirSoft)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 32)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
        .padding(.top, 8)
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
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
    }
}
