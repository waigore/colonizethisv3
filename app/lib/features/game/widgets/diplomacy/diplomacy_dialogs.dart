// Dialogs for diplomacy actions that require parameters.
// SPEC: SPEC/ui/grant-or-subsidy-dialog.md (DIPL20001),
// SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_app/core/utils/faction_display_name.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import 'diplomacy_dialogs_grant_subsidy_body.dart';

/// Grant or Subsidy dialog widget. Emits [GrantOrSubsidySubmittedEvent] on submit.
///
/// Visual contract: dark editorial-monocle DIPL20001 chrome per
/// `SPEC/ui/grant-or-subsidy-dialog.md` § Layout / wireframe and
/// `SPEC/ui/mockups/DIPL20001-grant-or-subsidy-dialog.html`. All colors resolve
/// from [EditorialMonoclePalette] tokens (no hard-coded hex literals); the
/// stepper renders bespoke `−` / `+` buttons (no Material `IconButton`) to
/// match the per-mockup chrome.
class GrantOrSubsidyDialog extends StatelessWidget {
  const GrantOrSubsidyDialog({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.targetFactionId,
    required this.isSubsidy,
    required this.bus,
  });

  final Game game;
  final String humanPlayerId;
  final String targetFactionId;
  final bool isSubsidy;
  final AppEventBus bus;

  int get _treasury => game.playerById(humanPlayerId)?.treasury ?? 0;

  String get _targetDisplayName => displayNameForFaction(game, targetFactionId);

  List<String> _previewLines(int amount) {
    final order = DiplomaticOrder(
      type: isSubsidy
          ? DiplomaticOrderType.setSubsidy
          : DiplomaticOrderType.grantAid,
      targetFactionId: targetFactionId,
      amount: amount,
    );
    return buildDiplomacyConfirmPreviewLines(
      order: order,
      game: game,
      humanPlayerId: humanPlayerId,
      targetDisplayName: _targetDisplayName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return CtDialogShell(
      child: GrantSubsidyAmountBody(
        title: isSubsidy ? l10n.diplomacy_setSubsidy : l10n.diplomacy_grantAid,
        treasury: _treasury,
        isSubsidy: isSubsidy,
        previewLinesForAmount: _previewLines,
        onCancel: () => Navigator.of(context).pop(),
        onSubmit: (amount) {
          Navigator.of(context).pop();
          bus.emit(
            GrantOrSubsidySubmittedEvent(
              targetFactionId: targetFactionId,
              amount: amount,
              isSubsidy: isSubsidy,
            ),
          );
        },
      ),
    );
  }
}
