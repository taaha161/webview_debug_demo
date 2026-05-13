# webview_debug_demo

Companion Flutter app for the Very Good Ventures blog post: [How to Use Browser Dev Tools with Flutter WebViews](https://verygood.ventures/blog/how-to-use-browser-dev-tools-with-flutter-webviews/).

Five interactive WebView scenarios for practicing Chrome DevTools (Android) and Safari Web Inspector (iOS) debugging end-to-end.

## Scenarios

| Scenario | DevTools Tab | What it exercises |
|---|---|---|
| Console Logging | Console | `console.log`, `warn`, `error`, `table`, `group`, `trace` |
| Network Requests | Network | `fetch`, `XMLHttpRequest`, headers, timing, error states |
| DOM Inspection | Elements | Element selection, live CSS editing, CSS variables, animations |
| JS Debugging | Sources | Breakpoints, step-through, call stack, closures, `debugger;` |
| Error Debugging | Console / Sources | Error types, stack traces, caught vs uncaught, promise rejections |

## Requirements

- Flutter SDK `^3.11.0` (Dart 3)
- Android device/emulator for Chrome DevTools
- iOS device/simulator + Mac with Safari for Web Inspector
- Physical iOS device required to verify `setInspectable` (simulators always inspect)

## Run

```bash
flutter pub get
flutter run
```

## Project Layout

```
lib/
  main.dart                       # enables AndroidWebViewController.enableDebugging
  screens/
    home_screen.dart              # scenario picker
    demo_webview_screen.dart      # WebView host, calls setInspectable on iOS
  models/                         # scenario metadata
assets/html/                      # one HTML file per scenario
  console_logging.html
  network_requests.html
  dom_inspection.html
  js_debugging.html
  error_debugging.html
```

## Key Debug Hooks

**Android** — global flag, call once in `main()`:
```dart
if (WebViewPlatform.instance is AndroidWebViewPlatform) {
  AndroidWebViewController.enableDebugging(true);
}
```

**iOS 16.4+** — per-WebView, call on each controller:
```dart
if (_controller.platform is WebKitWebViewController) {
  (_controller.platform as WebKitWebViewController).setInspectable(true);
}
```

## Connect DevTools

- **Android**: enable USB debugging on device → `chrome://inspect/#devices` → click `inspect` next to the WebView.
- **iOS**: enable Settings → Safari → Advanced → Web Inspector on device, and Show features for web developers in Safari on Mac → Develop menu → [Device] → select WebView.

Full setup, gotchas, and troubleshooting in the [blog post](https://verygood.ventures/blog/how-to-use-browser-dev-tools-with-flutter-webviews/).
