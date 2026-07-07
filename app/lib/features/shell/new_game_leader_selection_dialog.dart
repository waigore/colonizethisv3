// New game setup: six slots with nation + leader pickers. Opened via
// OpenDialogEvent id `new_game_leader_selection`. SPEC/ui/new-game-leader-selection-dialog.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_app/widgets/gp_default_map_color_swatch.dart';

part 'new_game_leader_selection_dialog_state_base.dart';
part 'new_game_leader_selection_dialog_slots.dart';
part 'new_game_leader_selection_dialog_slot_row.dart';
part 'new_game_leader_selection_dialog_setup_fields.dart';

const int _kNumSlots = 6;

/// Vertical gap between slot rows. Matches the mockup `.slots-list{gap:6px}`.
const double _kSlotListGap = CtSpacing.s;

/// Slot-row inner padding. Matches the mockup `.slot-row{padding:8px 10px}`
/// (vertical 8 dp = [CtSpacing.m]; horizontal 10 dp is a per-component override
/// not on the canonical spacing scale).
const EdgeInsets _kSlotRowPadding = EdgeInsets.symmetric(
  vertical: CtSpacing.m,
  horizontal: 10,
);

/// Horizontal gap between the infinite-mode toggle and its label, also used to
/// indent the helper text. Matches the mockup `.toggle-row{gap:10px}`.
const double _kToggleLabelGap = 10;

const String _kNormalProfileChoiceId = '';

/// Shown when the shell emits `OpenDialogEvent('new_game_leader_selection')`.
class NewGameLeaderSelectionDialog extends StatefulWidget {
  const NewGameLeaderSelectionDialog({
    super.key,
    required this.baseConfig,
    required this.naming,
    required this.initialLeaderByGpId,
    required this.blessedProfileNames,
    required this.onCancel,
    required this.onConfirmed,
  });

  /// SPEC/ui/new-game-leader-selection-dialog.md — [UiScreenIds.newGameLeaderSelectionDialog].
  static const screenId = UiScreenIds.newGameLeaderSelectionDialog;

  /// Template for non-GP fields; [GameSetupConfig.selectedGreatPowerIds] supplies initial six nations.
  final GameSetupConfig baseConfig;
  final ResolvedNamingConfig naming;
  final Map<String, String> initialLeaderByGpId;

  /// Blessed tuned profile names from the asset manifest (sorted).
  final List<String> blessedProfileNames;

  final VoidCallback onCancel;
  final void Function(
    List<String> orderedGreatPowerIds,
    Map<String, String> leaderVariantByGpId,
    int seed,
    bool infiniteMode,
    double terrainVariation,
    Map<String, String?> aiProfileByGpId,
    AdvancedStartType advancedStart,
  )
  onConfirmed;

  /// Default terrain-variation slider value (matches `GameSetupConfig.terrainVariation` default).
  static const double defaultTerrainVariation = 0.5;

  /// Width of the danger border painted around a slot's nation dropdown when
  /// the slot's currently-selected Great Power id also appears in another
  /// slot. Pinned to 1 dp so the visual cue does not shift slot layout.
  /// SPEC: `SPEC/ui/new-game-leader-selection-dialog.md` § Duplicate slot
  /// validation feedback (Refs #2867 R19).
  static const double duplicateSlotBorderWidth = 1.0;

  /// Stable key prefix for the danger-border wrapper rendered around the
  /// nation dropdown of slot `slotIndex` when that slot is part of a
  /// duplicate group. Tests pin the per-slot key
  /// `'newGameLeaderDialogSlotDuplicateBorder_<slotIndex>'` so the positive
  /// AC can assert that exactly the duplicate slots carry the danger
  /// border without depending on widget tree order. The wrapper is only
  /// mounted when the slot is detected as a duplicate; non-duplicate
  /// slots render the nation dropdown directly without this key.
  static String duplicateSlotBorderKey(int slotIndex) =>
      'newGameLeaderDialogSlotDuplicateBorder_$slotIndex';

  /// Parses seed field text for [GameSetupConfig.seed]: empty or invalid → 42; negative → 42.
  static int parseSeedInput(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return 42;
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < 0) {
      return 42;
    }
    return parsed;
  }

  @override
  State<NewGameLeaderSelectionDialog> createState() =>
      _NewGameLeaderSelectionDialogState();
}

class _NewGameLeaderSelectionDialogState extends State<NewGameLeaderSelectionDialog>
    with
        _NewGameLeaderSelectionDialogStateBase,
        _NewGameLeaderSelectionDialogSlots,
        _NewGameLeaderSelectionDialogSlotRow,
        _NewGameLeaderSelectionDialogSetupFields {
  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final ThemeData theme = Theme.of(context);
    final _LeaderDialogTextStyles styles = _resolveTextStyles(theme);
    final Set<int> duplicateSlots = _duplicateSlotIndices();
    final slotWidgets = <Widget>[
      for (var i = 0; i < _kNumSlots; i++) ...[
        if (i > 0) const SizedBox(height: _kSlotListGap),
        _buildSlotRow(
          context,
          i,
          l10n,
          styles,
          isDuplicate: duplicateSlots.contains(i),
        ),
      ],
    ];
    return CtDialogShell(
      maxWidth: 540,
      maxHeight: 720,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(l10n, styles),
          const SizedBox(height: CtSpacing.l),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: slotWidgets,
          ),
          const SizedBox(height: CtSpacing.ml),
          _buildSeedField(theme, l10n, styles),
          const SizedBox(height: CtSpacing.ml),
          _buildAdvancedStartField(theme, l10n, styles),
          const SizedBox(height: CtSpacing.ml),
          _buildInfiniteModeTile(theme, l10n, styles),
          const SizedBox(height: CtSpacing.ml),
          _buildTerrainVariationField(
            context,
            l10n,
            fieldLabelStyle: styles.fieldLabel,
            helperStyle: styles.helper,
          ),
          const SizedBox(height: CtSpacing.l),
          _buildFooterButtons(l10n, context),
        ],
      ),
    );
  }
}
