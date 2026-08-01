import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

/// End-of-campaign banner (military win or calendar halt) above Victory sections.
class VictoryEndStateBanner extends StatelessWidget {
  const VictoryEndStateBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorialMonoclePalette.surface,
          border: Border.all(color: EditorialMonoclePalette.accentDim),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: EditorialMonoclePalette.accentBright,
            ),
          ),
        ),
      ),
    );
  }
}
