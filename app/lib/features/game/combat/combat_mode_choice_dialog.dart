import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

/// Dialog for choosing combat mode (Auto-Resolve vs Quick Battle).
/// SPEC/project/phase-4-project-tasks. Capital sieges force Quick Battle.
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
    return AlertDialog(
      title: Text('Combat at $provinceName'),
      content: isCapitalSiege
          ? const Text(
              'Capital siege — Quick Battle only (no auto-resolve).',
            )
          : const Text(
              'Choose combat mode:',
            ),
      actions: [
        if (!isCapitalSiege)
          TextButton(
            onPressed: () => Navigator.pop(context, CombatMode.autoResolve),
            child: const Text('Auto-Resolve'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, CombatMode.quickBattle),
          child: const Text('Quick Battle'),
        ),
      ],
    );
  }
}
