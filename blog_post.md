# Debugging Flutter WebViews with Browser DevTools: A Complete Guide

If your Flutter app uses WebViews, you've probably hit a wall where something goes wrong inside the web content and you have no idea why. A network request silently fails, JavaScript throws an error you can't see, or the layout looks broken and you're left guessing.

The good news: you can use the same browser developer tools you already know -- Chrome DevTools on Android and Safari Web Inspector on iOS -- to debug WebView content inside your Flutter app. Full console, network inspection, DOM editing, breakpoints, and all.

This post walks through the complete setup, the common gotchas that trip people up (especially on iOS), and a demo app you can use to try every debugging technique hands-on.

---

## The Demo App

We built a Flutter app with five interactive scenarios, each designed to exercise a specific DevTools tab:

| Scenario | DevTools Tab | What It Demonstrates |
|---|---|---|
| Console Logging | Console | `console.log`, `warn`, `error`, `table`, `group`, `trace` |
| Network Requests | Network | `fetch`, `XMLHttpRequest`, headers, timing, error states |
| DOM Inspection | Elements | Element selection, live CSS editing, CSS variables, animations |
| JS Debugging | Sources | Breakpoints, step-through, call stack, closures, `debugger;` |
| Error Debugging | Console | Error types, stack traces, caught vs uncaught, promise rejections |

The full source code is available in the companion repository. For the rest of this post, we'll reference specific code from the app as we walk through each setup step and debugging technique.

---

## Prerequisites

- Flutter SDK 3.18+
- A physical Android device or emulator (for Chrome DevTools)
- A physical iOS device or simulator + a Mac with Safari (for Safari Web Inspector)
- The `webview_flutter` package (official, maintained by the Flutter team)

---

## Step 1: Project Setup

### Add the dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  webview_flutter: ^4.10.0
  webview_flutter_android: ^4.3.0
  webview_flutter_wkwebview: ^3.16.0
```

Run `flutter pub get` to install.

The main `webview_flutter` package provides the cross-platform API. The two platform packages (`webview_flutter_android` and `webview_flutter_wkwebview`) are needed to access platform-specific features like enabling debugging and setting WebViews as inspectable. The platform packages are already transitive dependencies of `webview_flutter`, but adding them as direct dependencies gives you access to their platform-specific classes.

---

## Step 2: Platform Configuration

### Android: Internet Permission

WebViews that make network requests need the `INTERNET` permission. Add it to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        ...
```

This goes **before** the `<application>` tag.

### iOS: App Transport Security

By default, iOS blocks HTTP (non-HTTPS) requests from WebViews. If your web content needs to reach HTTP endpoints, add this to `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <true/>
</dict>
```

> **Note:** For production apps, you should use more specific ATS exceptions rather than allowing all arbitrary loads. This blanket setting is appropriate for development and demo purposes.

---

## Step 3: Enable WebView Debugging in Code

This is the critical step that most tutorials gloss over. There are **two separate mechanisms**, one for each platform, and both are accessed through the platform-specific packages.

### Android: `AndroidWebViewController.enableDebugging`

On Android, WebView debugging is a **global, static setting**. You call it once, typically in `main()`, and it applies to every WebView in your app:

```dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (WebViewPlatform.instance is AndroidWebViewPlatform) {
    AndroidWebViewController.enableDebugging(true);
  }

  runApp(const MainApp());
}
```

Key points:
- This maps to Android's native `WebView.setWebContentsDebuggingEnabled(true)`
- The platform check (`is AndroidWebViewPlatform`) ensures it only runs on Android
- You must call this **before** any WebView is created
- It affects **all** WebViews in the app, not just one

### iOS: `setInspectable` per WebView

iOS works differently. Starting with **iOS 16.4**, Apple changed the default behavior: WebViews are **no longer inspectable** unless you explicitly opt in. This is a per-WebView setting, not a global one.

After creating your `WebViewController`, cast the platform controller and call `setInspectable`:

