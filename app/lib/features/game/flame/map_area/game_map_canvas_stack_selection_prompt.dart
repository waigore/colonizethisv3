import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_spacing.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'game_map_canvas_stack.dart';
import '../../screens/game/game_screen_shared.dart' show kGameMapWideProvinceSidePanelWidth;
import '../../widgets/units/civilian/work_order_afford_preview_ui.dart';

/// Work-target selection prompt banner overlaying the in-game map canvas.
///
/// SPEC: `SPEC/ui/map-widget.md` § Dark-theme selection prompt overlay tokens.
class GameMapCanvasStackSelectionPrompt extends StatelessWidget {
  const GameMapCanvasStackSelectionPrompt({
    required this.isNarrow,
    required this.overlayOpen,
    required this.onCancel,
    this.usesRelocateCopy = false,
    this.affordPreview,
    super.key,
  });

  final bool isNarrow;
  final bool overlayOpen;
  final VoidCallback? onCancel;
  final bool usesRelocateCopy;
  final WorkOrderAffordPreview? affordPreview;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final preview = affordPreview;
    final showAfford =
        preview != null && preview.hasCostPreview && !usesRelocateCopy;
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GameMapSelectionPromptHeaderRow(
                  l10n: l10n,
                  usesRelocateCopy: usesRelocateCopy,
                  onCancel: onCancel,
                ),
                if (showAfford)
                  _GameMapSelectionPromptAffordSection(
                    l10n: l10n,
                    preview: preview!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameMapSelectionPromptHeaderRow extends StatelessWidget {
  const _GameMapSelectionPromptHeaderRow({
    required this.l10n,
    required this.usesRelocateCopy,
    required this.onCancel,
  });

  final AppLocalizations l10n;
  final bool usesRelocateCopy;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          usesRelocateCopy
              ? l10n.map_selectionMode_relocatePrompt
              : l10n.map_selectionMode_prompt,
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
    );
  }
}

class _GameMapSelectionPromptAffordSection extends StatelessWidget {
  const _GameMapSelectionPromptAffordSection({
    required this.l10n,
    required this.preview,
  });

  final AppLocalizations l10n;
  final WorkOrderAffordPreview preview;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        buildWorkOrderAffordCostChips(preview: preview),
        const SizedBox(height: 4),
        buildWorkOrderAffordStatusText(
          l10n: l10n,
          preview: preview,
        ),
      ],
    );
  }
}
