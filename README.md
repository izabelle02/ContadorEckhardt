# Contador — widgets de contagem regressiva

App para **Android e iPhone** que mostra, na **tela inicial** e na **tela de bloqueio**,
quanto tempo falta para uma data ou evento. Cada evento tem nome, emoji, data/hora e cor,
e o usuário escolhe entre **6 layouts de widget**.

| Layout | Tamanho | Android | iPhone |
|---|---|:-:|:-:|
| **Clássico** — emoji, número grande de dias, nome | 2×2 / pequeno | ✅ | ✅ |
| **Detalhado** — dias + relógio ao vivo hh:mm:ss | 4×2 / médio | ✅ | ✅ |
| **Progresso** — barra do caminho até a data | 4×1 / pequeno e médio | ✅ | ✅ |
| **Lista** — próximos eventos num só widget | 4×3 / médio e grande | ✅ | ✅ |
| **Minimalista** — só o número | 1×1 / pequeno | ✅ | ✅ |
| **Tela de bloqueio** — circular, retangular, em linha | acessório | — ¹ | ✅ (iOS 16+) |

¹ O Android não tem widgets de tela de bloqueio em celulares (o recurso foi removido no Android 5;
o Android 16 só os trouxe de volta para tablets).

Cada widget que você adiciona pode mostrar um evento diferente: o Android pergunta qual evento
ao adicionar (e permite "Reconfigurar" depois); no iPhone, segure o widget e toque em **Editar widget**.

## Como funciona

```
┌────────────── App Flutter (lib/) ──────────────┐
│ telas: lista, editor, galeria de widgets       │
│ EventRepository → salva JSON "events_json"     │
└───────────────┬────────────────────────────────┘
                │ pacote home_widget
      ┌─────────┴──────────┐
      ▼                    ▼
 Android                iOS
 SharedPreferences      App Group (UserDefaults)
      │                    │
 AppWidgetProvider     WidgetKit + SwiftUI
 (Kotlin, RemoteViews) (AppIntent p/ escolher evento)
```

- **`lib/`** — app Flutter (um código para as duas plataformas).
- **`android/app/src/main/kotlin/.../widgets/`** — os 5 widgets Android, a tela de escolha de
  evento e as regras de atualização. Layouts em `res/layout/widget_*.xml`.
- **`ios/CountdownWidget/`** — a extensão de widgets do iOS (SwiftUI).

Os widgets se atualizam sozinhos exatamente quando o número muda (virada do dia/hora/minuto).
Os relógios "ao vivo" usam recursos nativos que contam sem gastar bateria
(`Chronometer` no Android, `Text(timerInterval:)` e `ProgressView(timerInterval:)` no iOS).

## Montando o projeto

Pré-requisitos: [Flutter](https://docs.flutter.dev/get-started/install) **3.27 ou mais novo**,
Android Studio (para Android) e um Mac com **Xcode 15+** (para iPhone).

### 1. Gerar os arquivos de plataforma que faltam

Este repositório traz só o código próprio do app. Gere o resto (Gradle, projeto Xcode, ícones)
com o comando abaixo, na raiz do projeto. Ele **não sobrescreve** os arquivos que já existem:

```bash
flutter create --org com.eckhardt --project-name contador --platforms android,ios .
```

```bash
flutter pub get
```

### 2. Android

Em `android/app/build.gradle.kts` (ou `build.gradle`), confira se o `minSdk` é **24 ou mais**
(necessário para o relógio regressivo do widget Detalhado):

```kotlin
minSdk = 24
```

Depois é só rodar:

```bash
flutter run
```

Para adicionar: segure a tela inicial → **Widgets** → **Contador**. No app, a tela
**Widgets** (ícone no topo) também tem o botão **Adicionar à tela inicial**.

### 3. iPhone (feito uma vez no Xcode)

1. Abra `ios/Runner.xcworkspace` no Xcode.
2. **File → New → Target… → Widget Extension**. Nome: `CountdownWidget`.
   Desmarque *Include Live Activity* e *Include Control*; *Include Configuration App Intent*
   pode ficar desmarcado. Quando perguntar sobre ativar o scheme, clique em **Cancel**.
3. O Xcode cria a pasta `ios/CountdownWidget/` com arquivos de exemplo. **Apague os arquivos
   `.swift` de exemplo** que ele criou e adicione ao target `CountdownWidget` os 4 arquivos deste
   repositório: `SharedEvents.swift`, `SelectEventIntent.swift`, `Providers.swift` e
   `CountdownWidgets.swift` (botão direito na pasta → *Add Files to "Runner"…* → marque só o
   target **CountdownWidget**). Se o Xcode tiver sobrescrito algum deles, restaure com
   `git checkout ios/CountdownWidget`.
4. No target **CountdownWidget** → *General*: **Minimum Deployments = iOS 17.0**.
5. **App Group** — em *Signing & Capabilities*, clique **+ Capability → App Groups** e adicione
   `group.com.eckhardt.contador`. Faça isso **nos dois targets**: `Runner` e `CountdownWidget`.
   (Se trocar esse nome, troque também em `lib/services/event_repository.dart` e
   `ios/CountdownWidget/SharedEvents.swift`.)
6. No target **Runner** → *Build Phases*: se a fase **Embed Foundation Extensions** aparecer
   abaixo de **Thin Binary**, arraste-a para cima dela (evita o erro *"Cycle inside Runner"*).
7. Rode pelo Flutter:

   ```bash
   flutter run
   ```

Para adicionar: **tela inicial** → segure → **Editar → Adicionar widget → Contador**.
**Tela de bloqueio** → segure a tela bloqueada → **Personalizar → Tela Bloqueada** → toque na área
de widgets → **Contador**.

## Testes

```bash
flutter test
```

## Personalizando

- **Cores e emojis** disponíveis: `lib/ui/palette.dart`.
- **Texto exibido** ("42 dias", "5 horas", "Chegou!"): a mesma regra está em
  `lib/ui/format.dart`, `widgets/EventStore.kt` (`Countdown`) e `SharedEvents.swift` (`Countdown`)
  — se mudar uma, mude as três.
- **Novo layout**: adicione no enum `WidgetLayout` (Dart), crie o provider + XML no Android e uma
  `Widget` no `CountdownWidgetBundle` do iOS.
