import 'package:flutter/material.dart';

import '../models/countdown_event.dart';
import '../models/widget_layout.dart';
import '../services/event_repository.dart';
import '../ui/format.dart';
import '../ui/palette.dart';
import '../ui/widget_preview.dart';

class EditEventScreen extends StatefulWidget {
  const EditEventScreen({super.key, this.event});

  /// `null` para criar um evento novo.
  final CountdownEvent? event;

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late String _emoji;
  late DateTime _target;
  late int _color;
  bool _saving = false;

  bool get _isNew => widget.event == null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    final tomorrow = DateTime.now().add(const Duration(days: 30));
    _title = TextEditingController(text: e?.title ?? '');
    _emoji = e?.emoji ?? eventEmojis.first;
    _target = e?.target ?? DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
    _color = e?.color ?? eventColors.first;
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  CountdownEvent get _draft {
    final base = widget.event;
    final title = _title.text.trim().isEmpty ? 'Meu evento' : _title.text.trim();
    if (base != null) {
      return base.copyWith(title: title, emoji: _emoji, target: _target, color: _color);
    }
    return CountdownEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      emoji: _emoji,
      target: _target,
      created: DateTime.now(),
      color: _color,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _target,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 50),
    );
    if (picked != null) {
      setState(() => _target = DateTime(
          picked.year, picked.month, picked.day, _target.hour, _target.minute));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_target),
    );
    if (picked != null) {
      setState(() => _target = DateTime(
          _target.year, _target.month, _target.day, picked.hour, picked.minute));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    var event = _draft;
    // Se a data mudou e o "início" ficou depois dela, reinicia o progresso.
    if (!event.created.isBefore(event.target)) {
      event = event.copyWith(created: DateTime.now());
    }
    await EventRepository.instance.upsert(event);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await EventRepository.instance.delete(widget.event!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Novo evento' : 'Editar evento'),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: WidgetPreview(
                layout: WidgetLayout.classic,
                event: _draft,
                now: DateTime.now(),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'Nome do evento',
                hintText: 'Ex.: Férias na praia',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Dê um nome ao evento' : null,
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: _PickerTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Data',
                  value: formatDate(_target),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerTile(
                  icon: Icons.schedule,
                  label: 'Hora',
                  value: formatTime(_target),
                  onTap: _pickTime,
                ),
              ),
            ]),
            const SizedBox(height: 24),
            Text('Emoji', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final category in emojiCategories.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(category.key,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant)),
              ),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final e in category.value)
                    InkWell(
                      onTap: () => setState(() => _emoji = e),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: e == _emoji ? scheme.primaryContainer : null,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: e == _emoji ? scheme.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Text('Cor do widget', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in eventColors)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c == _color ? scheme.onSurface : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: c == _color
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: const Text('Salvar'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
