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

/// Setup for saved-game scenarios (unit injection, economy state).
class ScenarioSetup {
  const ScenarioSetup({
    this.units,
    this.stockpileOverrides,
    this.initialStockpile,
    this.initialWorkers,
  });

  final List<UnitPlacement>? units;
  final Map<String, int>? stockpileOverrides;
  /// Player id → commodity id → quantity. Applied to player stockpile before turns.
  final Map<String, Map<String, int>>? initialStockpile;
  /// Player id → worker counts (peasants, apprentices, journeymen, masters). Applied to WorkerPool before turns.
  final Map<String, Map<String, int>>? initialWorkers;
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

/// Scripted orders for a single turn.
class TurnScript {
  const TurnScript({
    required this.turn,
    required this.orders,
    this.workerAssignments,
  });

  final int turn;
  final List<OrderCommand> orders;
  /// Production phase: recipe assignments for this turn (defaultAssignments).
  final List<WorkerAssignment>? workerAssignments;
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
    this.fleetId,
    this.destinationSeaZoneId,
    this.mission,
    this.targetPortId,
    this.targetProvinceId,
  });

  final String player;
  final String type; // move, build, work, diplomatic, research, naval_move, naval_mission
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
  // Naval move fields
  final String? fleetId;
  final String? destinationSeaZoneId;
  // Naval mission fields
  final String? mission;
  final String? targetPortId;
  final String? targetProvinceId;
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
    this.relationWith,
    this.relationState,
    this.relationScore,
    this.relationLevel,
    this.relationSinceTurn,
    this.relationLastInteractionTurn,
    this.overtureStage,
    this.capitalProvince,
  });

  /// Which turn to check (null = final state)
  final int? turn;
  /// Region ID (e.g., "oldWorld", "newWorld") - optional, used with province
  final String? region;
  final String? province;
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
}

/// Type of value matching for assertions.
enum MatchType {
  exact,
  range,
  atLeast,
  atMost,
}

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
    turns: (json['turns'] as List<dynamic>?)
            ?.map((t) => _parseTurnScript(t as Map<String, dynamic>))
            .toList() ??
        [],
    assertions: (json['assertions'] as List<dynamic>?)
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
    if (raw is! Map) return null;
    final result = <String, Map<String, int>>{};
    for (final entry in (raw as Map<String, dynamic>).entries) {
      if (entry.value is Map) {
        final inner = <String, int>{};
        for (final e in (entry.value as Map).entries) {
          final v = e.value;
          inner[e.key.toString()] = v is int ? v : (int.tryParse('$v') ?? 0);
        }
        result[entry.key] = inner;
      }
    }
    return result.isEmpty ? null : result;
  }

  Map<String, Map<String, int>>? _parseInitialWorkers(dynamic raw) {
    if (raw is! Map) return null;
    final result = <String, Map<String, int>>{};
    for (final entry in (raw as Map<String, dynamic>).entries) {
      if (entry.value is Map) {
        final inner = <String, int>{};
        for (final e in (entry.value as Map).entries) {
          final v = e.value;
          inner[e.key.toString()] = v is int ? v : (int.tryParse('$v') ?? 0);
        }
        result[entry.key] = inner;
      }
    }
    return result.isEmpty ? null : result;
  }

  return ScenarioSetup(
    units: (json['units'] as List<dynamic>?)
        ?.map((u) => _parseUnitPlacement(u as Map<String, dynamic>))
        .toList(),
    stockpileOverrides: (json['stockpileOverrides'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, v as int)),
    initialStockpile: _parseInitialStockpile(json['initialStockpile']),
    initialWorkers: _parseInitialWorkers(json['initialWorkers']),
  );
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
    if (raw is! List) return null;
    final list = <WorkerAssignment>[];
    for (final e in raw) {
      if (e is! Map) continue;
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
    orders: (json['orders'] as List<dynamic>?)
            ?.map((o) => _parseOrderCommand(o as Map<String, dynamic>))
            .toList() ??
        [],
    workerAssignments: _parseWorkerAssignments(json['workerAssignments']),
  );
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
    fleetId: json['fleetId'] as String?,
    destinationSeaZoneId: json['destinationSeaZoneId'] as String?,
    mission: json['mission'] as String?,
    targetPortId: json['targetPortId'] as String?,
    targetProvinceId: json['targetProvinceId'] as String?,
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
    everyTileResourceAllowedInRegion: json['everyTileResourceAllowedInRegion'] as bool?,
    relationWith: json['relationWith'] as String?,
    relationState: json['relationState'] as String?,
    relationScore: json['relationScore'] as int?,
    relationLevel: json['relationLevel'] as String?,
    relationSinceTurn: json['relationSinceTurn'] as int?,
    relationLastInteractionTurn: json['relationLastInteractionTurn'] as int?,
    overtureStage: json['overtureStage'] as String?,
    capitalProvince: json['capitalProvince'] as String?,
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
    return json.map((e) => parseScenarioFromJson(e as Map<String, dynamic>)).toList();
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
