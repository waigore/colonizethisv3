// Scenario models and JSON parsing.

import 'dart:convert';
import 'dart:io';

/// Represents a complete scenario test case.
class Scenario {
  const Scenario({
    required this.name,
    required this.description,
    required this.init,
    this.setup,
    required this.turns,
    required this.assertions,
  });

  final String name;
  final String description;
  final ScenarioInit init;
  final ScenarioSetup? setup;
  final List<TurnScript> turns;
  final List<Assertion> assertions;
}

/// Initialization source for a scenario.
class ScenarioInit {
  const ScenarioInit({
    required this.type,
    this.config,
    this.gameId,
    this.oldWorld,
    this.newWorld,
  });

  /// 'fresh', 'saved', or 'fromTopology'
  final String type;
  final Map<String, dynamic>? config;
  final String? gameId;

  /// For fromTopology: { grid, nodes, edges } for Old World.
  final Map<String, dynamic>? oldWorld;

  /// For fromTopology: { grid, nodes, edges } for New World (optional).
  final Map<String, dynamic>? newWorld;
}

/// Setup for saved-game scenarios (unit injection, resource overrides).
/// initialWorkers / initialStockpile apply after init (fresh or fromTopology).
/// initialTileState: tileKey → { improvementLevel, roadLevel } for extraction scenarios. SPEC/game/extraction-and-improvements.md.
/// leaderKeys: player id → leaderKey (SPEC/game/leader-bonuses.md); applied to Player.leaderKey after init.
/// initialTech: player id → list of tech ids. Overrides Player.techUnlocked for buildability scenarios. SPEC/game/military-units.md.
/// initialTreasury: player id → treasury (integer pounds). Overrides Player.treasury. SPEC/game/diplomacy.md (Join Empire scenarios).
/// defaultCombatMode: optional "quickBattle" or "autoResolve". Overrides Game.defaultCombatMode. SPEC/game/quick-battle.md.
class ScenarioSetup {
  const ScenarioSetup({
    this.units,
    this.initialFleets,
    this.stockpileOverrides,
    this.initialWorkers,
    this.initialStockpile,
    this.productionAssignments,
    this.initialTileState,
    this.leaderKeys,
    this.initialTech,
    this.initialTreasury,
    this.defaultCombatMode,
    this.purchasedTilesByTileKey,
  });

  final List<UnitPlacement>? units;
  final List<FleetPlacement>? initialFleets;
  final Map<String, int>? stockpileOverrides;

  /// Player id → { peasants, apprentices, journeymen, masters }. SPEC/game/workers-and-population.md.
  final Map<String, Map<String, int>>? initialWorkers;

  /// Player id → { commodityId: quantity }. Replaces player stockpile.
  final Map<String, Map<String, int>>? initialStockpile;

  /// Recipe assignments for Production phase (each turn). SPEC/game/stockpiles-and-production.md.
  final List<ProductionAssignment>? productionAssignments;

  /// Tile key → { improvementLevel: 0-4, roadLevel: 0|1|2|4 }. Applied to worldState.tileState for extraction scenarios.
  final Map<String, Map<String, int>>? initialTileState;

  /// Player id → leaderKey. Overrides Player.leaderKey for leader-bonus scenarios. SPEC/game/leader-bonuses.md.
  final Map<String, String>? leaderKeys;

  /// Player id → list of tech ids. Overrides Player.techUnlocked (map techId → true). SPEC/game/military-units.md, SPEC/game/military-generals.md, tech-tree.
  final Map<String, List<String>>? initialTech;

  /// Player id → treasury (pounds). Overrides Player.treasury for Join Empire etc. SPEC/game/diplomacy.md.
  final Map<String, int>? initialTreasury;

  /// "quickBattle" or "autoResolve". Overrides Game.defaultCombatMode. SPEC/game/quick-battle.md.
  final String? defaultCombatMode;

  /// Tile key → player id. Overrides WorldState.purchasedTilesByTileKey for build_improvement on purchased foreign tiles. SPEC/game/civilian-units.md, SPEC/program/orders.md.
  final Map<String, String>? purchasedTilesByTileKey;
}

class FleetPlacement {
  const FleetPlacement({
    required this.id,
    required this.ownerId,
    required this.regionId,
    required this.shipTypeIds,
    this.seaZoneId,
    this.inPortAtProvinceId,
    this.mission = 'none',
  });

