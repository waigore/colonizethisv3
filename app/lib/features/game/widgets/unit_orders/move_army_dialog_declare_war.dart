import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_spacing.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/invade_province_declare_war_body.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'move_army_dialog.dart';
import 'move_army_dialog_state_logic.dart';
import 'move_units_dialog_base.dart';

mixin MoveArmyDialogDeclareWar
    on MoveUnitsDialogState<MoveArmyDialog>, MoveArmyDialogStateLogic {
  Future<void> onConfirmPressed() async {
    final entries = destinationEntries();
    final entry = selectedEntry(entries);
    if (entry == null) return;
    final l10n = appL10n(context);

    if (!entry.requiresDeclareWarOnConfirm) {
      emitAndClose(entry);
      return;
    }

    final ownerLabel = moveArmyFactionGroupHeaderLabel(
      widget.game,
      entry,
      l10n,
    );
    final ok = await showDeclareWarConfirmDialog(
      ownerLabel: ownerLabel,
      l10n: l10n,
      targetFactionId: entry.ownerFactionId,
    );
    if (ok == true && context.mounted) {
      emitAndClose(entry);
    }
  }

  Future<bool?> showDeclareWarConfirmDialog({
    required String ownerLabel,
    required AppLocalizations l10n,
    required String targetFactionId,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final titleStyle = (theme.textTheme.titleMedium ?? const TextStyle())
            .copyWith(color: EditorialMonoclePalette.danger);
        final bodyStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
            .copyWith(color: EditorialMonoclePalette.fg);
        return CtDialogShell(
          borderColor: EditorialMonoclePalette.danger,
          borderWidth: CtDialogShell.dangerBorderWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.moveArmy_invadeProvinceTitle, style: titleStyle),
              const SizedBox(height: CtSpacing.m),
              Text(
                invadeProvinceDeclareWarBody(
                  l10n: l10n,
                  game: widget.game,
                  humanPlayerId: widget.humanPlayerId,
                  targetFactionId: targetFactionId,
                  ownerLabel: ownerLabel,
                ),
                style: bodyStyle,
              ),
              const SizedBox(height: CtSpacing.l),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: CtSpacing.m,
                runSpacing: CtSpacing.m,
                children: [
                  CtNinePatchButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(l10n.common_cancel),
                  ),
                  CtNinePatchButton(
                    dangerVariant: true,
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(l10n.moveArmy_declareWarAndMove),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
