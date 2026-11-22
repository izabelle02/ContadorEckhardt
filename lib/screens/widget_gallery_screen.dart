import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/countdown_event.dart';
import '../models/widget_layout.dart';
import '../services/event_repository.dart';
import '../ui/widget_preview.dart';

/// Mostra todos os layouts de widget com o evento escolhido e explica
/// (ou faz, no Android) a adição à tela inicial / de bloqueio.
class WidgetGalleryScreen extends StatefulWidget {
  const WidgetGalleryScreen({super.key});

  @override
  State<WidgetGalleryScreen> createState() => _WidgetGalleryScreenState();
}

class _WidgetGalleryScreenState extends State<WidgetGalleryScreen> {
  final _repo = EventRepository.instance;
  String? _selectedId;
  bool _canPin = false;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    _repo.canPinWidgets().then((v) {
      if (mounted) setState(() => _canPin = v);
    });
  }

  CountdownEvent _sample() {
    final now = DateTime.now();
    return CountdownEvent(
      id: 'sample',
      title: 'Férias',
      emoji: '🏖️',
      target: now.add(const Duration(days: 42, hours: 5, minutes: 17)),
      created: now.subtract(const Duration(days: 60)),
      color: 0xFF1E6FD9,
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = _repo.events;
    final selected = (_selectedId == null ? null : _repo.byId(_selectedId!)) ??
        (events.isNotEmpty ? events.first : _sample());
    final layouts = WidgetLayout.values
        .where((l) => !_isAndroid || l.availableOnAndroid)
        .toList();
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Escolha seu widget')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (events.length > 1)
            DropdownButtonFormField<String>(
              value: selected.id,
              decoration: const InputDecoration(
                labelText: 'Pré-visualizar com',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final e in events)
                  DropdownMenuItem(value: e.id, child: Text('${e.emoji}  ${e.title}')),
              ],
              onChanged: (id) => setState(() => _selectedId = id),
            ),
          if (events.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Exemplo'),
                subtitle: Text('Crie um evento para ver seus próprios dados aqui.'),
              ),
            ),
          const SizedBox(height: 8),
          for (final layout in layouts) ...[
            const SizedBox(height: 20),
            Text(layout.title, style: Theme.of(context).textTheme.titleLarge),
            Text('${layout.size} • ${layout.description}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Center(
              child: FittedBox(
                child: WidgetPreview(
                  layout: layout,
                  event: selected,
                  allEvents: events,
                  now: now,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_canPin && layout.availableOnAndroid)
              OutlinedButton.icon(
                onPressed: () => _repo.requestPin(layout),
                icon: const Icon(Icons.add_to_home_screen),
                label: const Text('Adicionar à tela inicial'),
              ),
          ],
          const SizedBox(height: 32),
          _HowToCard(isAndroid: _isAndroid),
        ],
      ),
    );
  }
}

class _HowToCard extends StatelessWidget {
  const _HowToCard({required this.isAndroid});

  final bool isAndroid;

  @override
  Widget build(BuildContext context) {
    final steps = isAndroid
        ? const [
            'Toque e segure num espaço vazio da tela inicial.',
            'Escolha "Widgets" e procure por "Contador".',
            'Arraste o layout que preferir para a tela.',
            'Escolha qual evento o widget vai mostrar.',
            'Para trocar o evento depois, toque e segure o widget → "Reconfigurar".',
          ]
        : const [
            'Tela inicial: toque e segure num espaço vazio, toque em "Editar" → "Adicionar widget" e procure "Contador".',
            'Tela de bloqueio: toque e segure a tela bloqueada → "Personalizar" → "Tela Bloqueada" → toque na área de widgets.',
            'Depois de adicionar, toque e segure o widget → "Editar widget" para escolher o evento.',
          ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Como adicionar', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${i + 1}. ${steps[i]}'),
              ),
          ],
        ),
      ),
    );
  }
}