```dart
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

// Create the controller with platform-specific params
late final PlatformWebViewControllerCreationParams params;
if (WebViewPlatform.instance is WebKitWebViewPlatform) {
  params = WebKitWebViewControllerCreationParams(
    allowsInlineMediaPlayback: true,
  );
} else {
  params = const PlatformWebViewControllerCreationParams();
}

final controller = WebViewController.fromPlatformCreationParams(params);

// Enable inspection on iOS 16.4+
if (controller.platform is WebKitWebViewController) {
  (controller.platform as WebKitWebViewController).setInspectable(true);
}
```

This is the single most common reason people report "Safari Web Inspector can't see my WebView." Before iOS 16.4, inspection was always enabled in debug builds. After iOS 16.4, you must call `setInspectable(true)` on **each individual WebView instance**.

> **On iOS simulators**, WebViews are always inspectable regardless of this flag. So you might think everything is working in the simulator, then get confused when it breaks on a real device. Always test inspection on a physical device.

---

## Step 4: Connect DevTools

### Android: Chrome DevTools

1. **Enable USB Debugging** on your Android device:
   - Go to **Settings > About phone**
   - Tap **Build number** 7 times to enable Developer Options
   - Go to **Settings > Developer options**
   - Enable **USB debugging**

2. **Connect your device** via USB to your development machine

3. When prompted on the device, tap **Allow** to authorize USB debugging from your computer

4. **Run your Flutter app**:
   ```bash
   flutter run
   ```

5. **Open Chrome** on your development machine and navigate to:
   ```
   chrome://inspect/#devices
   ```

6. Ensure **"Discover USB devices"** is checked

7. Your device should appear in the list, with each WebView shown under it. Click **"inspect"** next to the WebView you want to debug.

A full Chrome DevTools window opens, connected to your WebView. You now have access to Console, Network, Elements, Sources, and everything else.

> **Emulator note:** `chrome://inspect` works with emulators too, but the connection can be flaky. For reliable demos, use a physical device.

### iOS: Safari Web Inspector

Safari Web Inspector requires a **Mac** -- there is no Windows or Linux equivalent.

1. **Enable Web Inspector on your iOS device**:
   - Go to **Settings > Safari > Advanced**
   - Toggle **Web Inspector** ON

   > This setting is easy to miss. It's not under the main Safari settings -- you need to scroll to the bottom and tap **Advanced**.

2. **Enable the Develop menu in Safari on your Mac**:
   - Open **Safari > Settings** (or press `Cmd + ,`)
   - Go to the **Advanced** tab
   - Check **"Show features for web developers"**

   This adds a **Develop** menu to Safari's menu bar.

3. **Connect your iOS device** via USB to your Mac (or use the same Wi-Fi network for wireless debugging)

4. **Run your Flutter app** on the iOS device:
   ```bash
   flutter run
   ```

5. In Safari on your Mac, go to **Develop > [Your Device Name]**. You should see your app and its WebView listed. Click on it to open Web Inspector.

> **If your device doesn't appear in the Develop menu:**
> - Make sure the device is unlocked
> - Try disconnecting and reconnecting USB
> - Restart Safari
> - Confirm `setInspectable(true)` was called on your WebViewController (iOS 16.4+)
> - Confirm Web Inspector is enabled in device Settings

---

## Step 5: Debugging in Practice

Now that DevTools is connected, let's walk through what you can actually do. Each section corresponds to a scenario in our demo app.

### Console Logging

**DevTools tab: Console**

The Console tab captures all JavaScript `console.*` calls from your WebView. This is your first stop for understanding what's happening inside the web content.

Our demo provides buttons that exercise every console method:

```javascript
// Basic log levels -- each gets a different icon/color in DevTools
console.log('Standard message');
console.warn('This will show a yellow warning icon');
console.error('This shows red with a stack trace');
console.info('Informational message');

// Structured data
console.table([
    { name: 'Alice', role: 'Engineer', level: 'Senior' },
    { name: 'Bob', role: 'Designer', level: 'Mid' },
]);

// Grouped output for readability
console.group('API Request Lifecycle');
console.log('1. Request initiated');
console.log('2. Headers set');
console.groupEnd();

// Performance measurement
console.time('Heavy Operation');
// ... do work ...
console.timeEnd('Heavy Operation');

// Stack traces
console.trace('How did we get here?');
```

