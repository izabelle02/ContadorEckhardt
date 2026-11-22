/// Os layouts de widget disponíveis. Cada um corresponde a um widget nativo
/// (um `kind` do WidgetKit no iOS e um `AppWidgetProvider` no Android).
enum WidgetLayout {
  classic(
    title: 'Clássico',
    description: 'Emoji, número grande de dias e o nome do evento.',
    size: 'Pequeno (2×2)',
    iosKind: 'ClassicCountdownWidget',
    androidProvider: 'ClassicWidgetProvider',
  ),
  detailed(
    title: 'Detalhado',
    description: 'Dias + relógio ao vivo com horas, minutos e segundos.',
    size: 'Médio (4×2)',
    iosKind: 'DetailedCountdownWidget',
    androidProvider: 'DetailedWidgetProvider',
  ),
  progress(
    title: 'Progresso',
    description: 'Barra mostrando quanto do caminho até a data já passou.',
    size: 'Largo (4×1)',
    iosKind: 'ProgressCountdownWidget',
    androidProvider: 'ProgressWidgetProvider',
  ),
  list(
    title: 'Lista',
    description: 'Seus próximos eventos, todos num só widget.',
    size: 'Grande (4×3)',
    iosKind: 'ListCountdownWidget',
    androidProvider: 'ListWidgetProvider',
  ),
  minimal(
    title: 'Minimalista',
    description: 'Só o número — limpo e discreto.',
    size: 'Mini (1×1)',
    iosKind: 'MinimalCountdownWidget',
    androidProvider: 'MinimalWidgetProvider',
  ),
  lockScreen(
    title: 'Tela de bloqueio',
    description:
        'Circular, retangular ou em linha, acima do relógio. Exclusivo do iPhone (iOS 16+).',
    size: 'Acessório',
    iosKind: 'LockScreenCountdownWidget',
    androidProvider: null,
  );

  const WidgetLayout({
    required this.title,
    required this.description,
    required this.size,
    required this.iosKind,
    required this.androidProvider,
  });

  final String title;
  final String description;
  final String size;
  final String iosKind;

  /// `null` quando o layout não existe no Android.
  final String? androidProvider;

  bool get availableOnAndroid => androidProvider != null;
}
