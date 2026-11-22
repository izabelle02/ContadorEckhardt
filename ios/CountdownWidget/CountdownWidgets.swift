import SwiftUI
import WidgetKit

// MARK: - Bundle

@main
struct CountdownWidgetBundle: WidgetBundle {
    var body: some Widget {
        ClassicCountdownWidget()
        DetailedCountdownWidget()
        ProgressCountdownWidget()
        ListCountdownWidget()
        MinimalCountdownWidget()
        LockScreenCountdownWidget()
    }
}

// Os `kind` abaixo precisam bater com `WidgetLayout.iosKind` no Dart.

struct ClassicCountdownWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "ClassicCountdownWidget", intent: SelectEventIntent.self,
                               provider: SelectableProvider()) { entry in
            ClassicView(entry: entry).eventBackground(entry.event)
        }
        .configurationDisplayName("Clássico")
        .description("Emoji, número grande de dias e o nome do evento.")
        .supportedFamilies([.systemSmall])
    }
}

struct DetailedCountdownWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "DetailedCountdownWidget", intent: SelectEventIntent.self,
                               provider: SelectableProvider()) { entry in
            DetailedView(entry: entry).eventBackground(entry.event)
        }
        .configurationDisplayName("Detalhado")
        .description("Dias e relógio ao vivo com horas, minutos e segundos.")
        .supportedFamilies([.systemMedium])
    }
}

struct ProgressCountdownWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "ProgressCountdownWidget", intent: SelectEventIntent.self,
                               provider: SelectableProvider()) { entry in
            ProgressCountdownView(entry: entry).eventBackground(entry.event)
        }
        .configurationDisplayName("Progresso")
        .description("Barra com quanto do caminho até a data já passou.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ListCountdownWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ListCountdownWidget", provider: ListProvider()) { entry in
            ListCountdownView(entry: entry)
                .containerBackground(for: .widget) { Color(argb: 0xFF263238) }
        }
        .configurationDisplayName("Lista")
        .description("Seus próximos eventos em um só widget.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct MinimalCountdownWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "MinimalCountdownWidget", intent: SelectEventIntent.self,
                               provider: SelectableProvider()) { entry in
            MinimalView(entry: entry).eventBackground(entry.event)
        }
        .configurationDisplayName("Minimalista")
        .description("Só o número, limpo e discreto.")
        .supportedFamilies([.systemSmall])
    }
}

