import 'package:flutter/material.dart';

import 'ct_panel.dart';

/// Full-screen pixel-art shell: background + framed content area.
class CtScreenShell extends StatelessWidget {
  const CtScreenShell({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: CtPanel(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

