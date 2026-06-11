import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_spacing.dart';
import '../../../widgets/ct_transfer_list.dart';
import '../utils/region_labels.dart';

/// Split regiments from one army into a new army (same province).
/// SPEC/ui/military-units-army-management.md.
class SplitArmyDialog extends StatelessWidget {
  const SplitArmyDialog({
    super.key,
    required this.army,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    required this.isHomeArmy,
  });

  final Army army;
  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;
  final bool isHomeArmy;

  Unit? _unit(String id) {
    for (final u in game.worldState.oldWorld.units) {
      if (u.id == id) return u;
    }
    for (final u in game.worldState.newWorld.units) {
      if (u.id == id) return u;
    }
    return null;
  }

  Map<String, int> _initialLeftCounts() {
    final counts = <String, int>{};
    for (final id in army.regimentUnitIds) {
      final u = _unit(id);
      final bucket = regimentTransferBucketKey(u, id);
      counts[bucket] = (counts[bucket] ?? 0) + 1;
    }
    return counts;
  }

  String _locationLabel() {
    final pid = army.stationedProvinceId;
    final province = game.worldState.tryGetProvince(pid);
    final regionId = army.regionId;
    final regionLabel = regionDisplayLabel(regionId);
    final name = province?.displayName ?? pid;
    return '$name — $regionLabel';
  }

  void _handleConfirm(Map<String, int> right, BuildContext context) {
    final toMove = regimentUnitIdsForTransferCounts(
      army.regimentUnitIds,
      _unit,
      right,
    );
    bus.emit(
      ArmySplitRequestedEvent(
        humanPlayerId: humanPlayerId,
        sourceArmyId: army.id,
        unitIdsToMove: toMove,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return CtDialogShell(
      maxWidth: 520,
      maxHeight: 500,
      child: Padding(
        padding: const EdgeInsets.all(CtSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.splitArmy_title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            CtTransferList(
              listHeight: 220,
              leftTitle: army.isHomeArmy ? 'Home Army' : 'Army ${army.id}',
              rightTitle: 'New Army',
              leftSubtitle: _locationLabel(),
              rightSubtitle: _locationLabel(),
              initialLeftCounts: _initialLeftCounts(),
              itemLabelBuilder: (bucketKey) => bucketKey,
              leftEmptyLabel: 'No regiments',
              rightEmptyLabel: 'No regiments',
              confirmLabel: 'Confirm Split',
              totalLabelBuilder: (total) => 'Total: $total regiments',
              canConfirm: (left, right) {
                final leftTotal = left.values.fold(0, (sum, c) => sum + c);
                final rightTotal = right.values.fold(0, (sum, c) => sum + c);
                if (isHomeArmy) {
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
    );
  }
}
