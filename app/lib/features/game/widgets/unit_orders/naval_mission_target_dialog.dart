import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import 'naval_mission_flow.dart';
import 'move_units_dialog_base.dart';

/// Province target picker for blockade / beachhead missions (Refs #4213).
class NavalMissionTargetDialog extends StatefulWidget {
  const NavalMissionTargetDialog({
    super.key,
    required this.game,
    required this.mission,
    required this.fleet,
    required this.targetProvinceIds,
  });

  static const screenId = NavalMissionDialogIds.targetDialog;

  final Game game;
  final FleetMission mission;
  final Fleet fleet;
  final List<String> targetProvinceIds;

  @override
  State<NavalMissionTargetDialog> createState() =>
      _NavalMissionTargetDialogState();
}

class _NavalMissionTargetDialogState
    extends MoveUnitsDialogState<NavalMissionTargetDialog> {
  String? _selected;

  @override
  String get moveDialogTitle {
    final l10n = appL10n(context);
    return l10n.naval_mission_selectTargetTitle(
      navalMissionMenuLabel(widget.mission),
    );
  }

  @override
  String? get moveDialogCaption =>
      navalMissionTargetCaption(appL10n(context), widget.mission);

  @override
  bool get moveDialogHasDestinations => widget.targetProvinceIds.isNotEmpty;

  @override
  String get moveDialogEmptyText =>
      appL10n(context).naval_mission_noTargetsAvailable;

  @override
  bool get moveDialogCanConfirm => _selected != null;

  @override
  void onMoveDialogConfirm() {
    final selected = _selected;
    if (selected == null) return;
    Navigator.pop(context, selected);
  }

  @override
  void onMoveDialogCancel() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) => buildMoveDialogScaffold(context);

  @override
  Widget buildMoveDialogDestinations(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final provinceId in widget.targetProvinceIds)
          _provinceRow(context, provinceId),
      ],
    );
  }

  Widget _provinceRow(BuildContext context, String provinceId) {
    final province = widget.game.worldState.tryGetProvince(provinceId);
    final label = province?.displayName ?? province?.id ?? provinceId;
    final selected = _selected == provinceId;
    return MoveDialogDestinationRow(
      selected: selected,
      semanticsLabel: label,
      onTap: () => setState(() => _selected = provinceId),
      content: Text(
        label,
        style: moveDialogRowLabelStyle(Theme.of(context), selected: selected),
      ),
    );
  }
}
