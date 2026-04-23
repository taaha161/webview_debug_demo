import 'package:flutter/material.dart';

class DemoScenario {
  final String title;
  final String subtitle;
  final String devToolsTab;
  final String description;
  final String assetPath;
  final IconData icon;

  const DemoScenario({
    required this.title,
    required this.subtitle,
    required this.devToolsTab,
    required this.description,
    required this.assetPath,
    required this.icon,
  });
}
