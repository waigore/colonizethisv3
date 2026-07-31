import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import 'naval_mission_flow.dart';
import 'move_units_dialog_base_styles.dart';

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
            ListTile(
              dense: true,
              title: Text(l10n.naval_fleetLabel(fleetId)),
              leading: Radio<String>(
                value: fleetId,
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v),
              ),
              onTap: () => setState(() => _selected = fleetId),
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

/// Mission assign / cancel-pending menu for one fleet (Refs #4213).
class NavalMissionMenuDialog extends StatelessWidget {
  const NavalMissionMenuDialog({
    super.key,
    required this.game,
    required this.fleet,
    required this.availability,
  });

  static const screenId = NavalMissionDialogIds.menuDialog;

  final Game game;
  final Fleet fleet;
  final NavalMissionAvailability availability;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final fleetLabel = l10n.naval_fleetLabel(fleet.id);
    final rows = <Widget>[
      for (final option in availability.missions)
        _missionTile(context, option),
      if (availability.canCancelPending)
        ListTile(
          dense: true,
          title: Text(l10n.naval_mission_cancelPending),
          onTap: () => Navigator.pop(
            context,
            const NavalMissionMenuChoiceCancelPending(),
          ),
        ),
    ];
    if (rows.isEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: CtSpacing.s),
          child: Text(
            l10n.naval_mission_noMissionsAvailable,
            style: moveDialogEmptyTextStyle(theme),
          ),
        ),
      );
    }

    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.naval_mission_menuTitle(fleetLabel),
            style: moveDialogTitleTextStyle(theme),
          ),
          const SizedBox(height: CtSpacing.ml),
          ...rows,
          const SizedBox(height: CtSpacing.l),
          Align(
            alignment: Alignment.centerRight,
            child: CtNinePatchButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.common_cancel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _missionTile(BuildContext context, NavalMissionOption option) {
    final label = navalMissionMenuLabel(option.mission);
    final enabled = option.isEnabled;
    return ListTile(
      dense: true,
      enabled: enabled,
      title: Text(label),
      subtitle: option.disabledReason != null
          ? Text(option.disabledReason!)
          : null,
      onTap: enabled
          ? () => Navigator.pop(
              context,
              NavalMissionMenuChoiceMission(option.mission),
            )
          : null,
    );
  }
}
