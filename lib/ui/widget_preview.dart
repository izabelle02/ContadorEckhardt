import 'package:flutter/material.dart';

import '../models/countdown_event.dart';
import '../models/widget_layout.dart';
import 'format.dart';

/// Reproduz no app a aparência de cada widget nativo, para o usuário
/// escolher o layout antes de adicioná-lo à tela inicial.
class WidgetPreview extends StatelessWidget {
  const WidgetPreview({
    super.key,
    required this.layout,
    required this.event,
    required this.now,
    this.allEvents = const [],
  });

  final WidgetLayout layout;
  final CountdownEvent event;
  final List<CountdownEvent> allEvents;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case WidgetLayout.classic:
        return _Tile(width: 160, height: 160, color: event.color, child: _classic());
      case WidgetLayout.detailed:
        return _Tile(width: 340, height: 160, color: event.color, child: _detailed());
      case WidgetLayout.progress:
        return _Tile(width: 340, height: 96, color: event.color, child: _progress());
      case WidgetLayout.list:
        return _Tile(width: 340, height: 230, color: 0xFF263238, child: _list());
      case WidgetLayout.minimal:
        return _Tile(width: 84, height: 84, color: event.color, radius: 20, child: _minimal());
      case WidgetLayout.lockScreen:
        return _lockScreen();
    }
  }

  static const _white = Colors.white;
  TextStyle _t(double size, {FontWeight w = FontWeight.w500, double alpha = 1}) =>
      TextStyle(color: _white.withValues(alpha: alpha), fontSize: size, fontWeight: w, height: 1.1);

  Widget _classic() {
    final h = headline(event, now);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(event.emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 4),
        Text(h.value, style: _t(44, w: FontWeight.w800)),
        Text(h.unit, style: _t(14, alpha: .85)),
        const SizedBox(height: 6),
        Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(13, w: FontWeight.w600)),
      ],
    );
  }

  Widget _detailed() {
    final p = CountdownParts.of(event.remaining(now));
    Widget box(String v, String label) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              Text(v, style: _t(26, w: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label, style: _t(11, alpha: .8)),
            ]),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(event.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(15, w: FontWeight.w700)),
          ),
        ]),
        const Spacer(),
        if (event.isPast(now))
          Center(child: Text('🎉 Chegou o dia!', style: _t(24, w: FontWeight.w800)))
        else
          Row(children: [
            box('${p.days}', p.days == 1 ? 'dia' : 'dias'),
            box(two(p.hours), 'horas'),
            box(two(p.minutes), 'min'),
            box(two(p.seconds), 'seg'),
          ]),
        const Spacer(),
        Text(formatTarget(event.target), style: _t(11, alpha: .8)),
      ],
    );
  }

  Widget _progress() {
    final pct = (event.progress(now) * 100).round();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(children: [
          Text(event.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(14, w: FontWeight.w700)),
          ),
          Text(shortLabel(event, now), style: _t(14, w: FontWeight.w800)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: event.progress(now),
            minHeight: 10,
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: .25),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('$pct% do caminho', style: _t(11, alpha: .85)),
        ),
      ],
    );
  }

  Widget _list() {
    final source = allEvents.isEmpty ? [event] : allEvents;
    final items = source.where((e) => !e.isPast(now)).take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Próximos eventos', style: _t(14, w: FontWeight.w700, alpha: .9)),
        const SizedBox(height: 8),
        if (items.isEmpty) Text('Nenhum evento futuro', style: _t(13, alpha: .7)),
        for (final e in items)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Color(e.color),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Text(e.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(13, w: FontWeight.w600)),
              ),
              Text(shortLabel(e, now), style: _t(13, w: FontWeight.w800)),
            ]),
          ),
      ],
    );
  }

  Widget _minimal() {
    final h = headline(event, now);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(child: Text(h.value, style: _t(30, w: FontWeight.w900))),
        Text(h.unit, style: _t(10, alpha: .85)),
      ],
    );
  }

  Widget _lockScreen() {
    final h = headline(event, now);
    final dim = Colors.white.withValues(alpha: .18);
    return Container(
      width: 340,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
        ),
      ),
      child: Column(children: [
        Text('${event.emoji} ${h.value} ${h.unit} · ${event.title}',
            maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(13, alpha: .9)),
        Text(formatTime(now), style: _t(56, w: FontWeight.w300)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: event.progress(now),
                strokeWidth: 5,
                color: Colors.white,
                backgroundColor: dim,
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(event.emoji, style: const TextStyle(fontSize: 12)),
                Text(h.value, style: _t(15, w: FontWeight.w800)),
              ]),
            ]),
          ),
          const SizedBox(width: 12),
          Container(
            width: 160,
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: dim, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${event.emoji} ${event.title}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(13, w: FontWeight.w700)),
                Text('${h.value} ${h.unit}', style: _t(15, w: FontWeight.w800)),
                Text(formatDate(event.target), maxLines: 1, style: _t(10, alpha: .75)),
              ],
            ),
          ),
        ]),
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.width,
    required this.height,
    required this.color,
    required this.child,
    this.radius = 24,
  });

  final double width;
  final double height;
  final int color;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Color(color);
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.lerp(base, Colors.black, .25)!],
        ),
        boxShadow: [
          BoxShadow(color: base.withValues(alpha: .35), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}
