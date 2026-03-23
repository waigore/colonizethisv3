// Dialog for each human/selected Great Power to choose leader (or default).
// SPEC Phase 5 Dev 12; opened via OpenDialogEvent id `new_game_leader_selection`.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

/// Shown when the shell emits `OpenDialogEvent('new_game_leader_selection')` (handled by `AppEventHandler`).
class NewGameLeaderSelectionDialog extends StatefulWidget {
  const NewGameLeaderSelectionDialog({
    super.key,
    required this.baseConfig,
    required this.naming,
    required this.initialLeaderByGpId,
    required this.onCancel,
    required this.onConfirmed,
  });

  final GameSetupConfig baseConfig;
  final ResolvedNamingConfig naming;
  final Map<String, String> initialLeaderByGpId;
  final VoidCallback onCancel;
  final void Function(
    Map<String, String> leaderVariantByGpId,
    bool enforceFairGpOldWorldAssignment,
  ) onConfirmed;

  @override
  State<NewGameLeaderSelectionDialog> createState() =>
      _NewGameLeaderSelectionDialogState();
}

class _NewGameLeaderSelectionDialogState
    extends State<NewGameLeaderSelectionDialog> {
  late Map<String, String> _leaderByGpId;
  var _enforceFairGpOldWorldAssignment = false;

  @override
  void initState() {
    super.initState();
    _leaderByGpId = Map<String, String>.from(widget.initialLeaderByGpId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final children = <Widget>[
      Text(
        l10n.shell_leaderDialog_intro,
        style: const TextStyle(fontSize: 14),
      ),
      const SizedBox(height: 16),
    ];

    for (final gpId in widget.baseConfig.selectedGreatPowerIds) {
      final gp = widget.naming.gpById(gpId);
      if (gp == null || gp.leaderVariants.isEmpty) continue;
      final currentVariantId = _leaderByGpId[gpId] ?? gp.defaultLeaderVariantId;
      children.addAll([
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(gp.countryName, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CtDropdown<String>(
                  value: currentVariantId,
                  items: gp.leaderVariants.map((v) => v.id).toList(),
                  hint: l10n.shell_leaderDialog_selectLeaderHint,
                  itemLabel: (id) =>
                      gp.leaderVariants.firstWhere((v) => v.id == id).name,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _leaderByGpId[gpId] = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ]);
    }

    children.addAll([
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _enforceFairGpOldWorldAssignment,
            onChanged: (v) {
              setState(() => _enforceFairGpOldWorldAssignment = v ?? false);
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(
                  () => _enforceFairGpOldWorldAssignment =
                      !_enforceFairGpOldWorldAssignment,
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l10n.shell_leaderDialog_enforceFairGpAssignment,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CtNinePatchButton(
            onPressed: widget.onCancel,
            child: Text(l10n.common_cancel),
          ),
          const SizedBox(width: 8),
          CtNinePatchButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onConfirmed(
                _leaderByGpId,
                _enforceFairGpOldWorldAssignment,
              );
            },
            child: Text(l10n.common_start),
          ),
        ],
      ),
    ]);

    return CtDialogShell(
      maxWidth: 480,
      maxHeight: 560,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shell_leaderDialog_title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
