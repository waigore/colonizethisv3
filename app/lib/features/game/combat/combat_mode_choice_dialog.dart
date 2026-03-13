import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';

/// Dialog for choosing combat mode (Auto-Resolve vs Quick Battle).
/// SPEC/program/quick-battle-resolution. Capital sieges force Quick Battle.
class CombatModeChoiceDialog extends StatelessWidget {
  const CombatModeChoiceDialog({
    super.key,
    required this.provinceName,
    required this.isCapitalSiege,
    this.defaultMode = CombatMode.autoResolve,
  });

  final String provinceName;
  final bool isCapitalSiege;
  final CombatMode defaultMode;

  static Future<CombatMode?> show(
    BuildContext context, {
    required String provinceName,
    required bool isCapitalSiege,
    CombatMode defaultMode = CombatMode.autoResolve,
  }) {
    return showDialog<CombatMode>(
      context: context,
      builder: (context) => CombatModeChoiceDialog(
        provinceName: provinceName,
        isCapitalSiege: isCapitalSiege,
        defaultMode: defaultMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Combat at $provinceName',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (isCapitalSiege)
            const Text(
              'Capital siege — Quick Battle only (no auto-resolve).',
            )
          else
            const Text('Choose combat mode:'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isCapitalSiege)
                CtNinePatchButton(
                  onPressed: () =>
                      Navigator.pop(context, CombatMode.autoResolve),
                  child: const Text('Auto-Resolve'),
                ),
              if (!isCapitalSiege) const SizedBox(width: 8),
              CtNinePatchButton(
                onPressed: () =>
                    Navigator.pop(context, CombatMode.quickBattle),
                child: const Text('Quick Battle'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
