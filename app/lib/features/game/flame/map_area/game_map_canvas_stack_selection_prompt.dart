import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../widgets/chrome/ct_nine_patch_button.dart';
import 'game_map_canvas_stack.dart';
import '../../screens/game/game_screen_shared.dart' show kGameMapWideProvinceSidePanelWidth;

/// Work-target selection prompt banner overlaying the in-game map canvas.
///
/// SPEC: `SPEC/ui/map-widget.md` § Dark-theme selection prompt overlay tokens.
class GameMapCanvasStackSelectionPrompt extends StatelessWidget {
  const GameMapCanvasStackSelectionPrompt({
    required this.isNarrow,
    required this.overlayOpen,
    required this.onCancel,
    super.key,
  });

  final bool isNarrow;
  final bool overlayOpen;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Positioned(
      top: 8,
      left: 0,
      right: !isNarrow && overlayOpen ? kGameMapWideProvinceSidePanelWidth : 0,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: EditorialMonoclePalette.bgDeep.withValues(
              alpha: kMapSelectionPromptBackgroundAlpha,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: EditorialMonoclePalette.accentDim,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: CtSpacing.m,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.map_selectionMode_prompt,
                  style: TextStyle(
                    color: EditorialMonoclePalette.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                CtNinePatchButton(
                  onPressed: onCancel,
                  minHeight: kMapSelectionPromptCancelMinHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: CtSpacing.ml,
                    vertical: 4,
                  ),
                  child: Text(
                    l10n.map_selectionMode_cancel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
