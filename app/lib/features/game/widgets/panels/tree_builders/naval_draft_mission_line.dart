import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'fleet_mission_label.dart';

/// Pending naval mission draft line for fleet rows (Refs #4213).
String? navalDraftMissionLineForFleet({
  required Game game,
  required String humanPlayerId,
  required String fleetId,
  required Orders draftOrders,
  required AppLocalizations l10n,
}) {
  final missions =
      draftOrders.navalMissionOrdersByPlayerId[humanPlayerId] ?? const [];
  for (final order in missions) {
    if (order.fleetId != fleetId) continue;
    final missionLabel = fleetMissionDisplayLabel(
      fleetMissionFromOrderString(order.mission),
    );
    final targetId = order.targetProvinceId;
    if (targetId == null || targetId.isEmpty) {
      return l10n.naval_mission_pendingLine(missionLabel);
    }
    final province = game.worldState.tryGetProvince(targetId);
    final targetName = province?.displayName ?? province?.id ?? targetId;
    return l10n.naval_mission_pendingLineWithTarget(missionLabel, targetName);
  }
  return null;
}
