import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/ui_screen_ids.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import 'move_units_dialog_base.dart';
import 'unit_picker_composition.dart';

/// Army picker when several field armies can Move/Invade from MAP20001 (Refs #4350).
class OverlayArmyMovePickerDialog extends StatefulWidget {
  const OverlayArmyMovePickerDialog({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.armyIds,
    this.initialArmyId,
  });

  static const screenId = UiScreenIds.overlayArmyMovePickerDialog;

  final Game game;
  final String humanPlayerId;
  final List<String> armyIds;
  final String? initialArmyId;

  @override
  State<OverlayArmyMovePickerDialog> createState() =>
      _OverlayArmyMovePickerDialogState();
}

class _OverlayArmyMovePickerDialogState
    extends State<OverlayArmyMovePickerDialog> {
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialArmyId ?? widget.armyIds.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.provinceOverlay_selectArmyTitle,
            style: moveDialogTitleTextStyle(theme),
          ),
          const SizedBox(height: CtSpacing.ml),
          for (final armyId in widget.armyIds)
            MoveDialogDestinationRow(
              selected: _selected == armyId,
              semanticsLabel: l10n.military_units_army(armyId),
              onTap: () => setState(() => _selected = armyId),
              content: UnitPickerCompositionContent(
                title: l10n.military_units_army(armyId),
                compositionLines: armyPickerCompositionLines(
                  game: widget.game,
                  armyId: armyId,
                  l10n: l10n,
                ),
                selected: _selected == armyId,
              ),
            ),
          const SizedBox(height: CtSpacing.l),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: CtSpacing.m,
            children: [
              CtNinePatchButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.common_cancel),
              ),
              CtNinePatchButton(
                enabled: _selected != null,
                onPressed: _selected == null
                    ? null
                    : () => Navigator.pop(context, _selected),
                child: Text(l10n.common_confirm),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
