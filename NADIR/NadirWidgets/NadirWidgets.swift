import SwiftUI
import WidgetKit

@main
struct NadirWidgetBundle: WidgetBundle {
    var body: some Widget {
        NadirChartWidget()
    }
}

/// La courbe dehors / chez vous en continu : une entrée de timeline par
/// heure fait avancer la fenêtre de 30 h avec l'horloge — la courbe du
/// widget reste exactement celle de l'app.
struct NadirChartWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NadirChart", provider: NadirTimelineProvider()) { entry in
            NadirWidgetView(entry: entry)
                .containerBackground(Color.black, for: .widget)
        }
        .configurationDisplayName("NADIR")
        .description("La courbe dehors / chez vous et le créneau d'ouverture, actualisés toutes les heures.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NadirEntry: TimelineEntry {
    let date: Date
    let analysis: ThermalAnalysis
    let alarmOnOpen: Bool
    let alarmOnClose: Bool
}

struct NadirTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> NadirEntry {
        entry(at: .now, series: .demo(), profile: UserProfile())
    }

    func getSnapshot(in context: Context, completion: @escaping (NadirEntry) -> Void) {
        completion(entry(
            at: .now,
            series: SharedStore.loadSeries() ?? .demo(),
            profile: UserProfile.load()
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NadirEntry>) -> Void) {
        Task {
            let profile = UserProfile.load()
            let series = await SeriesProvider.current(profile: profile)

            // Une entrée maintenant, puis à chaque heure pile sur 12 h.
            var dates = [Date.now]
            let calendar = Calendar.current
            var next = calendar.dateInterval(of: .hour, for: .now)?.end
                ?? Date.now.addingTimeInterval(3600)
            for _ in 0 ..< 12 {
                dates.append(next)
                next = next.addingTimeInterval(3600)
            }
            let entries = dates.map { entry(at: $0, series: series, profile: profile) }
            completion(Timeline(entries: entries, policy: .atEnd))
        }
    }

    private func entry(at date: Date, series: WeatherSeries, profile: UserProfile) -> NadirEntry {
        NadirEntry(
            date: date,
            analysis: ThermalAnalysis(
                series: series.window(from: date),
                indoorNow: profile.indoorNow,
                inertia: profile.inertia,
                ventilation: profile.ventilation,
                exposure: profile.exposure
            ),
            alarmOnOpen: profile.alarmOnOpen,
            alarmOnClose: profile.alarmOnClose
        )
    }
}
