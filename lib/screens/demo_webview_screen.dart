import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../models/demo_scenario.dart';

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
      ..loadFlutterAsset(widget.scenario.assetPath);

    // Enable inspection on iOS 16.4+
    if (_controller.platform is WebKitWebViewController) {
      (_controller.platform as WebKitWebViewController).setInspectable(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scenario.title),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text(
                widget.scenario.devToolsTab,
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Collapsible instruction panel
          ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text(
              'What to look for',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  widget.scenario.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          // WebView
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _controller.reload(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reload'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _controller.runJavaScript(
                    "if (document.getElementById('output')) document.getElementById('output').textContent = 'Cleared.';"
                    "if (document.getElementById('error-log')) document.getElementById('error-log').innerHTML = '<span style=\"color: #888;\">Cleared.</span>';",
                  ),
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear Output'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
