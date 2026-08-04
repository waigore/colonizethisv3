import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import 'fleet_mission_label.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_orders/src/orders/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_orders/src/orders/civilian_projected_tile.dart';
import 'package:colonizethis_logic/src/turn_to_year.dart';
import 'package:colonizethis_logic/src/civilians/spy_relocate_intel.dart';
import 'package:colonizethis_logic/src/civilians/civilians_missing_work_orders.dart';

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
