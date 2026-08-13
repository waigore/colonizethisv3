import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../province_overlay/province_panel_labels.dart';
import 'move_army_invasion_intel.dart';
import 'move_army_invasion_intel_labels.dart';
import 'naval_mission_flow.dart';
import 'naval_mission_target_intel.dart';
import 'naval_mission_target_intel_labels.dart';
import 'move_units_dialog_base.dart';

/// Province target picker for blockade / beachhead missions (Refs #4213, #4340).
class NavalMissionTargetDialog extends StatefulWidget {
  const NavalMissionTargetDialog({
    super.key,
    required this.game,
    required this.mission,
    required this.fleet,
    required this.targetProvinceIds,
    required this.humanPlayerId,
    this.playerView,
  });

  static const screenId = NavalMissionDialogIds.targetDialog;

  final Game game;
  final FleetMission mission;
  final Fleet fleet;
  final List<String> targetProvinceIds;
  final String humanPlayerId;
  final PlayerView? playerView;

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
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final province = widget.game.worldState.tryGetProvince(provinceId);
    final label = province?.displayName ?? province?.id ?? provinceId;
    final selected = _selected == provinceId;
    final labelStyle = moveDialogRowLabelStyle(theme, selected: selected);
    final intelMutedStyle = (theme.textTheme.bodySmall ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.muted);
    final intelLines = _intelSummaryLines(l10n, provinceId);
    final detailLines = selected ? _intelDetailLines(l10n, provinceId) : const <String>[];

    return MoveDialogDestinationRow(
      selected: selected,
      semanticsLabel: label,
      onTap: () => setState(() => _selected = provinceId),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: labelStyle),
          for (final line in intelLines) Text(line, style: intelMutedStyle),
          for (final line in detailLines) Text(line, style: intelMutedStyle),
        ],
      ),
    );
  }

  List<String> _intelSummaryLines(AppLocalizations l10n, String provinceId) {
    if (widget.mission == FleetMission.beachhead) {
      final summary = computeMoveArmyInvasionIntelSummary(
        game: widget.game,
        playerView: widget.playerView,
        humanPlayerId: widget.humanPlayerId,
        destinationProvinceId: provinceId,
      );
      return moveArmyInvasionIntelSummaryLines(l10n, summary);
    }
    if (widget.mission == FleetMission.blockade) {
      final summary = computeNavalMissionHarborIntelSummary(
        game: widget.game,
        playerView: widget.playerView,
        humanPlayerId: widget.humanPlayerId,
        targetProvinceId: provinceId,
      );
      return navalMissionHarborIntelSummaryLines(l10n, summary);
    }
    return const [];
  }

  List<String> _intelDetailLines(AppLocalizations l10n, String provinceId) {
    if (widget.mission != FleetMission.beachhead) {
      return const [];
    }
    final summary = computeMoveArmyInvasionIntelSummary(
      game: widget.game,
      playerView: widget.playerView,
      humanPlayerId: widget.humanPlayerId,
      destinationProvinceId: provinceId,
    );
    return moveArmyInvasionIntelDetailTypeLines(
      l10n: l10n,
      summary: summary,
      ownTypesByRegimentId: const {},
      regimentLabel: (id) => regimentTypeDisplayLabel(l10n, id),
    );
  }
}
