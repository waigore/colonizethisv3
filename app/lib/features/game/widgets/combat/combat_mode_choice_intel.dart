// Pre-battle force/fort snapshot for CMPT10001. Refs #4438.
// SPEC/ui/components/combat-mode-choice-intel.md.

import 'package:colonizethis_data/colonizethis_data.dart'
    show canUnitInitiateCombat, MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../unit_orders/move_army_invasion_intel.dart';

enum CombatModeChoiceRole { attacker, defender }

class CombatModeChoiceIntel {
  const CombatModeChoiceIntel({
    required this.role,
    required this.ownRegimentCount,
    this.ownTypesByRegimentId = const {},
    this.enemyRegimentCount,
    this.enemyTypesByRegimentId = const {},
    this.fortLevel,
    this.defendersUnknown = false,
  });

  final CombatModeChoiceRole role;
  final int ownRegimentCount;
  final Map<String, int> ownTypesByRegimentId;
  final int? enemyRegimentCount;
  final Map<String, int> enemyTypesByRegimentId;
  final int? fortLevel;
  final bool defendersUnknown;
}

String? resolveCombatModeChoiceProvinceId({
  required Game game,
  String? provinceId,
  required String provinceName,
}) {
  if (provinceId != null && provinceId.isNotEmpty) {
    return game.worldState.tryGetProvince(provinceId) == null
        ? null
        : provinceId;
  }
  if (provinceName.isEmpty) return null;
  String? match;
  for (final province in game.worldState.allProvinces()) {
    if (province.displayName != provinceName) continue;
    if (match != null) return null;
    match = province.id;
  }
  return match;
}

CombatModeChoiceIntel? combatModeChoiceIntelFromParams(
  Map<String, Object?>? params,
) {
  final game = params?['game'] as Game?;
  final humanPlayerId = params?['humanPlayerId'] as String?;
  final topology = params?['topology'] as MapTopology?;
  if (game == null || humanPlayerId == null || topology == null) {
    return null;
  }
  final provinceName = params?['provinceName'] as String? ?? '';
  final resolved = resolveCombatModeChoiceProvinceId(
    game: game,
    provinceId: params?['provinceId'] as String?,
    provinceName: provinceName,
  );
  if (resolved == null) return null;
  final playerView =
      params?['playerView'] as PlayerView? ??
      buildPlayerView(game, topology, humanPlayerId);
  return computeCombatModeChoiceIntel(
    game: game,
    humanPlayerId: humanPlayerId,
    provinceId: resolved,
    playerView: playerView,
  );
}

CombatModeChoiceIntel? computeCombatModeChoiceIntel({
  required Game game,
  required String humanPlayerId,
  required String provinceId,
  required PlayerView playerView,
}) {
  final province = game.worldState.tryGetProvince(provinceId);
  if (province == null) return null;
  final units = _combatCapableInProvince(game, provinceId);
  final own = [
    for (final unit in units)
      if (unit.ownerId == humanPlayerId) unit,
  ];
  final ownTypes = _typesById(own);
  if (province.ownerId == humanPlayerId) {
    final enemy = [
      for (final unit in units)
        if (unit.ownerId != humanPlayerId) unit,
    ];
    return CombatModeChoiceIntel(
      role: CombatModeChoiceRole.defender,
      ownRegimentCount: own.length,
      ownTypesByRegimentId: ownTypes,
      enemyRegimentCount: enemy.isEmpty ? null : enemy.length,
      enemyTypesByRegimentId: _typesById(enemy),
      fortLevel: province.fortLevel,
    );
  }
  final summary = computeMoveArmyInvasionIntelSummary(
    game: game,
    playerView: playerView,
    humanPlayerId: humanPlayerId,
    destinationProvinceId: provinceId,
  );
  if (summary.intelLevel == MoveArmyInvasionIntelLevel.unknown) {
    return CombatModeChoiceIntel(
      role: CombatModeChoiceRole.attacker,
      ownRegimentCount: own.length,
      ownTypesByRegimentId: ownTypes,
      defendersUnknown: true,
    );
  }
  final ownerId = province.ownerId;
  final ownerUnits = (ownerId == null || ownerId.isEmpty)
      ? const <Unit>[]
      : [
          for (final unit in units)
            if (unit.ownerId == ownerId) unit,
        ];
  final showEnemy = ownerUnits.isNotEmpty;
  return CombatModeChoiceIntel(
    role: CombatModeChoiceRole.attacker,
    ownRegimentCount: own.length,
    ownTypesByRegimentId: ownTypes,
    enemyRegimentCount: showEnemy ? ownerUnits.length : null,
    enemyTypesByRegimentId: showEnemy ? _typesById(ownerUnits) : const {},
    fortLevel: summary.fortLevel,
  );
}

List<Unit> _combatCapableInProvince(Game game, String provinceId) {
  final units = <Unit>[];
  for (final unit in game.worldState.allUnitsById.values) {
    if (unit.locationProvinceId != provinceId) continue;
    if (!canUnitInitiateCombat(unit.type)) continue;
    units.add(unit);
  }
  return units;
}

Map<String, int> _typesById(Iterable<Unit> units) {
  final byType = <String, int>{};
  for (final unit in units) {
    byType[unit.type] = (byType[unit.type] ?? 0) + 1;
  }
  return byType;
}
