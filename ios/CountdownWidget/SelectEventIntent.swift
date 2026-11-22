import AppIntents
import WidgetKit

/// Evento exibido na tela "Editar widget" do iOS.
struct EventEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Evento" }
    static var defaultQuery: EventQuery { EventQuery() }

    let id: String
    let title: String
    let emoji: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(emoji) \(title)")
    }

    init(_ event: CountdownEvent) {
        id = event.id
        title = event.title
        emoji = event.emoji
    }
}

struct EventQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [EventEntity] {
        EventStore.loadEvents().filter { identifiers.contains($0.id) }.map(EventEntity.init)
    }

    func suggestedEntities() async throws -> [EventEntity] {
        let now = Date()
        let events = EventStore.loadEvents()
        let upcoming = EventStore.upcoming(events, now: now)
        let past = events.filter { $0.target <= now }
        return (upcoming + past).map(EventEntity.init)
    }

    func defaultResult() async -> EventEntity? {
        EventStore.resolve(id: nil, in: EventStore.loadEvents(), now: Date()).map(EventEntity.init)
    }
}

/// Configuração de cada instância de widget: qual evento mostrar.
struct SelectEventIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Escolher evento" }
    static var description: IntentDescription { "Escolha qual contagem regressiva este widget exibe." }

    @Parameter(title: "Evento")
    var event: EventEntity?

    init() {}
}
