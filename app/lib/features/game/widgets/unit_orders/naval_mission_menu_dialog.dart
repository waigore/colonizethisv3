import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import 'naval_mission_flow.dart';
import 'move_units_dialog_base.dart';
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
            MoveDialogDestinationRow(
              selected: _selected == fleetId,
              semanticsLabel: l10n.naval_fleetLabel(fleetId),
              onTap: () => setState(() => _selected = fleetId),
              content: Text(
                l10n.naval_fleetLabel(fleetId),
                style: moveDialogRowLabelStyle(
                  theme,
                  selected: _selected == fleetId,
                ),
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
        _missionRow(context, option),
      if (availability.canCancelPending)
        _menuActionRow(
          context: context,
          label: l10n.naval_mission_cancelPending,
          enabled: true,
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

  Widget _missionRow(BuildContext context, NavalMissionOption option) {
    final label = navalMissionMenuLabel(option.mission);
    return _menuActionRow(
      context: context,
      label: label,
      subtitle: option.disabledReason,
      enabled: option.isEnabled,
      onTap: option.isEnabled
          ? () => Navigator.pop(
              context,
              NavalMissionMenuChoiceMission(option.mission),
            )
          : null,
    );
  }

  Widget _menuActionRow({
    required BuildContext context,
    required String label,
    String? subtitle,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: EditorialMonoclePalette.border,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: CtSpacing.m,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    label,
                    style: moveDialogRowLabelStyle(theme, selected: false),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: CtSpacing.xs),
                    Text(
                      subtitle,
                      style: moveDialogEmptyTextStyle(theme),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