  final String id;
  final String ownerId;
  final String regionId;
  final List<String> shipTypeIds;
  final String? seaZoneId;
  final String? inPortAtProvinceId;
  final String mission;
}

/// One production assignment: recipe id and labour to assign. Converted to AssignedRecipe in runner.
class ProductionAssignment {
  const ProductionAssignment({
    required this.recipeId,
    required this.assignedLabour,
  });

  final String recipeId;
  final int assignedLabour;
}

/// Placement of a unit in a province for scenario setup.
class UnitPlacement {
  const UnitPlacement({
    required this.playerId,
    required this.unitType,
    required this.provinceId,
    this.count = 1,
  });

  final String playerId;
  final String unitType;
  final String provinceId;
  final int count;
}

/// Production assignment for one recipe in a turn. SPEC/game/production-recipes.md.
class WorkerAssignment {
  const WorkerAssignment({
    required this.recipeId,
    required this.assignedLabour,
  });

  final String recipeId;
  final int assignedLabour;
}

/// Scripted overture decision for a turn (when resolution blocks on human GP target).
/// SPEC/program/diplomacy-resolution.md, SPEC/program/turn-resolution-phases.md.
class OvertureDecisionScript {
  const OvertureDecisionScript({
    required this.offererGpId,
    required this.targetFactionId,
    required this.stage,
    required this.accepted,
  });

  final String offererGpId;
  final String targetFactionId;
  final String stage;
  final bool accepted;
}

/// Scripted call-to-arms response when turn resolution blocks on human ally.
class CallToArmsDecisionScript {
  const CallToArmsDecisionScript({
    required this.allyGpId,
    required this.defenderGpId,
    required this.aggressorGpId,
    required this.accepted,
  });

  final String allyGpId;
  final String defenderGpId;
  final String aggressorGpId;
  final bool accepted;
}

/// Scripted orders for a single turn.
class TurnScript {
  const TurnScript({
    required this.turn,
    required this.orders,
    this.workerAssignments,
    this.overtureDecisions,
    this.callToArmsDecisions,
  });

  final int turn;
  final List<OrderCommand> orders;

  /// Production phase: recipe assignments for this turn (defaultAssignments).
  final List<WorkerAssignment>? workerAssignments;

  /// When turn resolution returns pending overtures (human GP target), these
  /// decisions are applied via resumeTurnResolutionWithOvertureDecisions.
  final List<OvertureDecisionScript>? overtureDecisions;

  /// When turn resolution returns pending call to arms, applied via
  /// resumeTurnResolutionWithCallToArmsDecisions.
  final List<CallToArmsDecisionScript>? callToArmsDecisions;
}

/// A single order command from a scenario.
class OrderCommand {
  const OrderCommand({
    required this.player,
    required this.type,
    this.unit,
    this.to,
    this.unitType,
    this.inProvince,
    this.workType,
    this.workers,
    this.techId,
    this.slotIndex,
    this.targetFactionId,
    this.diplomaticType,
    this.amount,
    this.overtureStage,
    this.fleetId,
    this.destinationSeaZoneId,
    this.destinationPortProvinceId,
    this.mission,
    this.targetPortId,
    this.targetProvinceId,
    this.targetTileKey,
  });

  final String player;
  final String
  type; // move, build, work, diplomatic, research, naval_move, naval_mission
  // Move fields
  final String? unit;
  final String? to;
  // Build fields
  final String? unitType;
  final String? inProvince;
  // Work fields
  final String? workType;
  final int? workers;
  // Research fields
  final String? techId;
  final int? slotIndex;
  // Diplomatic fields
  final String? targetFactionId;
  final String? diplomaticType;
  final int? amount;
  final String? overtureStage;
  // Naval move fields
  final String? fleetId;
  final String? destinationSeaZoneId;
  final String? destinationPortProvinceId;
  // Naval mission fields
  final String? mission;
  final String? targetPortId;
  final String? targetProvinceId;

  /// Optional explicit tile key for work orders (tile-level targets).
  final String? targetTileKey;
}

