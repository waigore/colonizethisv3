// New game setup: six slots with nation + leader pickers. Opened via
// OpenDialogEvent id `new_game_leader_selection`.
// SPEC/ui/new-game-leader-selection-dialog.md.
//
// De-parted wave-9 cluster (Refs #4117): explicit-import libraries replace the
// former 7-part library. Public surface: [NewGameLeaderSelectionDialog].

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'new_game_leader_selection_dialog_constants.dart';
import 'new_game_leader_selection_dialog_setup_fields_footer.dart';
import 'new_game_leader_selection_dialog_setup_fields_header.dart';
import 'new_game_leader_selection_dialog_setup_fields_options.dart';
import 'new_game_leader_selection_dialog_slot_row.dart';
import 'new_game_leader_selection_dialog_slots.dart';
import 'new_game_leader_selection_dialog_state_base.dart';

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
      NewGameLeaderSelectionDialogState();
}

class NewGameLeaderSelectionDialogState extends State<NewGameLeaderSelectionDialog>
    with
        NewGameLeaderSelectionDialogStateBase,
        NewGameLeaderSelectionDialogSlots,
        NewGameLeaderSelectionDialogSlotRow,
        NewGameLeaderSelectionDialogSetupFieldsHeader,
        NewGameLeaderSelectionDialogSetupFieldsOptions,
        NewGameLeaderSelectionDialogSetupFieldsFooter {
  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final ThemeData theme = Theme.of(context);
    final styles = resolveTextStyles(theme);
    final Set<int> duplicateSlots = duplicateSlotIndices();
    final slotWidgets = <Widget>[
      for (var i = 0; i < kNewGameLeaderSelectionDialogNumSlots; i++) ...[
        if (i > 0)
          const SizedBox(height: kNewGameLeaderSelectionDialogSlotListGap),
        buildSlotRow(
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
          buildHeader(l10n, styles),
          const SizedBox(height: CtSpacing.l),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: slotWidgets,
          ),
          const SizedBox(height: CtSpacing.ml),
          buildSeedField(theme, l10n, styles),
          const SizedBox(height: CtSpacing.ml),
          buildAdvancedStartField(theme, l10n, styles),
          const SizedBox(height: CtSpacing.ml),
          buildInfiniteModeTile(theme, l10n, styles),
          const SizedBox(height: CtSpacing.ml),
          buildTerrainVariationField(
            context,
            l10n,
            fieldLabelStyle: styles.fieldLabel,
            helperStyle: styles.helper,
          ),
          const SizedBox(height: CtSpacing.l),
          buildFooterButtons(l10n, context),
        ],
      ),
    );
  }
}
