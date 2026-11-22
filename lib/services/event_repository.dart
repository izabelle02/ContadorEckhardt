import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/countdown_event.dart';
import '../models/widget_layout.dart';

/// Guarda os eventos e mantém os widgets nativos atualizados.
///
/// Os eventos ficam em um único JSON salvo via `home_widget`, que no iOS usa
/// o App Group compartilhado e no Android as SharedPreferences do plugin —
/// os mesmos lugares de onde os widgets leem.
class EventRepository extends ChangeNotifier {
  EventRepository._();

  static final EventRepository instance = EventRepository._();

  /// Precisa ser igual ao App Group configurado no Xcode (app e extensão).
  static const appGroupId = 'group.com.eckhardt.contador';
  static const androidPackage = 'com.eckhardt.contador';
  static const storageKey = 'events_json';

  List<CountdownEvent> _events = [];

  /// Eventos futuros primeiro (mais próximos no topo), depois os passados.
  List<CountdownEvent> get events {
    final now = DateTime.now();
    final upcoming = _events.where((e) => !e.isPast(now)).toList()
      ..sort((a, b) => a.target.compareTo(b.target));
    final past = _events.where((e) => e.isPast(now)).toList()
      ..sort((a, b) => b.target.compareTo(a.target));
    return List.unmodifiable([...upcoming, ...past]);
  }

  bool get _isIOS => !kIsWeb && Platform.isIOS;
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  Future<void> init() async {
    if (_isIOS) await HomeWidget.setAppGroupId(appGroupId);
    try {
      final raw = await HomeWidget.getWidgetData<String>(storageKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _events = list
            .map((e) => CountdownEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Falha ao carregar eventos: $e');
    }
    // Garante que os widgets reflitam o estado atual ao abrir o app.
    await refreshWidgets();
  }

  CountdownEvent? byId(String id) {
    for (final e in _events) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<void> upsert(CountdownEvent event) async {
    final i = _events.indexWhere((e) => e.id == event.id);
    if (i >= 0) {
      _events[i] = event;
    } else {
      _events.add(event);
    }
    await _persist();
  }

  Future<void> delete(String id) async {
    _events.removeWhere((e) => e.id == id);
    await _persist();
  }

  Future<void> _persist() async {
    notifyListeners();
    await HomeWidget.saveWidgetData<String>(
      storageKey,
      jsonEncode(_events.map((e) => e.toJson()).toList()),
    );
    await refreshWidgets();
  }

  /// Pede para todos os widgets se redesenharem com os dados novos.
  Future<void> refreshWidgets() async {
    for (final layout in WidgetLayout.values) {
      try {
        if (_isIOS) {
          await HomeWidget.updateWidget(iOSName: layout.iosKind);
        } else if (_isAndroid && layout.androidProvider != null) {
          await HomeWidget.updateWidget(
            qualifiedAndroidName:
                '$androidPackage.widgets.${layout.androidProvider}',
          );
        }
      } catch (e) {
        debugPrint('Falha ao atualizar ${layout.name}: $e');
      }
    }
  }

  /// No Android 8+ é possível pedir ao launcher para fixar o widget direto.
  Future<bool> canPinWidgets() async {
    if (!_isAndroid) return false;
    try {
      return await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestPin(WidgetLayout layout) async {
    final provider = layout.androidProvider;
    if (!_isAndroid || provider == null) return;
    await HomeWidget.requestPinWidget(
      qualifiedAndroidName: '$androidPackage.widgets.$provider',
    );
  }
}
