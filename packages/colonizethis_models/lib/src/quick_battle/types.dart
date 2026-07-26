/// Quick Battle enums and unit-level types. SPEC/game/quick-battle.md.

/// Lane position. LEFT, CENTER, RIGHT, RESERVE.
enum QuickBattleLane { left, center, right, reserve }

/// Line position. FRONT, SUPPORT (non-reserve lanes only).
enum QuickBattleLine { front, support }

/// Lane terrain tag. Modifies combat strength per quick-battle-resolution.
enum QuickBattleLaneTerrain { open, hill, woods, town, swamp }

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
  const QuickBattleRoundActions({
    this.actions = const [],
    this.attackerActions,
    this.defenderActions,
  });

  /// Backward-compatible action list for both sides.
  final List<QuickBattleAction> actions;

  /// Optional side-specific attacker actions for the round.
  final List<QuickBattleAction>? attackerActions;

  /// Optional side-specific defender actions for the round.
  final List<QuickBattleAction>? defenderActions;
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
  }) => QuickBattleGroup(
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

/// Virtual emplaced fort gun at Quick Battle input build time. Not a [Unit] in WorldState.
/// SPEC/program/quick-battle-resolution.md, SPEC/game/quick-battle.md.
class QuickBattleEmplacedGun {
  const QuickBattleEmplacedGun({
    required this.id,
    required this.maxHp,
    required this.hp,
    required this.attackStrength,
    required this.defenseStrength,
    required this.rng,
  });

  final String id;
  final int maxHp;
  final int hp;
  final double attackStrength;
  final double defenseStrength;
  final int rng;

  QuickBattleEmplacedGun copyWith({
    String? id,
    int? maxHp,
    int? hp,
    double? attackStrength,
    double? defenseStrength,
    int? rng,
  }) => QuickBattleEmplacedGun(
    id: id ?? this.id,
    maxHp: maxHp ?? this.maxHp,
    hp: hp ?? this.hp,
    attackStrength: attackStrength ?? this.attackStrength,
    defenseStrength: defenseStrength ?? this.defenseStrength,
    rng: rng ?? this.rng,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'maxHp': maxHp,
    'hp': hp,
    'attackStrength': attackStrength,
    'defenseStrength': defenseStrength,
    'rng': rng,
  };

  static QuickBattleEmplacedGun fromJson(Map<String, dynamic> json) =>
      QuickBattleEmplacedGun(
        id: json['id'] as String,
        maxHp: json['maxHp'] as int,
        hp: json['hp'] as int,
        attackStrength: (json['attackStrength'] as num).toDouble(),
        defenseStrength: (json['defenseStrength'] as num).toDouble(),
        rng: json['rng'] as int,
      );
}

/// Per-gun state after Quick Battle (for determinism AC / replay).
class QuickBattleEmplacedGunOutcome {
  const QuickBattleEmplacedGunOutcome({
    required this.id,
    required this.hp,
    required this.destroyed,
  });

  final String id;
  final int hp;
  final bool destroyed;

  Map<String, dynamic> toJson() => {'id': id, 'hp': hp, 'destroyed': destroyed};

  static QuickBattleEmplacedGunOutcome fromJson(Map<String, dynamic> json) =>
      QuickBattleEmplacedGunOutcome(
        id: json['id'] as String,
        hp: json['hp'] as int,
        destroyed: json['destroyed'] as bool? ?? false,
      );
}