/// Assertion for state verification.
class Assertion {
  const Assertion({
    this.turn,
    this.region,
    this.province,
    this.player,
    this.owner,
    this.notOwner,
    this.unitCount,
    this.hasUnit,
    this.hasPlayerUnits,
    this.stockpile,
    this.stockpileCommodity,
    this.commodity,
    this.treasury,
    this.matchMin,
    this.matchMax,
    this.matchType = MatchType.exact,
    this.resource,
    this.maxBothFraction,
    this.everyTileResourceAllowedInRegion,
    this.capitalProvinceId,
    this.capitalTileKey,
    this.relationWith,
    this.relationState,
    this.relationScore,
    this.relationLevel,
    this.relationSinceTurn,
    this.relationLastInteractionTurn,
    this.overtureStage,
    this.capitalProvince,
    this.workerPeasants,
    this.workerApprentices,
    this.workerJourneymen,
    this.workerMasters,
    this.greatPowerCount,
    this.minorNationCount,
    this.tribeCount,
    this.tileKey,
    this.tileVisibility,
    this.tileProspected,
    this.tileImprovementName,
    this.leaderKey,
    this.techUnlocked,
    this.provinceDisplayName,
    this.tileRoadLevel,
    this.tileImprovementLevel,
    this.generalCount,
    this.effectiveMilitaryLevel,
    this.victoryWinner,
    this.victoryType,
    this.victoryTurn,
    this.fleetShipCount,
  });

  /// Which turn to check (null = final state)
  final int? turn;

  /// Region ID (e.g., "oldWorld", "newWorld") - optional, used with province
  final String? region;
  final String? province;

  /// Province display name (SPEC/game/naming.md). Use with [province]: expected Province.displayName.
  final String? provinceDisplayName;
  final String? player;
  final String? owner;

  /// Negative assertion: province must not be owned by this player id.
  final String? notOwner;
  final int? unitCount;
  final String? hasUnit;
  final String? hasPlayerUnits;
  final int? stockpile;

  /// With [player] and [commodity]: expected quantity of that commodity in stockpile. SPEC/game/production-recipes.md.
  final int? stockpileCommodity;

  /// Commodity id for [stockpileCommodity] assertion.
  final String? commodity;
  final int? treasury;
  final int? matchMin;
  final int? matchMax;
  final MatchType matchType;

  /// With region: no tile in region has this resource (regionHasNoResource). SPEC/game/resource-terrain-region-rules.md.
  final String? resource;

  /// With region: fraction of placed resources that are "both" must be <= this (resourcePlacementCap).
  final double? maxBothFraction;

  /// Every tile's resource is allowed in its region per resource rules. Optional region scopes to one region.
  final bool? everyTileResourceAllowedInRegion;

  /// Diplomacy assertions (SPEC/game/diplomacy.md)
  /// Relation between [player] and [relationWith].
  final String? relationWith;
  final String? relationState;
  final int? relationScore;
  final String? relationLevel;
  final int? relationSinceTurn;
  final int? relationLastInteractionTurn;

  /// Overture stage between GP [player] and Minor/Tribe [relationWith].
  final String? overtureStage;

  /// Capital province for [player] (Great Power). Full province id, e.g. oldWorld|p1. SPEC/game/capital-choice-phase.md.
  final String? capitalProvince;

  /// Capital assertion: expected capital province id (full id, e.g. oldWorld|p1). Used with player (faction id).
  final String? capitalProvinceId;

  /// Capital assertion: expected capital tile key (regionId|provinceId|x|y). Optional.
  final String? capitalTileKey;

  /// Worker pool assertions (SPEC/game/workers-and-population.md). Require [player].
  final int? workerPeasants;
  final int? workerApprentices;
  final int? workerJourneymen;
  final int? workerMasters;

  /// Faction count assertions (SPEC/game/factions.md). After game setup, assert counts of Great Powers, Minor Nations, Tribes.
  final int? greatPowerCount;
  final int? minorNationCount;
  final int? tribeCount;

  /// Fog/exploration assertions (SPEC/game/fog-and-exploration.md). Require [player].
  /// [tileKey]: format regionId|provinceId|x|y.
  /// [tileVisibility]: expected visibility level for that player at tileKey (unknown, revealed, fogged, fullyVisible).
  /// [tileProspected]: true iff that player has prospected the tile at tileKey.
  final String? tileKey;
  final String? tileVisibility;
  final bool? tileProspected;

  /// Improvement naming assertion (SPEC/game/extraction-and-improvements.md).
  /// With [tileKey]: expected improvement display name derived from the tile's resource id.
  /// Example: tile with resource `grain` and improvementLevel 1-4 → `Farm`.
  final String? tileImprovementName;

