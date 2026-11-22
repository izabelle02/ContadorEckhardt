import SwiftUI
import WidgetKit

struct CountdownEntry: TimelineEntry {
    let date: Date
    /// Evento do widget (nil = nenhum evento criado ainda).
    let event: CountdownEvent?
    /// Próximos eventos (usado pelo widget de Lista).
    let upcoming: [CountdownEvent]

    static var placeholder: CountdownEntry {
        CountdownEntry(date: Date(), event: .sample, upcoming: [.sample])
    }
}

/// Gera entradas exatamente nos momentos em que o número exibido muda
/// (virada de dia/hora/minuto). Os relógios ao vivo usam `Text(timerInterval:)`
/// e `ProgressView(timerInterval:)`, que o sistema anima sozinho.
enum TimelineFactory {
    static func make(
        events: [CountdownEvent],
        pick: ([CountdownEvent], Date) -> CountdownEvent?
    ) -> Timeline<CountdownEntry> {
        var entries: [CountdownEntry] = []
        var date = Date()

        for _ in 0..<12 {
            let event = pick(events, date)
            let upcoming = Array(EventStore.upcoming(events, now: date).prefix(6))
            entries.append(CountdownEntry(date: date, event: event, upcoming: upcoming))

            let watched = upcoming.isEmpty ? [event].compactMap { $0 } : upcoming
            guard let next = watched.compactMap({ Countdown.nextChange($0.remaining(from: date)) }).min()
            else { break }
            date = date.addingTimeInterval(max(next, 1) + 1)
        }

        if entries.count == 1 {
            // Nada mais muda: confere de novo em 6 horas.
            return Timeline(entries: entries, policy: .after(Date().addingTimeInterval(6 * 3_600)))
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

/// Provider para widgets em que o usuário escolhe o evento.
struct SelectableProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry { .placeholder }

    func snapshot(for configuration: SelectEventIntent, in context: Context) async -> CountdownEntry {
        let events = EventStore.loadEvents()
        if events.isEmpty { return .placeholder } // galeria de widgets
        let now = Date()
        return CountdownEntry(
            date: now,
            event: EventStore.resolve(id: configuration.event?.id, in: events, now: now),
            upcoming: EventStore.upcoming(events, now: now)
        )
    }

    func timeline(for configuration: SelectEventIntent, in context: Context) async -> Timeline<CountdownEntry> {
        let selected = configuration.event?.id
        return TimelineFactory.make(events: EventStore.loadEvents()) { events, date in
            EventStore.resolve(id: selected, in: events, now: date)
        }
    }
}

/// Provider para o widget de Lista (sem configuração).
struct ListProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        let events = EventStore.loadEvents()
        let now = Date()
        completion(events.isEmpty
            ? .placeholder
            : CountdownEntry(date: now, event: nil, upcoming: EventStore.upcoming(events, now: now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        completion(TimelineFactory.make(events: EventStore.loadEvents()) { _, _ in nil })
    }
}
