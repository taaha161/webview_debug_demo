import 'dart:io';

import 'package:flutter/material.dart';
import '../models/demo_scenario.dart';
import 'demo_webview_screen.dart';

final List<DemoScenario> scenarios = [
  const DemoScenario(
    title: 'Console Logging',
    subtitle: 'Log messages, objects, tables & groups',
    devToolsTab: 'Console',
    description:
        'Open the Console tab in DevTools. Try each button and observe:\n'
        '- Different log levels (log, warn, error, info)\n'
        '- Object expansion and console.dir\n'
        '- Formatted tables with console.table\n'
        '- Grouped/nested logs with console.group\n'
        '- Stack traces with console.trace\n'
        '- Performance timing with console.time',
    assetPath: 'assets/html/console_logging.html',
    icon: Icons.terminal,
  ),
  const DemoScenario(
    title: 'Network Requests',
    subtitle: 'Inspect fetch, XHR, headers & timing',
    devToolsTab: 'Network',
    description:
        'Open the Network tab in DevTools. Try each button and observe:\n'
        '- Request/response headers and body\n'
        '- POST request payload inspection\n'
        '- 404 status codes on failed requests\n'
        '- Timing waterfall on the slow request\n'
        '- Parallel request waterfall view\n'
        '- XHR vs Fetch request types\n'
        '- Custom headers on requests',
    assetPath: 'assets/html/network_requests.html',
    icon: Icons.cloud_outlined,
  ),
  const DemoScenario(
    title: 'DOM Inspection',
    subtitle: 'Inspect elements, edit CSS live',
    devToolsTab: 'Elements',
    description:
        'Open the Elements tab in DevTools. Try:\n'
        '- Click the inspect cursor and tap elements\n'
        '- View and edit CSS properties live\n'
        '- Modify CSS variables on :root (--primary, --accent)\n'
        '- Check the box model for .profile-card\n'
        '- Toggle the animation on .pulse-dot\n'
        '- Edit text content directly in the DOM\n'
        '- Inspect the nested DOM structure',
    assetPath: 'assets/html/dom_inspection.html',
    icon: Icons.account_tree,
  ),
  const DemoScenario(
    title: 'JS Debugging',
    subtitle: 'Breakpoints, stepping, call stack',
    devToolsTab: 'Sources',
    description:
        'Open the Sources tab in DevTools. Try:\n'
        '- Find the page script and set breakpoints on marked lines\n'
        '- Run the Data Pipeline and step through functions\n'
        '- Use Step Over, Step Into, Step Out\n'
        '- Watch variables in the Scope panel\n'
        '- Run Fibonacci and inspect the call stack depth\n'
        '- Hit the debugger; button to trigger a pause\n'
        '- Run Closure Demo and inspect closure scope',
    assetPath: 'assets/html/js_debugging.html',
    icon: Icons.bug_report,
  ),
  const DemoScenario(
    title: 'Error Debugging',
    subtitle: 'Errors, stack traces, pause on exceptions',
    devToolsTab: 'Console',
    description:
        'Open the Console tab and enable "Pause on exceptions" in Sources. Try:\n'
        '- Trigger different error types and read stack traces\n'
        '- Compare caught vs uncaught errors\n'
        '- Watch unhandled promise rejections\n'
        '- Inspect custom error properties (code, timestamp)\n'
        '- Follow the error chain through nested functions\n'
        '- See errors in both the in-page log and DevTools',
    assetPath: 'assets/html/error_debugging.html',
    icon: Icons.error_outline,
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView Debug Demo'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildSetupBanner(context),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: scenarios.length,
              itemBuilder: (context, index) {
                final scenario = scenarios[index];
                return _ScenarioCard(scenario: scenario);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupBanner(BuildContext context) {
    final isAndroid = Platform.isAndroid;
    final instruction = isAndroid
        ? 'Connect device via USB, then open chrome://inspect/#devices in Chrome'
        : 'Open Safari > Develop > [Your Device] to connect';
    final icon = isAndroid ? Icons.adb : Icons.apple;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final DemoScenario scenario;

  const _ScenarioCard({required this.scenario});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DemoWebViewScreen(scenario: scenario),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  scenario.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          scenario.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            scenario.devToolsTab,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scenario.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
