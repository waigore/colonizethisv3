import 'package:flutter/material.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';

import 'new_game_leader_selection_dialog.dart';
import 'new_game_leader_selection_dialog_setup_fields_options.dart';
import 'new_game_leader_selection_dialog_state_base.dart';

/// Footer actions and start confirmation for [NewGameLeaderSelectionDialog]
/// (Refs #4117).
mixin NewGameLeaderSelectionDialogSetupFieldsFooter
    on
        State<NewGameLeaderSelectionDialog>,
        NewGameLeaderSelectionDialogStateBase,
        NewGameLeaderSelectionDialogSetupFieldsOptions {
  Widget buildFooterButtons(AppLocalizations l10n, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CtNinePatchButton(
          onPressed: widget.onCancel,
          child: Text(l10n.common_cancel),
        ),
        const SizedBox(width: CtSpacing.m),
        CtNinePatchButton(
          onPressed: startEnabled ? () => handleStartPressed(context) : null,
          enabled: startEnabled,
          child: Text(l10n.common_start),
        ),
      ],
    );
  }

  void handleStartPressed(BuildContext context) {
    final seed = NewGameLeaderSelectionDialog.parseSeedInput(
      seedController.text,
    );
    Navigator.of(context).pop();
    widget.onConfirmed(
      List<String>.from(orderedGpIdsBySlot),
      Map<String, String>.from(leaderByGpId),
      seed,
      infiniteMode,
      terrainVariation,
      aiProfileByGpIdForCallback(),
      advancedStartEnabled ? advancedStart : AdvancedStartType.none,
    );
  }

  Map<String, String?> aiProfileByGpIdForCallback() {
    final out = <String, String?>{};
    for (var slot = 1; slot < kNewGameLeaderSelectionNumSlots; slot++) {
      final gpId = orderedGpIdsBySlot[slot];
      final profileName = profileBySlot[slot];
      if (profileName != null && profileName.isNotEmpty) {
        out[gpId] = profileName;
      }
    }
    return out;
  }
}
