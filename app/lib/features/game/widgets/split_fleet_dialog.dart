import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_transfer_list.dart';
import '../utils/region_labels.dart';

class SplitFleetDialog extends StatelessWidget {
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
      final localId = seaZoneId.contains('|')
          ? seaZoneId.split('|').last
          : seaZoneId;
      return 'Region — $localId';
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
    final toMove =
        shipInstancesForTransferCounts(originalFleet.ships, newCounts);
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
    return CtDialogShell(
      maxWidth: 520,
      maxHeight: 500,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Split Fleet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              CtTransferList(
                listHeight: 220,
                leftTitle: originalFleet.id == 'home_fleet'
                    ? 'Home Fleet'
                    : 'Fleet ${originalFleet.id}',
                rightTitle: 'New Fleet',
                leftSubtitle: _fleetLocationLabel(),
                rightSubtitle: _fleetLocationLabel(),
                initialLeftCounts: _initialOriginalCounts(),
                leftEmptyLabel: 'No ships',
                rightEmptyLabel: 'No ships',
                confirmLabel: 'Confirm Split',
                totalLabelBuilder: (total) => 'Total: $total ships',
                canConfirm: (left, right) {
                  final leftTotal = left.values.fold(
                    0,
                    (sum, count) => sum + count,
                  );
                  final rightTotal = right.values.fold(
                    0,
                    (sum, count) => sum + count,
                  );
                  if (isHomeFleet) {
                    return rightTotal > 0;
                  }
                  return leftTotal >= 1 && rightTotal > 0;
                },
                onCancel: () => Navigator.of(context).pop(),
                onConfirm: (_, right) => _handleConfirm(right, context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
