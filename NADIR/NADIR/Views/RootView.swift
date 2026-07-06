import Combine
import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            if model.showOnboarding {
                OnboardingView()
            } else {
                content
                TabBarView()
            }
        }
        .preferredColorScheme(.dark)
        .task { await model.start() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.refreshNow() }
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            model.refreshNow()
        }
    }

    private var content: some View {
        ZStack {
            switch model.tab {
            case .today: TodayView().transition(.opacity)
            case .guide: GuideView().transition(.opacity)
            case .learn: LearnView().transition(.opacity)
            case .about: AboutView().transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.18), value: model.tab)
    }
}

/// Barre d'onglets du design : icônes filaires, libellés mono en capitales,
/// fond noir translucide flouté.
struct TabBarView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.today, glyph: .today, label: "Aujourd'hui")
            tabButton(.guide, glyph: .guide, label: "Le geste")
            tabButton(.learn, glyph: .learn, label: "Comprendre")
            tabButton(.about, glyph: .about, label: "À propos")
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Color.black.opacity(0.72)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
    }

    private func tabButton(_ tab: AppModel.Tab, glyph: TabIcon.Glyph, label: String) -> some View {
        Button {
            model.tab = tab
        } label: {
            VStack(spacing: 6) {
                TabIcon(glyph: glyph)
                Text(label.uppercased())
                    .font(.nadirMono(10))
                    .tracking(0.4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(model.tab == tab ? Color.white : Color.nadirFaint)
        .animation(.easeOut(duration: 0.15), value: model.tab)
    }
}