  /// Leader assertion (SPEC/game/leader-bonuses.md). With [player]: expected leaderKey for that Great Power.
  final String? leaderKey;

  /// Research-state assertion (SPEC/game/research-state.md). With [player]: list of tech ids that must be in techUnlocked (true).
  final List<String>? techUnlocked;

  /// Road / transport-level assertion (SPEC/game/capital-and-connectivity.md, SPEC/program/development-resolution.md).
  /// With [tileKey]: expected road/transport level on that tile (0, 1, 2, or 4).
  final int? tileRoadLevel;

  /// Improvement level assertion (SPEC/game/extraction-and-improvements.md). With [tileKey]: expected improvement level (0-4).
  final int? tileImprovementLevel;

  /// General count assertion (SPEC/game/military-generals.md). With [player]: expected number of generals for that Great Power.
  final int? generalCount;

  /// Faction effective military level (SPEC/game/factions.md). With [player] (Minor or Tribe faction id): expected effectiveMilitaryLevel (minors get parity; tribes always 1).
  final int? effectiveMilitaryLevel;

  /// Victory assertions (SPEC/game/victory.md). [victoryWinner]: expected winner player id; [victoryType]: e.g. military; [victoryTurn]: turn when victory was set.
  final String? victoryWinner;
  final String? victoryType;
  final int? victoryTurn;

  /// Fleet ship count (SPEC/game/ships-and-naval.md). With [player]: total ships in that player's fleets (sum of shipTypeIds.length). Use [matchType] for atLeast/atMost/exact.
  final int? fleetShipCount;
}

/// Type of value matching for assertions.
enum MatchType { exact, range, atLeast, atMost }

// JSON Parsing