**What to try in DevTools:**
- Filter by log level (click the icons next to "Default levels")
- Click on logged objects to expand and inspect them
- Use `console.table` output -- it renders as an actual sortable table
- Right-click a log entry and select "Store as global variable" to interact with it in the Console

### Network Requests

**DevTools tab: Network**

The Network tab shows every HTTP request the WebView makes, with full request/response details.

Our demo fires various types of requests:

```javascript
// Simple GET -- inspect response body and headers
await fetch('https://jsonplaceholder.typicode.com/posts/1');

// POST with payload -- inspect the request body
await fetch('https://jsonplaceholder.typicode.com/posts', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        title: 'Debug Demo Post',
        body: 'Created from WebView debug demo.',
        userId: 1
    })
});

// Slow request -- watch the timing bar in the waterfall
await fetch('https://httpbin.org/delay/3');

// Parallel requests -- see the waterfall visualization
await Promise.all([
    fetch('https://jsonplaceholder.typicode.com/posts/1'),
    fetch('https://jsonplaceholder.typicode.com/posts/2'),
    fetch('https://jsonplaceholder.typicode.com/users/1'),
    fetch('https://jsonplaceholder.typicode.com/comments/1'),
    fetch('https://jsonplaceholder.typicode.com/todos/1'),
]);
```

**What to try in DevTools:**
- Click any request to see its **Headers**, **Payload**, **Response**, and **Timing** tabs
- The **Waterfall** column shows how long each request took and whether they overlapped
- Filter requests by type (Fetch, XHR, JS, CSS, etc.)
- Right-click a request and select **"Copy as cURL"** to replay it in your terminal
- Throttle the connection (Network tab > throttle dropdown) to simulate slow networks

### DOM Inspection

**DevTools tab: Elements**

The Elements tab lets you inspect and live-edit the DOM and CSS of your WebView content. This is especially useful when debugging layout issues in hybrid apps.

Our demo includes a rich layout with multiple CSS techniques:

```html
<!-- CSS custom properties on :root for easy live editing -->
<style>
    :root {
        --primary: #2196F3;
        --accent: #9C27B0;
        --radius: 12px;
    }
    .profile-card {
        background: var(--card-bg);
        border-radius: var(--radius);
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    .pulse-dot {
        animation: pulse 2s ease-in-out infinite;
    }
</style>

<!-- Rich DOM structure for inspection practice -->
<div class="profile-card" id="profile">
    <div class="avatar">JD</div>
    <div class="profile-info">
        <h3>Jane Developer</h3>
        <span class="role">Senior Engineer</span>
    </div>
</div>
```

**What to try in DevTools:**
- Click the **inspect cursor** (top-left icon) and tap any element on the WebView to jump to it in the DOM tree
- Edit CSS properties in the **Styles** panel -- changes apply instantly
- Change CSS variables on `:root` to restyle the entire page (try changing `--primary` to `#E91E63`)
- Check the **Box Model** diagram to understand padding, margin, and border
- Toggle the CSS animation on `.pulse-dot` by unchecking the `animation` property
- Double-click text content in the Elements panel to edit it inline
- Check **Computed** tab to see the final resolved values for any property

### JavaScript Debugging

**DevTools tab: Sources**

The Sources tab is your full JavaScript debugger -- breakpoints, step-through execution, variable inspection, and call stack analysis.

Our demo includes a data processing pipeline with clearly-marked breakpoint targets:

```javascript
function fetchData() {
    // BREAKPOINT HERE: inspect the raw data
    const rawData = [
        { id: 1, name: 'Widget A', price: 29.99, category: 'electronics', inStock: true },
        // ...
    ];
    return rawData;
}

function transformData(data) {
    // BREAKPOINT HERE: watch the transformation
    const transformed = data.map(item => ({
        ...item,
        displayName: item.name.toUpperCase(),
        priceFormatted: '$' + item.price.toFixed(2),
    }));
    return transformed;
}

function filterData(data) {
    // BREAKPOINT HERE: see what gets filtered
    const filtered = data.filter(item => {
        const isInStock = item.inStock === true;
        const isAffordable = item.price < 50;
        return isInStock && isAffordable;
    });
    return filtered;
}
```