struct LockScreenCountdownWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "LockScreenCountdownWidget", intent: SelectEventIntent.self,
                               provider: SelectableProvider()) { entry in
            LockScreenView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Tela de bloqueio")
        .description("Contagem regressiva acima do relógio.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Helpers

private extension View {
    func eventBackground(_ event: CountdownEvent?) -> some View {
        let base = event?.color ?? Color(argb: 0xFF455A64)
        return containerBackground(for: .widget) {
            LinearGradient(colors: [base, base.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .background(Color.black)
        }
        .foregroundStyle(.white)
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("⏳").font(.title)
            Text("Crie um evento no app")
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
        }
    }
}

/// Texto "hh:mm:ss" que conta sozinho até o fim do dia corrente da contagem.
private struct LiveClock: View {
    let event: CountdownEvent
    let now: Date

    var body: some View {
        let remaining = event.remaining(from: now)
        let sub = remaining.truncatingRemainder(dividingBy: Countdown.day)
        Text(timerInterval: now...now.addingTimeInterval(max(sub, 0)), countsDown: true)
            .monospacedDigit()
    }
}

// MARK: - Views

struct ClassicView: View {
    let entry: CountdownEntry

    var body: some View {
        if let e = entry.event {
            let h = Countdown.headline(e.remaining(from: entry.date))
            VStack(spacing: 2) {
                Text(e.emoji).font(.title2)
                Text(h.value)
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(h.unit).font(.subheadline).opacity(0.85)
                Text(e.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .padding(.top, 2)
            }
        } else {
            EmptyStateView()
        }
    }
}

struct MinimalView: View {
    let entry: CountdownEntry

    var body: some View {
        if let e = entry.event {
            let h = Countdown.headline(e.remaining(from: entry.date))
            VStack(spacing: 0) {
                Text(h.value)
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                Text(h.unit).font(.headline).opacity(0.85)
            }
        } else {
            EmptyStateView()
        }
    }
}

struct DetailedView: View {
    let entry: CountdownEntry

    var body: some View {
        if let e = entry.event {
            let remaining = e.remaining(from: entry.date)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(e.emoji)
                    Text(e.title).font(.headline).lineLimit(1)
                }
                Spacer(minLength: 0)
                if remaining <= 0 {
                    Text("🎉 Chegou o dia!")
                        .font(.title.weight(.heavy))
                        .frame(maxWidth: .infinity)
                } else {
                    let days = Int(remaining / Countdown.day)
                    HStack(spacing: 8) {
                        chip {
                            Text("\(days)").font(.system(size: 30, weight: .heavy, design: .rounded))
                            Text(days == 1 ? "dia" : "dias").font(.caption2).opacity(0.8)
                        }
                        .frame(width: 80)
                        chip {
                            LiveClock(event: e, now: entry.date)
                                .font(.system(size: 30, weight: .heavy, design: .rounded))
                                .multilineTextAlignment(.center)
                            Text("horas · min · seg").font(.caption2).opacity(0.8)
                        }
                    }
                }
                Spacer(minLength: 0)
                Text(e.target.formattedTarget).font(.caption2).opacity(0.8)
            }
        } else {
            EmptyStateView()
        }
    }

    private func chip<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 2, content: content)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ProgressCountdownView: View {
    let entry: CountdownEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let e = entry.event {
            let remaining = e.remaining(from: entry.date)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(e.emoji)
                    Text(e.title).font(.headline).lineLimit(1)
                    Spacer(minLength: 4)
                    if family != .systemSmall {
                        Text(Countdown.shortLabel(remaining)).font(.headline.weight(.heavy))
                    }
                }
                if family == .systemSmall {
                    Spacer(minLength: 0)
                    Text(Countdown.shortLabel(remaining))
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .minimumScaleFactor(0.5)
                }
                Spacer(minLength: 0)
                // Anima sozinha até a data-alvo.
                if e.created < e.target, remaining > 0 {
                    ProgressView(timerInterval: e.created...e.target, countsDown: false) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                    .tint(.white)
                } else {
                    ProgressView(value: 1).tint(.white)
                }
                Text("\(Int(e.progress(at: entry.date) * 100))% do caminho")
                    .font(.caption2)
                    .opacity(0.85)
            }
        } else {
            EmptyStateView()
        }
    }
}

struct ListCountdownView: View {
    let entry: CountdownEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let limit = family == .systemLarge ? 6 : 3
        let items = Array(entry.upcoming.prefix(limit))
        VStack(alignment: .leading, spacing: 6) {
            Text("Próximos eventos")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white.opacity(0.9))
            if items.isEmpty {
                Spacer()
                Text("Crie um evento no app")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(items) { e in
                    HStack {
                        Text(e.emoji)
                        Text(e.title).font(.caption.weight(.semibold)).lineLimit(1)
                        Spacer(minLength: 4)
                        Text(Countdown.shortLabel(e.remaining(from: entry.date)))
                            .font(.caption.weight(.heavy))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(maxHeight: .infinity)
                    .background(e.color, in: RoundedRectangle(cornerRadius: 10))
                }
                if items.count < limit { Spacer(minLength: 0) }
            }
        }
    }
}

struct LockScreenView: View {
    let entry: CountdownEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let e = entry.event {
            let remaining = e.remaining(from: entry.date)
            let h = Countdown.headline(remaining)
            switch family {
            case .accessoryCircular:
                Gauge(value: e.progress(at: entry.date)) {
                    Text(e.emoji)
                } currentValueLabel: {
                    Text(h.value).minimumScaleFactor(0.5)
                }
                .gaugeStyle(.accessoryCircular)
                .widgetAccentable()

            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(e.emoji) \(e.title)")
                        .font(.headline)
                        .lineLimit(1)
                        .widgetAccentable()
                    Text(remaining > 0 ? "\(h.value) \(h.unit)" : "Chegou!")
                        .font(.title3.weight(.bold))
                    Text(e.target.formattedDay)
                        .font(.caption2)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            default: // .accessoryInline
                Text("\(e.emoji) \(Countdown.shortLabel(remaining)) · \(e.title)")
            }
        } else {
            switch family {
            case .accessoryInline: Text("⏳ Crie um evento")
            default: Text("⏳")
            }
        }
    }
}
