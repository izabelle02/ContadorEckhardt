import 'package:flutter_test/flutter_test.dart';

import 'package:contador/models/countdown_event.dart';

void main() {
  final created = DateTime(2026, 1, 1);
  final target = DateTime(2026, 1, 11);
  final event = CountdownEvent(
    id: '1',
    title: 'Teste',
    emoji: '🎉',
    target: target,
    created: created,
    color: 0xFF6750A4,
  );

  test('JSON ida e volta preserva os campos', () {
    final copy = CountdownEvent.fromJson(event.toJson());
    expect(copy.id, event.id);
    expect(copy.title, event.title);
    expect(copy.target, event.target);
    expect(copy.created, event.created);
    expect(copy.color, event.color);
  });

  test('progresso vai de 0 a 1', () {
    expect(event.progress(created), 0);
    expect(event.progress(DateTime(2026, 1, 6)), closeTo(.5, .001));
    expect(event.progress(DateTime(2026, 2, 1)), 1);
  });

  test('partes da contagem', () {
    final p = CountdownParts.of(const Duration(days: 3, hours: 4, minutes: 5, seconds: 6));
    expect([p.days, p.hours, p.minutes, p.seconds], [3, 4, 5, 6]);
  });
}
