import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_spacing.dart';
import '../../../widgets/ct_transfer_list.dart';
import '../utils/region_labels.dart';
import '../utils/sea_zone_name_resolver.dart';

class TransferToHomeFleetDialog extends StatelessWidget {
  const TransferToHomeFleetDialog({
    super.key,
    required this.sourceFleet,
    required this.homeFleet,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
  });

  /// SPEC/ui/transfer-to-home-fleet-dialog.md — [UiScreenIds.transferToHomeFleetDialog].
  static const screenId = UiScreenIds.transferToHomeFleetDialog;

  final Fleet sourceFleet;
  final Fleet homeFleet;
  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;

  Map<String, int> _countsForFleet(Fleet fleet) {
    final counts = <String, int>{};
    for (final typeId in fleet.shipTypeIds) {
      counts[typeId] = (counts[typeId] ?? 0) + 1;
    }
    return counts;
  }

  String _fleetLocationLabel(Fleet fleet) {
    if (fleet.isAtSea) {
      final seaZoneId = fleet.seaZoneId ?? '';
      final zoneName = seaZoneDisplayName(
        game: game,
        regionId: fleet.regionId,
        seaZoneId: seaZoneId,
      );
      return '$zoneName - ${regionDisplayLabel(fleet.regionId)}';
    }
    final inPortId = fleet.inPortAtProvinceId;
    if (inPortId == null) {
      return regionDisplayLabel(fleet.regionId);
    }
    Province? province;
    for (final p in game.worldState.oldWorld.provinces) {
      if (p.id == inPortId || '${p.regionId}|${p.id}' == inPortId) {
        province = p;
        break;
      }
    }
    if (province == null) {
      for (final p in game.worldState.newWorld.provinces) {
        if (p.id == inPortId || '${p.regionId}|${p.id}' == inPortId) {
          province = p;
          break;
        }
      }
    }
    final provinceLabel = province?.displayName ?? inPortId;
    return '$provinceLabel - ${regionDisplayLabel(fleet.regionId)}';
  }

  void _handleConfirm(Map<String, int> sourceRemaining, BuildContext context) {
    final sourceInitial = _countsForFleet(sourceFleet);
    final movedByType = <String, int>{};
    for (final entry in sourceInitial.entries) {
      final remaining = sourceRemaining[entry.key] ?? 0;
      final moved = entry.value - remaining;
      if (moved > 0) {
        movedByType[entry.key] = moved;
      }
    }
    final movedShips = shipInstancesForTransferCounts(
      sourceFleet.ships,
      movedByType,
    );
    if (movedShips.isEmpty) {
      return;
    }
    bus.emit(
      NavalTransferShipsRequestedEvent(
        humanPlayerId: humanPlayerId,
        sourceFleetId: sourceFleet.id,
        targetFleetId: homeFleet.id,
        shipInstanceIdsToTransfer: movedShips.map((s) => s.id).toList(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final l10n = appL10n(context);
    final sourceInitialCounts = _countsForFleet(sourceFleet);
    final homeInitialCounts = _countsForFleet(homeFleet);
    final TextStyle titleStyle =
        (theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16))
            .copyWith(
              color: EditorialMonoclePalette.accent,
              letterSpacing: 0.05 * 16,
              fontWeight: FontWeight.w600,
            );
    return CtDialogShell(
      maxWidth: 560,
      maxHeight: 520,
      child: Padding(
        padding: const EdgeInsets.all(CtSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.naval_transferToHome_dialogTitle,
              style: titleStyle,
            ),
            const SizedBox(height: 16),
            CtTransferList(
              listHeight: 240,
              itemLabelBuilder: shipTypeDisplayName,
              leftTitle: l10n.naval_transferToHome_sourceTitle(sourceFleet.id),
              rightTitle: l10n.naval_homeFleetLabel,
              leftSubtitle: _fleetLocationLabel(sourceFleet),
              rightSubtitle: _fleetLocationLabel(homeFleet),
              initialLeftCounts: sourceInitialCounts,
              initialRightCounts: homeInitialCounts,
              leftEmptyLabel: l10n.splitFleet_noShips,
              rightEmptyLabel: l10n.splitFleet_noShips,
              confirmLabel: l10n.naval_transferToHome_confirm,
              totalLabelBuilder: (total) => l10n.splitFleet_totalShips(total),
              canConfirm: (left, right) {
                for (final entry in sourceInitialCounts.entries) {
                  final remaining = left[entry.key] ?? 0;
                  if (remaining < entry.value) {
                    return true;
                  }
                }
                return false;
              },
              onCancel: () => Navigator.of(context).pop(),
              onConfirm: (left, right) => _handleConfirm(left, context),
            ),
          ],
        ),
      ),
    );
  }
}
