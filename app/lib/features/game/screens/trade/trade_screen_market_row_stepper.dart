// Compact quantity stepper chrome for Market tab commodity rows.
// Split from `trade_screen_market_row.dart` to keep each trade-screen
// part under the repo file-size target (Refs #3878).

/// Compact stepper button used by [MarketCommodityRowControls]. Uses
/// an `InkWell` so the chrome stays in the editorial-monocle palette
/// (no Material elevated buttons or accent splash colours).
library;


import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

class StepperButton extends StatelessWidget {
  const StepperButton({super.key, 
    required this.buttonKey,
    required this.glyph,
    required this.semanticLabel,
    required this.onPressed,
  });

  final Key buttonKey;
  final String glyph;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle glyphStyle =
        (theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14))
            .copyWith(
              color: onPressed == null
                  ? EditorialMonoclePalette.muted
                  : EditorialMonoclePalette.accent,
            );
    final Color borderColor = onPressed == null
        ? EditorialMonoclePalette.muted
        : EditorialMonoclePalette.accent;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: InkWell(
        key: buttonKey,
        onTap: onPressed,
        child: Container(
          width: 28,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: EditorialMonoclePalette.surface.withValues(alpha: 0.5),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(glyph, style: glyphStyle),
        ),
      ),
    );
  }
}
