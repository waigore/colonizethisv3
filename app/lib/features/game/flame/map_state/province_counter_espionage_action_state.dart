import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// MAP20001 Civilian **Counter-espionage** visibility/enablement (Refs #4528).
enum ProvinceCounterEspionageDisabledReason { noIdleSpy, alreadyPosted }

class ProvinceCounterEspionageActionState {
  const ProvinceCounterEspionageActionState({
    required this.showControl,
    required this.enabled,
    this.disabledReason,
  });

  final bool showControl;
  final bool enabled;
  final ProvinceCounterEspionageDisabledReason? disabledReason;

  static const hidden = ProvinceCounterEspionageActionState(
    showControl: false,
    enabled: false,
  );
}

/// Hide > disabled > enabled. Destination is the overlay province-level key.
ProvinceCounterEspionageActionState computeProvinceCounterEspionageActionState({
  required Game game,
  required Orders orders,
  required String humanPlayerId,
  required String displayId,
  required bool canMutateViaUi,
  required bool isSeaZone,
  required bool civilianSectionObfuscated,
}) {
  if (!canMutateViaUi || isSeaZone || civilianSectionObfuscated) {
    return ProvinceCounterEspionageActionState.hidden;
  }
  final province = game.worldState.tryGetProvince(displayId);
  final ownerId = province?.ownerId;
  if (ownerId == null || ownerId.isEmpty || ownerId != humanPlayerId) {
    return ProvinceCounterEspionageActionState.hidden;
  }

  final alreadyPosted = _realmAlreadyCovered(
    game: game,
    orders: orders,
    humanPlayerId: humanPlayerId,
  );
  final eligible = _eligibleAssigners(
    game: game,
    orders: orders,
    humanPlayerId: humanPlayerId,
  );
  if (alreadyPosted) {
    return const ProvinceCounterEspionageActionState(
      showControl: true,
      enabled: false,
      disabledReason: ProvinceCounterEspionageDisabledReason.alreadyPosted,
    );
  }
  if (eligible.isNotEmpty) {
    return const ProvinceCounterEspionageActionState(
      showControl: true,
      enabled: true,
    );
  }
  return const ProvinceCounterEspionageActionState(
    showControl: true,
    enabled: false,
    disabledReason: ProvinceCounterEspionageDisabledReason.noIdleSpy,
  );
}

/// Province-level `regionId|provinceId|0|0` work-order key (Refs #4528).
String? provinceLevelCounterSpyTileKey(String prefixedProvinceId) {
  if (prefixedProvinceId.isEmpty || !prefixedProvinceId.contains('|')) {
    return null;
  }
  return '$prefixedProvinceId|0|0';
}

bool counterEspionageUnitIsEligibleAssigner({
  required Orders orders,
  required String humanPlayerId,
  required Unit unit,
}) {
  if (!isSpyUnit(unit.type) || unit.ownerId != humanPlayerId) return false;
  if (unit.status != UnitStatus.idle || unit.currentWork != null) return false;
  if (pendingWorkOrderForUnit(
        playerId: humanPlayerId,
        unitId: unit.id,
        orders: orders,
      ) !=
      null) {
    return false;
  }
  if (pendingMoveOrderForUnit(
        playerId: humanPlayerId,
        unitId: unit.id,
        orders: orders,
      ) !=
      null) {
    return false;
  }
  return true;
}

bool _realmAlreadyCovered({
  required Game game,
  required Orders orders,
  required String humanPlayerId,
}) {
  for (final unit in _humanSpies(game, humanPlayerId)) {
    if (unit.currentWork?.workTarget == kWorkTargetCounterSpy) return true;
    final pending = pendingWorkOrderForUnit(
      playerId: humanPlayerId,
      unitId: unit.id,
      orders: orders,
    );
    if (pending?.target == kWorkTargetCounterSpy) return true;
  }
  return false;
}

List<Unit> _eligibleAssigners({
  required Game game,
  required Orders orders,
  required String humanPlayerId,
}) {
  return [
    for (final unit in _humanSpies(game, humanPlayerId))
      if (counterEspionageUnitIsEligibleAssigner(
        orders: orders,
        humanPlayerId: humanPlayerId,
        unit: unit,
      ))
        unit,
  ];
}

List<Unit> _humanSpies(Game game, String humanPlayerId) {
  return [
    for (final unit in game.worldState.oldWorld.units)
      if (unit.ownerId == humanPlayerId && isSpyUnit(unit.type)) unit,
    for (final unit in game.worldState.newWorld.units)
      if (unit.ownerId == humanPlayerId && isSpyUnit(unit.type)) unit,
  ];
}