**What to try in DevTools:**
1. In the **Sources** tab, find the page's script (it may appear under `demo.local`)
2. Click a line number to set a breakpoint (a blue marker appears)
3. Press **"Run Data Pipeline"** in the WebView
4. Execution pauses at your breakpoint. Now you can:
   - **Step Over** (F10) to execute the current line and move to the next
   - **Step Into** (F11) to enter a function call
   - **Step Out** (Shift+F11) to return from the current function
   - Hover over variables to see their current values
   - Check the **Scope** panel on the right to see all local and closure variables
   - Check the **Call Stack** panel to see the function call chain

The demo also includes a `debugger;` statement behind a button:

```javascript
function triggerDebugger() {
    const secret = 'You found the hidden value!';
    const counter = 42;
    const data = { message: secret, count: counter };
    debugger;  // Execution pauses here when DevTools is open
}
```

When you click the button with DevTools open, execution pauses immediately and you can inspect all variables in scope.

**Bonus -- Fibonacci for call stack depth:**
Set a breakpoint inside the `fibonacci()` function and run it. The recursive calls create a deep call stack visible in the Call Stack panel, which is great for understanding how recursive functions execute.

### Error Debugging

**DevTools tab: Console (with Sources "Pause on exceptions")**

The Console tab shows JavaScript errors with their full stack traces. Combined with the "Pause on exceptions" feature in Sources, you can freeze execution at the exact moment an error occurs.

Our demo triggers various error types:

```javascript
// Each of these creates a different error in DevTools
function throwReferenceError() {
    console.log(undefinedVariable);  // ReferenceError
}

function throwTypeError() {
    const obj = null;
    obj.toString();  // TypeError
}

function throwSyntaxError() {
    eval('function {');  // SyntaxError
}

// Async errors
function throwPromiseRejection() {
    Promise.reject(new Error('Async operation failed: timeout after 30s'));
}

// Caught vs uncaught -- compare behavior in DevTools
function caughtError() {
    try {
        const data = JSON.parse('{ invalid json }');
    } catch (error) {
        console.error('Caught error:', error);
    }
}
```

**What to try in DevTools:**
- Enable **"Pause on exceptions"** (the pause icon in the Sources tab) -- execution will freeze at the exact line where an error is thrown
- Toggle **"Pause on caught exceptions"** as well to catch errors inside try/catch blocks
- Click on stack trace entries to jump to the source location
- Compare how caught and uncaught errors appear differently in the Console
- Watch for **unhandled promise rejections** -- these show up with a distinct icon

---

## The WebView Screen: Bringing It Together

Here's how the demo app's WebView screen is structured. Each scenario uses the same screen with different HTML content:

```dart
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class DemoWebViewScreen extends StatefulWidget {
  final DemoScenario scenario;
  const DemoWebViewScreen({super.key, required this.scenario});

  @override
  State<DemoWebViewScreen> createState() => _DemoWebViewScreenState();
}

class _DemoWebViewScreenState extends State<DemoWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // Use platform-specific params for iOS
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(
        widget.scenario.htmlContent,
        baseUrl: 'https://demo.local/',
      );

    // Enable inspection on iOS 16.4+
    if (_controller.platform is WebKitWebViewController) {
      (_controller.platform as WebKitWebViewController).setInspectable(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.scenario.title)),
      body: Column(
        children: [
          // Instruction panel for presenters
          ExpansionTile(
            initiallyExpanded: true,
            title: const Text('What to look for'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(widget.scenario.description),
              ),
            ],
          ),
          const Divider(height: 1),
          // The WebView
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
```

A few things worth noting:

- **`WebViewController.fromPlatformCreationParams`** -- On iOS, we pass `WebKitWebViewControllerCreationParams` to configure WebKit-specific behavior. On Android, we use the default params. This pattern lets you write platform-adaptive code cleanly.
- **`setInspectable(true)`** -- This is what makes the WebView visible to Safari Web Inspector on iOS 16.4+. Without it, the WebView simply won't appear in the Develop menu. You access this through the platform-specific `WebKitWebViewController`.
- **`setJavaScriptMode(JavaScriptMode.unrestricted)`** -- Enables JavaScript execution in the WebView. Without this, none of the demo interactions would work.
- **`loadHtmlString` with `baseUrl`** -- When loading HTML inline, the page's origin is `about:blank` by default. Setting a `baseUrl` gives the page a proper origin so network requests from JavaScript don't hit CORS issues.
- **`WebViewWidget(controller: _controller)`** -- The widget is a thin wrapper that renders whatever the controller has loaded. The controller holds all the configuration and state.

---

## Common Gotchas and Troubleshooting

### "My WebView doesn't appear in chrome://inspect"

1. Verify `AndroidWebViewController.enableDebugging(true)` is called in `main()` **before** the WebView loads
2. Check USB debugging is enabled on the device
3. Try a different USB cable -- charging-only cables don't support debugging
4. Change USB mode from "Charging" to "File Transfer" on the device
5. Refresh `chrome://inspect` and make sure "Discover USB devices" is checked

### "Safari Develop menu shows my device but no WebView"

This is almost always the `setInspectable` issue on iOS 16.4+:

1. Make sure you're calling `setInspectable(true)` on the `WebKitWebViewController`:
   ```dart
   if (_controller.platform is WebKitWebViewController) {
     (_controller.platform as WebKitWebViewController).setInspectable(true);
   }
   ```
2. Make sure Web Inspector is enabled on the device: **Settings > Safari > Advanced > Web Inspector**
3. Rebuild and re-run the app -- hot reload doesn't apply setting changes
4. Remember: simulators always work without this flag, so test on a **real device**

### "Network requests from my WebView fail with CORS errors"

When HTML is loaded via `loadHtmlString`, the page origin is `about:blank`, which can trigger CORS restrictions. Pass a `baseUrl`:

```dart
controller.loadHtmlString(
  htmlContent,
  baseUrl: 'https://demo.local/',
);
```

### "The debugger; statement doesn't pause execution"

`debugger;` only pauses if DevTools is open and attached **before** the statement is hit. If DevTools isn't connected, the statement is silently ignored. Connect DevTools first, then trigger the action.

### "I can't see my WebView's source in the Sources tab"

The page loaded via `loadHtmlString` may appear under the `baseUrl` domain you set (e.g., `demo.local`). Look in the page tree under that domain. If you don't set a `baseUrl`, it appears under `about:blank`, which can be harder to find.

---

## Quick Reference: Setup Checklist

### Android
- [ ] `INTERNET` permission in `AndroidManifest.xml`
- [ ] `AndroidWebViewController.enableDebugging(true)` called in `main()`
- [ ] USB debugging enabled on device
- [ ] Device connected via USB (data cable, not charging-only)
- [ ] `chrome://inspect/#devices` open in Chrome with "Discover USB devices" checked

### iOS
- [ ] `NSAppTransportSecurity` configured in `Info.plist` (if hitting HTTP endpoints)
- [ ] `setInspectable(true)` called on `WebKitWebViewController` (required for iOS 16.4+)
- [ ] **Web Inspector** enabled on device: Settings > Safari > Advanced > Web Inspector
- [ ] **"Show features for web developers"** enabled in Safari > Settings > Advanced on your Mac
- [ ] Device connected via USB to Mac
- [ ] Safari > Develop > [Device Name] > select the WebView

---

## Wrapping Up

Debugging WebView content in Flutter doesn't require special tools or complex setups -- it's the same Chrome DevTools and Safari Web Inspector you use for regular web development. The key steps are:

1. Use `webview_flutter` with the platform-specific packages for debugging control
2. Enable debugging in code: `AndroidWebViewController.enableDebugging(true)` on Android, `setInspectable(true)` on iOS
3. Configure the device settings: USB debugging on Android, Web Inspector on iOS
4. Connect via `chrome://inspect` or Safari's Develop menu

The demo app in this post gives you a hands-on playground for every major DevTools feature. Clone it, run it on a device, connect DevTools, and start inspecting.

If you've been treating WebViews as black boxes in your Flutter apps, this is your way in.
