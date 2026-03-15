import 'package:flutter/material.dart';

import 'ct_panel.dart';

/// Full-screen pixel-art shell: background + framed content area + title bar.
/// Replaces visible use of Scaffold/AppBar in user-facing screens.
class CtScreenShell extends StatelessWidget {
  const CtScreenShell({
    super.key,
    required this.title,
    required this.child,
    this.showBackButton = false,
  });

  final String title;
  final Widget child;
  final bool showBackButton;

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                  child: Row(
                    children: [
                      if (showBackButton)
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(
                            Icons.arrow_back,
                            color: theme.colorScheme.onPrimary,
                            size: 20,
                          ),
                        )
                      else
                        const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 20),
                    ],
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
