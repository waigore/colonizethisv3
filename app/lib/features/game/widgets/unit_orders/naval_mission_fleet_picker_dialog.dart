import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import 'naval_mission_flow.dart';
import 'move_units_dialog_base.dart';
import 'unit_picker_composition.dart';

/// Fleet picker when multiple fleets share one map marker (Refs #4213).
class NavalMissionFleetPickerDialog extends StatefulWidget {
  const NavalMissionFleetPickerDialog({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.fleetIds,
    this.initialFleetId,
  });

  static const screenId = NavalMissionDialogIds.fleetPickerDialog;

  final Game game;
  final String humanPlayerId;
  final List<String> fleetIds;
  final String? initialFleetId;

  @override
  State<NavalMissionFleetPickerDialog> createState() =>
      _NavalMissionFleetPickerDialogState();
}

class _NavalMissionFleetPickerDialogState
    extends State<NavalMissionFleetPickerDialog> {
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialFleetId ?? widget.fleetIds.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final showLocationContext = fleetPickerShowsLocationContext(
      widget.game,
      widget.fleetIds,
    );
    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.naval_mission_selectFleetTitle,
            style: moveDialogTitleTextStyle(theme),
          ),
          const SizedBox(height: CtSpacing.ml),
          for (final fleetId in widget.fleetIds)
            MoveDialogDestinationRow(
              selected: _selected == fleetId,
              semanticsLabel: l10n.naval_fleetLabel(fleetId),
              onTap: () => setState(() => _selected = fleetId),
              content: UnitPickerCompositionContent(
                title: l10n.naval_fleetLabel(fleetId),
                compositionLines: fleetPickerCompositionLines(
                  game: widget.game,
                  fleetId: fleetId,
                  l10n: l10n,
                  showLocationContext: showLocationContext,
                ),
                selected: _selected == fleetId,
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
