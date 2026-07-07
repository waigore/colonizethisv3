// Per-slot research turn-preview view for the GAME40001 Technology panel
// (Refs #3512): dual-segment progress bar (committed + anticipated), the
// monospace RP progress label, a green anticipated-RP delta that opens a
// breakdown dialog, and a treasury (gold) row with a signed per-turn delta.
//
// Split out of `technology_panel.dart` so that file stays under the
// `repo.game_widgets_file_size` cap.
//
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview.

import 'package:flutter/material.dart';

import '../../../../config/app_assets.dart';
import '../../../../config/editorial_monocle_palette.dart';
import '../../../../l10n/l10n.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_resource_cell.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/strict_asset_icon.dart';
import 'research_slot_preview.dart';
import 'technology_slot_funding_toggles.dart';

part 'research_slot_turn_preview_view_bar.dart';
part 'research_slot_turn_preview_view_controls.dart';
part 'research_slot_turn_preview_view_breakdown.dart';

/// Treasury-coin glyph shared with the trade screen / game tab-bar treasury
/// chip. SPEC/ui/technology-panel.md § Slot turn preview.
const String _kTreasuryCoinAsset = '${kAppIconAssetPrefix}ui_icon_treasury_coin.png';

/// Renders the committed/anticipated progress bar, RP progress label + delta,
/// and the treasury (gold) row for one assigned, editable research slot.
class ResearchSlotTurnPreviewView extends StatelessWidget {
  const ResearchSlotTurnPreviewView({
    super.key,
    required this.slotIndex,
    required this.preview,
  });

  final int slotIndex;
  final ResearchSlotTurnPreview preview;

  /// Stable test key for the green anticipated-RP delta control.
  static Key rpDeltaKey(int slotIndex) =>
      ValueKey<String>('techSlotRpDelta_$slotIndex');

  /// Stable test key for the treasury (gold) preview row.
  static Key goldRowKey(int slotIndex) =>
      ValueKey<String>('techSlotGoldRow_$slotIndex');

  /// Stable test key for the anticipated (segment B) progress fill.
  static Key anticipatedSegmentKey(int slotIndex) =>
      ValueKey<String>('techSlotAnticipatedSegment_$slotIndex');

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _ResearchDualSegmentBar(
                committedFraction: preview.committedFraction,
                anticipatedFraction: preview.anticipatedFraction,
                anticipatedSegmentKey: anticipatedSegmentKey(slotIndex),
              ),
            ),
            CtGap.wm,
            Text(
              l10n.technologyPanel_slotRpProgress(
                preview.committedProgress,
                preview.cost,
              ),
              style: _monoStyle(EditorialMonoclePalette.accentDim),
            ),
            if (preview.showsAnticipatedSegment) ...[
              const SizedBox(width: 6),
              _RpDeltaControl(
                key: rpDeltaKey(slotIndex),
                preview: preview,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        _GoldPreviewRow(
          key: goldRowKey(slotIndex),
          preview: preview,
        ),
      ],
    );
  }
}

TextStyle _monoStyle(Color color) => TextStyle(
  color: color,
  fontFamilyFallback: const <String>['SF Mono', 'Menlo', 'monospace'],
  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  fontSize: 10,
);
