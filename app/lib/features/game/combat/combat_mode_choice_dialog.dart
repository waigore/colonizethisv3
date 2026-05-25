import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';

/// Dialog for choosing combat mode (Auto-Resolve vs Quick Battle).
/// Open via `OpenDialogEvent('combat_mode_choice', params)` registered in `app_event_handler_scope.dart`.
/// SPEC/program/quick-battle-resolution. Capital sieges force Quick Battle.
class CombatModeChoiceDialog extends StatelessWidget {
  const CombatModeChoiceDialog({
    super.key,
    required this.bus,
    required this.provinceName,
    required this.isCapitalSiege,
  });

  static const screenId = UiScreenIds.combatModeChoiceDialog;

  final AppEventBus bus;
  final String provinceName;
  final bool isCapitalSiege;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.quickBattle_combatAt(provinceName),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (isCapitalSiege)
            Text(l10n.quickBattle_capitalSiegeQuickBattleOnly)
          else
            Text(l10n.quickBattle_chooseCombatMode),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isCapitalSiege)
                CtNinePatchButton(
                  onPressed: () {
                    bus.emit(
                      const CombatModeChosenEvent(CombatMode.autoResolve),
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n.quickBattle_autoResolve),
                ),
              if (!isCapitalSiege) const SizedBox(width: 8),
              CtNinePatchButton(
                onPressed: () {
                  bus.emit(const CombatModeChosenEvent(CombatMode.quickBattle));
                  Navigator.of(context).pop();
                },
                child: Text(l10n.quickBattle_quickBattle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