/// Parses a scenario from a JSON map.
Scenario parseScenarioFromJson(Map<String, dynamic> json) {
  return Scenario(
    name: json['name'] as String? ?? 'unnamed',
    description: json['description'] as String? ?? '',
    init: _parseScenarioInit(json['init'] as Map<String, dynamic>?),
    setup: json['setup'] != null
        ? _parseScenarioSetup(json['setup'] as Map<String, dynamic>)
        : null,
    turns:
        (json['turns'] as List<dynamic>?)
            ?.map((t) => _parseTurnScript(t as Map<String, dynamic>))
            .toList() ??
        [],
    assertions:
        (json['assertions'] as List<dynamic>?)
            ?.map((a) => _parseAssertion(a as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

ScenarioInit _parseScenarioInit(Map<String, dynamic>? json) {
  if (json == null) {
    return const ScenarioInit(type: 'fresh');
  }
  return ScenarioInit(
    type: json['type'] as String? ?? 'fresh',
    config: json['config'] as Map<String, dynamic>?,
    gameId: json['gameId'] as String?,
    oldWorld: json['oldWorld'] as Map<String, dynamic>?,
    newWorld: json['newWorld'] as Map<String, dynamic>?,
  );
}

ScenarioSetup _parseScenarioSetup(Map<String, dynamic> json) {
  Map<String, Map<String, int>>? _parseInitialStockpile(dynamic raw) {
    if (raw is! Map<dynamic, dynamic>) return null;
    final result = <String, Map<String, int>>{};
    for (final entry in (raw as Map<String, dynamic>).entries) {
      if (entry.value is Map<dynamic, dynamic>) {
        final inner = <String, int>{};
        for (final e in (entry.value as Map<dynamic, dynamic>).entries) {
          final v = e.value;
          inner[e.key.toString()] = v is int ? v : (int.tryParse('$v') ?? 0);
        }
        result[entry.key] = inner;
      }
    }
    return result.isEmpty ? null : result;
  }

  Map<String, Map<String, int>>? _parseInitialWorkers(dynamic raw) {
    if (raw is! Map<dynamic, dynamic>) return null;
    final result = <String, Map<String, int>>{};
    for (final entry in (raw as Map<String, dynamic>).entries) {
      if (entry.value is Map<dynamic, dynamic>) {
        final inner = <String, int>{};
        for (final e in (entry.value as Map<dynamic, dynamic>).entries) {
          final v = e.value;
          inner[e.key.toString()] = v is int ? v : (int.tryParse('$v') ?? 0);
        }
        result[entry.key] = inner;
      }
    }
    return result.isEmpty ? null : result;
  }

  Map<String, Map<String, int>>? _parseInitialTileState(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final result = <String, Map<String, int>>{};
    for (final entry in raw.entries) {
      if (entry.value is Map<dynamic, dynamic>) {
        final inner = <String, int>{};
        for (final e in (entry.value as Map<dynamic, dynamic>).entries) {
          final v = e.value;
          inner[e.key.toString()] = v is int ? v : (int.tryParse('$v') ?? 0);
        }
        result[entry.key] = inner;
      }
    }
    return result.isEmpty ? null : result;
  }

  Map<String, List<String>>? _parseInitialTech(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final result = <String, List<String>>{};
    for (final entry in raw.entries) {
      final list = entry.value;
      if (list is List<dynamic>) {
        result[entry.key] = list.map((e) => e.toString()).toList();
      }
    }
    return result.isEmpty ? null : result;
  }

  return ScenarioSetup(
    units: (json['units'] as List<dynamic>?)
        ?.map((u) => _parseUnitPlacement(u as Map<String, dynamic>))
        .toList(),
    initialFleets: (json['initialFleets'] as List<dynamic>?)
        ?.map((f) => _parseFleetPlacement(f as Map<String, dynamic>))
        .toList(),
    stockpileOverrides: (json['stockpileOverrides'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, v.toInt())),
    initialWorkers: _parseInitialWorkers(json['initialWorkers']),
    initialStockpile: _parseInitialStockpile(json['initialStockpile']),
    productionAssignments: _parseProductionAssignments(
      json['productionAssignments'],
    ),
    initialTileState: _parseInitialTileState(json['initialTileState']),
    leaderKeys: _parseLeaderKeys(json['leaderKeys']),
    initialTech: _parseInitialTech(json['initialTech']),
    initialTreasury: _parseInitialTreasury(json['initialTreasury']),
    defaultCombatMode: json['defaultCombatMode'] as String?,
    purchasedTilesByTileKey: _parsePurchasedTilesByTileKey(
      json['purchasedTilesByTileKey'],
    ),
  );
}

FleetPlacement _parseFleetPlacement(Map<String, dynamic> json) {
  return FleetPlacement(
    id: json['id'] as String,
    ownerId: json['ownerId'] as String,
    regionId: json['regionId'] as String,
    shipTypeIds: (json['shipTypeIds'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList(),
    seaZoneId: json['seaZoneId'] as String?,
    inPortAtProvinceId: json['inPortAtProvinceId'] as String?,
    mission: json['mission'] as String? ?? 'none',
  );
}

Map<String, String>? _parsePurchasedTilesByTileKey(dynamic raw) {
  if (raw is! Map<String, dynamic>) return null;
  final out = <String, String>{};
  for (final e in raw.entries) {
    final v = e.value;
    if (v != null && v.toString().isNotEmpty) out[e.key] = v.toString();
  }
  return out.isEmpty ? null : out;
}

Map<String, int>? _parseInitialTreasury(dynamic value) {
  if (value == null || value is! Map<dynamic, dynamic>) return null;
  final out = <String, int>{};
  for (final e in value.entries) {
    final v = e.value;
    if (v != null) out[e.key.toString()] = (v is int) ? v : v.toInt();
  }
  return out.isEmpty ? null : out;
}

Map<String, String>? _parseLeaderKeys(dynamic raw) {
  if (raw is! Map<String, dynamic>) return null;
  final out = <String, String>{};
  for (final e in raw.entries) {
    final v = e.value;
    if (v != null && v.toString().isNotEmpty) out[e.key] = v.toString();
  }
  return out.isEmpty ? null : out;
}

List<ProductionAssignment>? _parseProductionAssignments(dynamic raw) {
  if (raw is! List<dynamic> || raw.isEmpty) return null;
  final out = <ProductionAssignment>[];
  for (final e in raw) {
    if (e is! Map<String, dynamic>) continue;
    final recipeId = e['recipeId'] as String?;
    final labour = e['assignedLabour'];
    if (recipeId == null || recipeId.isEmpty || labour == null) continue;
    out.add(
      ProductionAssignment(
        recipeId: recipeId,
        assignedLabour: (labour as num).toInt(),
      ),
    );
  }
  return out.isEmpty ? null : out;
}

UnitPlacement _parseUnitPlacement(Map<String, dynamic> json) {
  return UnitPlacement(
    playerId: json['player'] as String,
    unitType: json['type'] as String,
    provinceId: json['province'] as String,
    count: json['count'] as int? ?? 1,
  );
}

TurnScript _parseTurnScript(Map<String, dynamic> json) {
  List<WorkerAssignment>? _parseWorkerAssignments(dynamic raw) {
    if (raw is! List<dynamic>) return null;
    final list = <WorkerAssignment>[];
    for (final e in raw) {
      if (e is! Map<dynamic, dynamic>) continue;
      final m = Map<String, dynamic>.from(e);
      final recipeId = m['recipeId'] as String?;
      final labour = m['assignedLabour'] as int? ?? 0;
      if (recipeId != null && recipeId.isNotEmpty && labour > 0) {
        list.add(WorkerAssignment(recipeId: recipeId, assignedLabour: labour));
      }
    }
    return list.isEmpty ? null : list;
  }

  return TurnScript(
    turn: json['turn'] as int,
    orders:
        (json['orders'] as List<dynamic>?)
            ?.map((o) => _parseOrderCommand(o as Map<String, dynamic>))
            .toList() ??
        [],
    workerAssignments: _parseWorkerAssignments(json['workerAssignments']),
    overtureDecisions: _parseOvertureDecisions(json['overtureDecisions']),
    callToArmsDecisions: _parseCallToArmsDecisions(json['callToArmsDecisions']),
  );
}

List<CallToArmsDecisionScript>? _parseCallToArmsDecisions(dynamic raw) {
  if (raw is! List<dynamic> || raw.isEmpty) return null;
  final list = <CallToArmsDecisionScript>[];
  for (final e in raw) {
    if (e is! Map<String, dynamic>) continue;
    final allyGpId = e['allyGpId'] as String?;
    final defenderGpId = e['defenderGpId'] as String?;
    final aggressorGpId = e['aggressorGpId'] as String?;
    final accepted = e['accepted'] as bool?;
    if (allyGpId == null ||
        defenderGpId == null ||
        aggressorGpId == null ||
        accepted == null) {
      continue;
    }
    list.add(
      CallToArmsDecisionScript(
        allyGpId: allyGpId,
        defenderGpId: defenderGpId,
        aggressorGpId: aggressorGpId,
        accepted: accepted,
      ),
    );
  }
  return list.isEmpty ? null : list;
}

List<OvertureDecisionScript>? _parseOvertureDecisions(dynamic raw) {
  if (raw is! List<dynamic> || raw.isEmpty) return null;
  final list = <OvertureDecisionScript>[];
  for (final e in raw) {
    if (e is! Map<String, dynamic>) continue;
    final offererGpId = e['offererGpId'] as String?;
    final targetFactionId = e['targetFactionId'] as String?;
    final stage = e['stage'] as String?;
    final accepted = e['accepted'] as bool?;
    if (offererGpId == null ||
        targetFactionId == null ||
        stage == null ||
        accepted == null)
      continue;
    list.add(
      OvertureDecisionScript(
        offererGpId: offererGpId,
        targetFactionId: targetFactionId,
        stage: stage,
        accepted: accepted,
      ),
    );
  }
  return list.isEmpty ? null : list;
}

OrderCommand _parseOrderCommand(Map<String, dynamic> json) {
  return OrderCommand(
    player: json['player'] as String,
    type: json['type'] as String,
    unit: json['unit'] as String?,
    to: json['to'] as String?,
    unitType: json['unitType'] as String?,
    inProvince: json['in'] as String?,
    workType: json['workType'] as String?,
    workers: json['workers'] as int?,
    techId: json['techId'] as String?,
    slotIndex: json['slotIndex'] as int?,
    targetFactionId: json['targetFactionId'] as String?,
    diplomaticType: json['diplomaticType'] as String?,
    amount: json['amount'] as int?,
    overtureStage: json['overtureStage'] as String?,
    fleetId: json['fleetId'] as String?,
    destinationSeaZoneId: json['destinationSeaZoneId'] as String?,
    destinationPortProvinceId: json['destinationPortProvinceId'] as String?,
    mission: json['mission'] as String?,
    targetPortId: json['targetPortId'] as String?,
    targetProvinceId: json['targetProvinceId'] as String?,
    targetTileKey: json['targetTileKey'] as String?,
  );
}

Assertion _parseAssertion(Map<String, dynamic> json) {
  return Assertion(
    turn: json['turn'] as int?,
    region: json['region'] as String?,
    province: json['province'] as String?,
    player: json['player'] as String?,
    owner: json['owner'] as String?,
    notOwner: json['notOwner'] as String?,
    unitCount: json['unitCount'] as int?,
    hasUnit: json['hasUnit'] as String?,
    hasPlayerUnits: json['hasPlayerUnits'] as String?,
    stockpile: json['stockpile'] as int?,
    stockpileCommodity: json['stockpileCommodity'] as int?,
    commodity: json['commodity'] as String?,
    treasury: json['treasury'] as int?,
    matchMin: json['matchMin'] as int?,
    matchMax: json['matchMax'] as int?,
    matchType: _parseMatchType(json['matchType'] as String?),
    resource: json['resource'] as String?,
    maxBothFraction: (json['maxBothFraction'] as num?)?.toDouble(),
    everyTileResourceAllowedInRegion:
        json['everyTileResourceAllowedInRegion'] as bool?,
    capitalProvinceId: json['capitalProvinceId'] as String?,
    capitalTileKey: json['capitalTileKey'] as String?,
    relationWith: json['relationWith'] as String?,
    relationState: json['relationState'] as String?,
    relationScore: json['relationScore'] as int?,
    relationLevel: json['relationLevel'] as String?,
    relationSinceTurn: json['relationSinceTurn'] as int?,
    relationLastInteractionTurn: json['relationLastInteractionTurn'] as int?,
    overtureStage: json['overtureStage'] as String?,
    capitalProvince: json['capitalProvince'] as String?,
    workerPeasants: json['workerPeasants'] as int?,
    workerApprentices: json['workerApprentices'] as int?,
    workerJourneymen: json['workerJourneymen'] as int?,
    workerMasters: json['workerMasters'] as int?,
    greatPowerCount: json['greatPowerCount'] as int?,
    minorNationCount: json['minorNationCount'] as int?,
    tribeCount: json['tribeCount'] as int?,
    tileKey: json['tileKey'] as String?,
    tileVisibility: json['tileVisibility'] as String?,
    tileProspected: json['tileProspected'] as bool?,
    tileImprovementName: json['tileImprovementName'] as String?,
    leaderKey: json['leaderKey'] as String?,
    techUnlocked: (json['techUnlocked'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList(),
    provinceDisplayName: json['provinceDisplayName'] as String?,
    tileRoadLevel: json['tileRoadLevel'] as int?,
    tileImprovementLevel: json['tileImprovementLevel'] as int?,
    generalCount: json['generalCount'] as int?,
    effectiveMilitaryLevel: json['effectiveMilitaryLevel'] as int?,
    victoryWinner: json['victoryWinner'] as String?,
    victoryType: json['victoryType'] as String?,
    victoryTurn: json['victoryTurn'] as int?,
    fleetShipCount: json['fleetShipCount'] as int?,
  );
}

MatchType _parseMatchType(String? value) {
  switch (value) {
    case 'range':
      return MatchType.range;
    case 'atLeast':
      return MatchType.atLeast;
    case 'atMost':
      return MatchType.atMost;
    default:
      return MatchType.exact;
  }
}

/// Parses a scenario file (can contain single scenario or array).
List<Scenario> parseScenarioFile(File file) {
  final content = file.readAsStringSync();
  final json = jsonDecode(content) as dynamic;

  if (json is List<dynamic>) {
    return json
        .map((e) => parseScenarioFromJson(e as Map<String, dynamic>))
        .toList();
  }
  return [parseScenarioFromJson(json as Map<String, dynamic>)];
}

/// Discovers all JSON scenario files in a directory.
List<Scenario> discoverScenarios(Directory dir) {
  final scenarios = <Scenario>[];
  if (!dir.existsSync()) return scenarios;

  for (final entity in dir.listSync()) {
    if (entity is File && entity.path.endsWith('.json')) {
      try {
        scenarios.addAll(parseScenarioFile(entity));
      } catch (e) {
        // Skip invalid files
        print('Warning: Failed to parse ${entity.path}: $e');
      }
    }
  }
  return scenarios;
}
