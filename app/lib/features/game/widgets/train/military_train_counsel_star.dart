import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

/// Counsel star on a Train Military unit row (Refs #4307 Slice C).
class MilitaryTrainCounselStar extends StatelessWidget {
  const MilitaryTrainCounselStar({
    super.key,
    required this.briefMessage,
    required this.semanticLabel,
    required this.onOpenCounsel,
  });

  final String briefMessage;
  final String semanticLabel;
  final VoidCallback onOpenCounsel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Tooltip(
        message: briefMessage,
        child: InkWell(
          key: const ValueKey<String>('military_train_counsel_star'),
          onTap: onOpenCounsel,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              '★',
              style: TextStyle(
                fontSize: 14,
                height: 1,
                color: EditorialMonoclePalette.accentBright,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
