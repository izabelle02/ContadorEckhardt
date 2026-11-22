/// Um evento com data-alvo para a contagem regressiva.
///
/// O formato JSON deste modelo é lido também pelos widgets nativos
/// (Kotlin no Android e Swift no iOS) — mantenha os nomes dos campos
/// sincronizados com `EventStore.kt` e `SharedEvents.swift`.
class CountdownEvent {
  const CountdownEvent({
    required this.id,
    required this.title,
    required this.emoji,
    required this.target,
    required this.created,
    required this.color,
  });

  final String id;
  final String title;
  final String emoji;
  final DateTime target;

  /// Quando a contagem começou — usado na barra de progresso.
  final DateTime created;

  /// Cor ARGB (ex.: 0xFF6750A4).
  final int color;

  factory CountdownEvent.fromJson(Map<String, dynamic> json) {
    final target =
        DateTime.fromMillisecondsSinceEpoch((json['target'] as num).toInt());
    return CountdownEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      emoji: (json['emoji'] as String?) ?? '⏳',
      target: target,
      created: json['created'] == null
          ? target.subtract(const Duration(days: 30))
          : DateTime.fromMillisecondsSinceEpoch(
              (json['created'] as num).toInt()),
      color: (json['color'] as num?)?.toInt() ?? 0xFF6750A4,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'target': target.millisecondsSinceEpoch,
        'created': created.millisecondsSinceEpoch,
        'color': color,
      };

  CountdownEvent copyWith({
    String? title,
    String? emoji,
    DateTime? target,
    DateTime? created,
    int? color,
  }) =>
      CountdownEvent(
        id: id,
        title: title ?? this.title,
        emoji: emoji ?? this.emoji,
        target: target ?? this.target,
        created: created ?? this.created,
        color: color ?? this.color,
      );

  Duration remaining(DateTime now) => target.difference(now);

  bool isPast(DateTime now) => !target.isAfter(now);

  /// Fração do tempo já percorrido entre [created] e [target] (0..1).
  double progress(DateTime now) {
    final total = target.difference(created).inMilliseconds;
    if (total <= 0) return 1;
    final elapsed = now.difference(created).inMilliseconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}

/// Dias, horas, minutos e segundos de uma duração.
class CountdownParts {
  const CountdownParts(this.days, this.hours, this.minutes, this.seconds);

  factory CountdownParts.of(Duration d) {
    if (d.isNegative) return const CountdownParts(0, 0, 0, 0);
    return CountdownParts(
      d.inDays,
      d.inHours.remainder(24),
      d.inMinutes.remainder(60),
      d.inSeconds.remainder(60),
    );
  }

  final int days;
  final int hours;
  final int minutes;
  final int seconds;
}
