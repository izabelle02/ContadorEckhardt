import 'dart:async';

import 'package:flutter/material.dart';

import '../models/countdown_event.dart';
import '../services/event_repository.dart';
import '../ui/format.dart';
import 'edit_event_screen.dart';
import 'widget_gallery_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = EventRepository.instance;
  late Timer _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  Future<void> _openEditor([CountdownEvent? event]) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => EditEventScreen(event: event)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contagem regressiva'),
        actions: [
          IconButton(
            tooltip: 'Widgets',
            icon: const Icon(Icons.widgets_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WidgetGalleryScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Novo evento'),
      ),
      body: ListenableBuilder(
        listenable: _repo,
        builder: (context, _) {
          final events = _repo.events;
          if (events.isEmpty) return _EmptyState(onCreate: _openEditor);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final e = events[i];
              return Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.delete_outline),
                ),
                confirmDismiss: (_) => _confirmDelete(context, e),
                onDismissed: (_) => _repo.delete(e.id),
                child: _EventCard(
                  event: e,
                  now: _now,
                  onTap: () => _openEditor(e),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, CountdownEvent e) =>
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Excluir evento?'),
          content: Text('"${e.title}" será removido, inclusive dos widgets.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        ),
      );
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.now, required this.onTap});

  final CountdownEvent event;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final base = Color(event.color);
    final past = event.isPast(now);
    final p = CountdownParts.of(event.remaining(now));
    const white = TextStyle(color: Colors.white);

    Widget unit(String v, String label) => Column(children: [
          Text(v,
              style: white.copyWith(fontSize: 26, fontWeight: FontWeight.w800)),
          Text(label,
              style: white.copyWith(
                  fontSize: 11, color: Colors.white.withValues(alpha: .8))),
        ]);

    return Material(
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [base, Color.lerp(base, Colors.black, .3)!],
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(event.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: white.copyWith(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(formatTarget(event.target),
                          style: white.copyWith(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: .8))),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              if (past)
                Text('🎉 Chegou o dia!',
                    style: white.copyWith(
                        fontSize: 24, fontWeight: FontWeight.w800))
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    unit('${p.days}', p.days == 1 ? 'dia' : 'dias'),
                    unit(two(p.hours), 'horas'),
                    unit(two(p.minutes), 'min'),
                    unit(two(p.seconds), 'seg'),
                  ],
                ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: event.progress(now),
                  minHeight: 6,
                  color: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: .25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('⏳', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Nenhuma contagem ainda',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Crie um evento — aniversário, viagem, casamento — e coloque um '
            'widget na tela inicial ou de bloqueio.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Criar evento'),
          ),
        ]),
      ),
    );
  }
}
