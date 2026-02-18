/// Quick Battle models. SPEC/game/quick-battle.md, quick-battle-resolution.md.

/// Lane position. LEFT, CENTER, RIGHT, RESERVE.
enum QuickBattleLane {
  left,
  center,
  right,
  reserve,
}

/// Line position. FRONT, SUPPORT (non-reserve lanes only).
enum QuickBattleLine {
  front,
  support,
}

/// Lane terrain tag. Modifies combat strength per quick-battle-resolution.
enum QuickBattleLaneTerrain {
  open,
  hill,
  woods,
  town,
  swamp,
}

/// CP-based action. SPEC/game/quick-battle.md.
enum QuickBattleAction {
  volleyFire,
  defendEntrench,
  maneuver,
  fallBackRefuseFlank,
  assaultCharge,
}

/// Actions chosen by one side for a round. Cost: volleyFire/defend/maneuver 1 CP;
/// fallBack/assault 2 CP.
class QuickBattleRoundActions {
  const QuickBattleRoundActions({this.actions = const []});

  final List<QuickBattleAction> actions;
}

/// One battalion group (lane + line) with unit refs and cohesion.
class QuickBattleGroup {
  const QuickBattleGroup({
    required this.lane,
    required this.line,
    this.unitIds = const [],
    this.cohesion = 3,
  });

  final QuickBattleLane lane;
  final QuickBattleLine line;
  final List<String> unitIds;
  final int cohesion;

  QuickBattleGroup copyWith({
    QuickBattleLane? lane,
    QuickBattleLine? line,
    List<String>? unitIds,
    int? cohesion,
  }) =>
      QuickBattleGroup(
        lane: lane ?? this.lane,
        line: line ?? this.line,
        unitIds: unitIds ?? this.unitIds,
        cohesion: cohesion ?? this.cohesion,
      );

  Map<String, dynamic> toJson() => {
        'lane': lane.name,
        'line': line.name,
        'unitIds': unitIds,
        'cohesion': cohesion,
      };

  static QuickBattleGroup fromJson(Map<String, dynamic> json) =>
      QuickBattleGroup(
        lane: QuickBattleLane.values.firstWhere(
          (e) => e.name == json['lane'],
          orElse: () => QuickBattleLane.left,
        ),
        line: QuickBattleLine.values.firstWhere(
          (e) => e.name == json['line'],
          orElse: () => QuickBattleLine.front,
        ),
        unitIds: (json['unitIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        cohesion: json['cohesion'] as int? ?? 3,
      );
}

/// Deployment for one side (attacker or defender).
class QuickBattleDeployment {
  const QuickBattleDeployment({
    this.groups = const [],
    this.laneTerrain = const {},
  });

  final List<QuickBattleGroup> groups;
  final Map<String, QuickBattleLaneTerrain> laneTerrain;

  QuickBattleDeployment copyWith({
    List<QuickBattleGroup>? groups,
    Map<String, QuickBattleLaneTerrain>? laneTerrain,
  }) =>
      QuickBattleDeployment(
        groups: groups ?? this.groups,
        laneTerrain: laneTerrain ?? this.laneTerrain,
      );

  Map<String, dynamic> toJson() => {
        'groups': groups.map((g) => g.toJson()).toList(),
        'laneTerrain': laneTerrain.map((k, v) => MapEntry(k, v.name)),
      };

  static QuickBattleDeployment fromJson(Map<String, dynamic> json) {
    final groupsList = json['groups'] as List<dynamic>? ?? [];
    final terrainRaw = json['laneTerrain'] as Map<dynamic, dynamic>? ?? {};
    return QuickBattleDeployment(
      groups: groupsList
          .map((e) => QuickBattleGroup.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      laneTerrain: terrainRaw.map(
        (k, v) => MapEntry(
          k.toString(),
          QuickBattleLaneTerrain.values.firstWhere(
            (e) => e.name == v.toString(),
            orElse: () => QuickBattleLaneTerrain.open,
          ),
        ),
      ),
    );
  }
}

/// Input to Quick Battle resolution. SPEC/program/quick-battle-resolution.
class QuickBattleInput {
  const QuickBattleInput({
    required this.attackerFactionId,
    required this.defenderFactionId,
    required this.provinceId,
    required this.regionId,
    required this.attackerDeployment,
    required this.defenderDeployment,
    this.fortLevel = 0,
    this.provinceTerrain = 'plains',
    this.seed = 0,
    this.maxRounds = 3,
  });

  final String attackerFactionId;
  final String defenderFactionId;
  final String provinceId;
  final String regionId;
  final QuickBattleDeployment attackerDeployment;
  final QuickBattleDeployment defenderDeployment;
  final int fortLevel;
  final String provinceTerrain;
  final int seed;
  final int maxRounds;

  Map<String, dynamic> toJson() => {
        'attackerFactionId': attackerFactionId,
        'defenderFactionId': defenderFactionId,
        'provinceId': provinceId,
        'regionId': regionId,
        'attackerDeployment': attackerDeployment.toJson(),
        'defenderDeployment': defenderDeployment.toJson(),
        'fortLevel': fortLevel,
        'provinceTerrain': provinceTerrain,
        'seed': seed,
        'maxRounds': maxRounds,
      };

  static QuickBattleInput fromJson(Map<String, dynamic> json) =>
      QuickBattleInput(
        attackerFactionId: json['attackerFactionId'] as String,
        defenderFactionId: json['defenderFactionId'] as String,
        provinceId: json['provinceId'] as String,
        regionId: json['regionId'] as String,
        attackerDeployment: QuickBattleDeployment.fromJson(
          Map<String, dynamic>.from(json['attackerDeployment'] as Map),
        ),
        defenderDeployment: QuickBattleDeployment.fromJson(
          Map<String, dynamic>.from(json['defenderDeployment'] as Map),
        ),
        fortLevel: json['fortLevel'] as int? ?? 0,
        provinceTerrain: json['provinceTerrain'] as String? ?? 'plains',
        seed: json['seed'] as int? ?? 0,
        maxRounds: json['maxRounds'] as int? ?? 3,
      );
}

/// Result of Quick Battle. Consumable by combat pipeline.
enum QuickBattleWinner {
  attacker,
  defender,
  mutualExhaustion,
}

class QuickBattleResult {
  const QuickBattleResult({
    required this.winner,
    required this.attackerCasualties,
    required this.defenderCasualties,
    required this.provinceFlips,
    this.attackerRouts = false,
    this.defenderRouts = false,
  });

  final QuickBattleWinner winner;
  final List<String> attackerCasualties;
  final List<String> defenderCasualties;
  final bool provinceFlips;
  final bool attackerRouts;
  final bool defenderRouts;

  Map<String, dynamic> toJson() => {
        'winner': winner.name,
        'attackerCasualties': attackerCasualties,
        'defenderCasualties': defenderCasualties,
        'provinceFlips': provinceFlips,
        'attackerRouts': attackerRouts,
        'defenderRouts': defenderRouts,
      };

  static QuickBattleResult fromJson(Map<String, dynamic> json) =>
      QuickBattleResult(
        winner: QuickBattleWinner.values.firstWhere(
          (e) => e.name == json['winner'],
          orElse: () => QuickBattleWinner.mutualExhaustion,
        ),
        attackerCasualties: (json['attackerCasualties'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        defenderCasualties: (json['defenderCasualties'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        provinceFlips: json['provinceFlips'] as bool? ?? false,
        attackerRouts: json['attackerRouts'] as bool? ?? false,
        defenderRouts: json['defenderRouts'] as bool? ?? false,
      );
}
