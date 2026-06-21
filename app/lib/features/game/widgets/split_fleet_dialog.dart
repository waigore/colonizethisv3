import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../utils/region_labels.dart';
import '../utils/sea_zone_name_resolver.dart';
import 'split_entity_dialog.dart';

class SplitFleetDialog extends SplitEntityDialog {
  const SplitFleetDialog({
    super.key,
    required this.originalFleet,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    required this.isHomeFleet,
  });

  final Fleet originalFleet;
  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;
  final bool isHomeFleet;

  Map<String, int> _initialOriginalCounts() {
    final counts = <String, int>{};
    for (final typeId in originalFleet.shipTypeIds) {
      counts[typeId] = (counts[typeId] ?? 0) + 1;
    }
    return counts;
  }

  String _fleetLocationLabel() {
    final fleet = originalFleet;
    if (fleet.isAtSea) {
      final seaZoneId = fleet.seaZoneId!;
      final localId = prefixedIdLocalSegment(seaZoneId);
      final zoneName = seaZoneDisplayName(
        game: game,
        regionId: fleet.regionId,
        seaZoneId: localId,
      );
      final regionLabel = regionDisplayLabel(fleet.regionId);
      return '$zoneName — $regionLabel';
    } else if (fleet.isInPort) {
      final inPortId = fleet.inPortAtProvinceId!;
      final provinceMap = <String, Province>{};
      for (final p in game.worldState.oldWorld.provinces) {
        provinceMap[p.id] = p;
        provinceMap['${p.regionId}|${p.id}'] = p;
      }
      for (final p in game.worldState.newWorld.provinces) {
        provinceMap[p.id] = p;
        provinceMap['${p.regionId}|${p.id}'] = p;
      }
      final province = provinceMap[inPortId];
      final regionId = fleet.regionId;
      final regionLabel = regionDisplayLabel(regionId);
      final provinceName = province?.displayName ?? inPortId;
      return '$provinceName — $regionLabel';
    }
    return 'Unknown';
  }

  void _handleConfirm(Map<String, int> newCounts, BuildContext context) {
    final toMove = shipInstancesForTransferCounts(
      originalFleet.ships,
      newCounts,
    );
    bus.emit(
      NavalSplitFleetRequestedEvent(
        humanPlayerId: humanPlayerId,
        originalFleetId: originalFleet.id,
        shipInstanceIdsToNewFleet: toMove.map((s) => s.id).toList(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return buildSplitDialogScaffold(
      context: context,
      title: l10n.splitFleet_dialogTitle,
      leftTitle: originalFleet.id == 'home_fleet'
          ? l10n.naval_homeFleetLabel
          : l10n.naval_fleetLabel(originalFleet.id),
      rightTitle: l10n.splitFleet_newFleetTitle,
      locationLabel: _fleetLocationLabel(),
      initialLeftCounts: _initialOriginalCounts(),
      itemLabelBuilder: shipTypeDisplayName,
      leftEmptyLabel: l10n.splitFleet_noShips,
      rightEmptyLabel: l10n.splitFleet_noShips,
      confirmLabel: l10n.splitFleet_confirm,
      totalLabelBuilder: (total) => l10n.splitFleet_totalShips(total),
      isHomeEntity: isHomeFleet,
      onConfirm: (right) => _handleConfirm(right, context),
    );
  }
}
