import SwiftUI

/// Onglet Le geste : le mode d'emploi en quatre moments, puis les deux
/// questions avant d'ouvrir, puis comment faire un vrai courant d'air.
struct GuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                stepCard(
                    glyph: .openNight,
                    kicker: "Dès que dehors est 2 °C plus frais",
                    kickerColor: .nadirCold,
                    title: "Ouvrez en grand",
                    body: Text("L'air frais refroidit vos murs. Ce sont eux qui garderont votre logement au frais demain.")
                ) {
                    DisclosureRow(
                        title: "Pourquoi l'heure change chaque nuit ?",
                        verticalPadding: 9, borderColor: .nadirHairline
                    ) {
                        Text("Il fait souvent plus froid ")
                            + Text("juste avant le lever du jour").underline()
                            + Text(" qu'à minuit. Mais ça change selon la météo, donc on ne peut pas vous donner une heure fixe.")
                    }
                }

                stepCard(
                    glyph: .closeShutters,
                    kicker: "Dès qu'il refait plus chaud dehors",
                    kickerColor: .nadirHot,
                    title: "Fermez tout",
                    body: Text("Fermez les fenêtres. Si vous avez des ")
                        + Text("volets").foregroundColor(.white)
                        + Text(", fermez-les aussi : la fraîcheur de la nuit reste enfermée chez vous.")
                ) {
                    DisclosureRow(
                        title: "Volets ou rideaux ?",
                        verticalPadding: 9, borderColor: .nadirHairline
                    ) {
                        Text("Un volet arrête le soleil avant qu'il touche la vitre. Un rideau agit trop tard : la chaleur est déjà entrée.")
                    }
                }

                stepCard(
                    glyph: .stayClosed,
                    kicker: "Tant que dehors reste plus chaud",
                    kickerColor: .nadirHot,
                    title: "Restez fermé",
                    body: Text("Ouvrir ferait entrer un air ")
                        + Text("encore plus chaud").foregroundColor(.white)
                        + Text(" que le vôtre. Ça ne peut pas aider.")
                ) {
                    DisclosureRow(
                        title: "Et si j'étouffe ?",
                        verticalPadding: 9, borderColor: .nadirHairline
                    ) {
                        Text("Un ventilateur ne refroidit pas la pièce, mais il vous rafraîchit ")
                            + Text("vous").underline()
                            + Text(". Utilisez-le si vous en avez un.")
                    }
                }

                stepCard(
                    glyph: .reopen,
                    kicker: "Dès que dehors repasse à 2 °C plus frais",
                    kickerColor: .nadirCold,
                    title: "Rouvrez",
                    body: Text("C'est la même règle que le matin. Si vous hésitez, regardez ")
                        + Text("Aujourd'hui").foregroundColor(.white)
                        + Text(".")
                ) {
                    EmptyView()
                }

                openOrClose
                crossDraft
            }
            .padding(.bottom, 104)
        }
        .scrollIndicators(.hidden)
        .background(Color.black)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "Le mode d'emploi")
            SectionTitle(text: "Le geste", size: 44)
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
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
                        .font(.nadirSans(15))
                        .foregroundStyle(kickerColor)
                    Text(title.uppercased())
                        .font(.nadirSans(25, weight: .heavy))
                        .tracking(-0.75)
                        .foregroundStyle(.white)
                }
            }
            body
                .font(.nadirSans(15))
                .lineSpacing(3)
                .foregroundStyle(Color.nadirDim)
                .padding(.top, 14)
            detail()
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
    }

    private var openOrClose: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                SectionTitle(text: "Ouvrir,\nou fermer ?")
                Text("En dehors de ce cycle, deux questions suffisent avant d'ouvrir.")
                    .font(.nadirSans(15))
                    .lineSpacing(3)
                    .foregroundStyle(Color.nadirDim)
                    .padding(.top, 16)
                    .padding(.bottom, 22)
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
            .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
            .padding(.top, 8)

            VStack(spacing: 0) {
                ledgerRow(
                    number: "1",
                    title: "Fait-il plus frais dehors que chez vous ?",
                    detail: "Il faut au moins 2 °C de différence, sinon ouvrir ne change presque rien."
                )
                ledgerRow(
                    number: "2",
                    title: "L'air du dehors est-il sec ?",
                    detail: "Un air frais mais humide ne rafraîchit pas vraiment : il laisse juste une sensation collante."
                )
            }
            .overlay(alignment: .top) { Color.nadirLine2.frame(height: 1) }

            (
                Text("Deux ")
                    + Text("oui").foregroundColor(.white)
                    + Text(" : ouvrez. Sinon, attendez.")
            )
            .font(.nadirSans(15))
            .lineSpacing(3)
            .foregroundStyle(Color.nadirDim)
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }

    private func ledgerRow(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.nadirMono(13))
                .foregroundStyle(Color.nadirGo)
            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.nadirSans(16, weight: .semibold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.nadirSans(13))
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
            VStack(alignment: .leading, spacing: 0) {
                SectionTitle(text: "Un vrai\ncourant d'air")
                (
                    Text("Ouvrir une fenêtre laisse entrer un peu d'air. Le faire ")
                        + Text("circuler").foregroundColor(.white)
                        + Text(" en laisse entrer beaucoup plus.")
                )
                .font(.nadirSans(15))
                .lineSpacing(3)
                .foregroundStyle(Color.nadirDim)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
            .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
            .padding(.top, 24)

            VStack(spacing: 0) {
                adviceRow(
                    title: "Si vous avez deux façades",
                    body: Text("Ouvrez des deux côtés en même temps : l'air rentre d'un côté et ressort de l'autre. Un seul côté ? Ouvrez au moins une porte à l'intérieur.")
                )
                adviceRow(
                    title: "Si vous avez de la hauteur",
                    body: Text("Ouvrez en bas ")
                        + Text("et").foregroundColor(.white)
                        + Text(" en haut. L'air chaud sort par le haut, et ça aspire le frais par le bas.")
                )
                adviceRow(
                    title: "Si vous connaissez le vent",
                    body: Text("Repérez d'où il souffle, et ouvrez la fenêtre qui lui fait face.")
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    private func adviceRow(title: String, body: Text) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.nadirSans(17, weight: .bold))
                .tracking(-0.17)
                .foregroundStyle(.white)
            body
                .font(.nadirSans(15))
                .lineSpacing(3)
                .foregroundStyle(Color.nadirDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
    }
}
