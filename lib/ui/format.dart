import 'package:intl/intl.dart';

import '../models/countdown_event.dart';

/// Valor principal + unidade exibidos nos widgets.
/// Mesma regra usada no Kotlin (`Countdown.headline`) e no Swift.
({String value, String unit}) headline(CountdownEvent e, DateTime now) {
  final r = e.remaining(now);
  if (r <= Duration.zero) return (value: '🎉', unit: 'Chegou!');
  if (r.inDays >= 1) {
    return (value: '${r.inDays}', unit: r.inDays == 1 ? 'dia' : 'dias');
  }
  if (r.inHours >= 1) {
    return (value: '${r.inHours}', unit: r.inHours == 1 ? 'hora' : 'horas');
  }
  final m = r.inMinutes < 1 ? 1 : r.inMinutes;
  return (value: '$m', unit: 'min');
}

String shortLabel(CountdownEvent e, DateTime now) {
  final h = headline(e, now);
  return e.isPast(now) ? 'Chegou!' : '${h.value} ${h.unit}';
}

String two(int n) => n.toString().padLeft(2, '0');

String formatTarget(DateTime d) =>
    DateFormat("EEE, d 'de' MMM 'de' y • HH:mm", 'pt_BR').format(d);

String formatDate(DateTime d) =>
    DateFormat("d 'de' MMMM 'de' y", 'pt_BR').format(d);

String formatTime(DateTime d) => DateFormat('HH:mm', 'pt_BR').format(d);
