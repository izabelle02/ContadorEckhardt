import Foundation
import SwiftUI

/// Precisa ser igual a `EventRepository.appGroupId` no Dart e ao App Group
/// marcado em "Signing & Capabilities" do Runner e da extensão.
let appGroupId = "group.com.eckhardt.contador"
private let eventsKey = "events_json"

/// Espelho do modelo `CountdownEvent` do Dart.
struct CountdownEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let emoji: String
    let target: Date
    let created: Date
    let colorValue: Int64

    var color: Color { Color(argb: colorValue) }

    func remaining(from now: Date) -> TimeInterval { target.timeIntervalSince(now) }

    func progress(at now: Date) -> Double {
        let total = target.timeIntervalSince(created)
        guard total > 0 else { return 1 }
        return min(max(now.timeIntervalSince(created) / total, 0), 1)
    }

    static let sample = CountdownEvent(
        id: "sample",
        title: "Férias",
        emoji: "🏖️",
        target: Date().addingTimeInterval(42 * 86_400 + 5 * 3_600),
        created: Date().addingTimeInterval(-60 * 86_400),
        colorValue: 0xFF1E6FD9
    )
}

private struct RawEvent: Decodable {
    let id: String
    let title: String
    let emoji: String?
    let target: Double
    let created: Double?
    let color: Int64?
}

enum EventStore {
    static func loadEvents() -> [CountdownEvent] {
        guard
            let raw = UserDefaults(suiteName: appGroupId)?.string(forKey: eventsKey),
            let data = raw.data(using: .utf8),
            let list = try? JSONDecoder().decode([RawEvent].self, from: data)
        else { return [] }

        return list.map { r in
            let target = Date(timeIntervalSince1970: r.target / 1000)
            return CountdownEvent(
                id: r.id,
                title: r.title,
                emoji: r.emoji ?? "⏳",
                target: target,
                created: r.created.map { Date(timeIntervalSince1970: $0 / 1000) }
                    ?? target.addingTimeInterval(-30 * 86_400),
                colorValue: r.color ?? 0xFF6750A4
            )
        }
    }

    static func upcoming(_ events: [CountdownEvent], now: Date) -> [CountdownEvent] {
        events.filter { $0.target > now }.sorted { $0.target < $1.target }
    }

    /// Evento escolhido; se não existir mais, o próximo a acontecer.
    static func resolve(id: String?, in events: [CountdownEvent], now: Date) -> CountdownEvent? {
        if let id, let match = events.first(where: { $0.id == id }) { return match }
        return upcoming(events, now: now).first ?? events.max { $0.target < $1.target }
    }
}

/// Regras de exibição — as mesmas de `lib/ui/format.dart` e `Countdown.kt`.
enum Countdown {
    static let minute: TimeInterval = 60
    static let hour: TimeInterval = 3_600
    static let day: TimeInterval = 86_400

    static func headline(_ remaining: TimeInterval) -> (value: String, unit: String) {
        if remaining <= 0 { return ("🎉", "Chegou!") }
        if remaining >= day {
            let d = Int(remaining / day)
            return ("\(d)", d == 1 ? "dia" : "dias")
        }
        if remaining >= hour {
            let h = Int(remaining / hour)
            return ("\(h)", h == 1 ? "hora" : "horas")
        }
        return ("\(max(1, Int(remaining / minute)))", "min")
    }

    static func shortLabel(_ remaining: TimeInterval) -> String {
        if remaining <= 0 { return "Chegou!" }
        let h = headline(remaining)
        return "\(h.value) \(h.unit)"
    }

    /// Em quantos segundos o número exibido muda (nil se já passou).
    static func nextChange(_ remaining: TimeInterval) -> TimeInterval? {
        if remaining <= 0 { return nil }
        if remaining >= day { return remaining.truncatingRemainder(dividingBy: day) }
        if remaining >= hour { return remaining.truncatingRemainder(dividingBy: hour) }
        return remaining.truncatingRemainder(dividingBy: minute)
    }
}

extension Color {
    init(argb: Int64) {
        self.init(
            .sRGB,
            red: Double((argb >> 16) & 0xFF) / 255,
            green: Double((argb >> 8) & 0xFF) / 255,
            blue: Double(argb & 0xFF) / 255,
            opacity: Double((argb >> 24) & 0xFF) / 255
        )
    }
}

extension Date {
    var formattedTarget: String {
        formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year().hour().minute()
            .locale(Locale(identifier: "pt_BR")))
    }

    var formattedDay: String {
        formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "pt_BR")))
    }
}
