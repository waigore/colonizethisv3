/// Quick Battle models. SPEC/game/quick-battle.md, quick-battle-resolution.md.

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
  }) => QuickBattleDeployment(
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
          .map(
            (e) => QuickBattleGroup.fromJson(
              Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
            ),
          )
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
/// Leader multipliers (SPEC/game/leader-bonuses.md) apply to each side's effective strength.
class QuickBattleInput {
  const QuickBattleInput({
    required this.attackerFactionId,
    required this.defenderFactionId,
    required this.provinceId,
    required this.regionId,
    required this.attackerDeployment,
    required this.defenderDeployment,
    this.fortLevel = 0,
    this.emplacedGuns = const [],
    this.provinceTerrain = 'plains',
    this.seed = 0,
    this.maxRounds = 3,
    this.attackerLeaderMultiplier = 1.0,
    this.defenderLeaderMultiplier = 1.0,
    this.attackerCavalryShare = 0.0,
    this.defenderCavalryShare = 0.0,
    this.attackerGeneralMedals = 0,
    this.defenderGeneralMedals = 0,
  });

  final String attackerFactionId;
  final String defenderFactionId;
  final String provinceId;
  final String regionId;
  final QuickBattleDeployment attackerDeployment;
  final QuickBattleDeployment defenderDeployment;
  final int fortLevel;

  /// Virtual emplaced guns (siege). Empty when [fortLevel] == 0 or no fort.
  final List<QuickBattleEmplacedGun> emplacedGuns;
  final String provinceTerrain;
  final int seed;
  final int maxRounds;

  /// Leader combat bonus multiplier for attacker side. SPEC/game/leader-bonuses.md.
  final double attackerLeaderMultiplier;

  /// Leader combat bonus multiplier for defender side. SPEC/game/leader-bonuses.md.
  final double defenderLeaderMultiplier;

  /// Initiative input from combat formula: cavalry units share in [0.0, 1.0].
  final double attackerCavalryShare;
  final double defenderCavalryShare;

  /// Initiative input from combat formula: medals contribution.
  final int attackerGeneralMedals;
  final int defenderGeneralMedals;

  Map<String, dynamic> toJson() => {
    'attackerFactionId': attackerFactionId,
    'defenderFactionId': defenderFactionId,
    'provinceId': provinceId,
    'regionId': regionId,
    'attackerDeployment': attackerDeployment.toJson(),
    'defenderDeployment': defenderDeployment.toJson(),
    'fortLevel': fortLevel,
    'emplacedGuns': emplacedGuns.map((g) => g.toJson()).toList(),
    'provinceTerrain': provinceTerrain,
    'seed': seed,
    'maxRounds': maxRounds,
    'attackerLeaderMultiplier': attackerLeaderMultiplier,
    'defenderLeaderMultiplier': defenderLeaderMultiplier,
    'attackerCavalryShare': attackerCavalryShare,
    'defenderCavalryShare': defenderCavalryShare,
    'attackerGeneralMedals': attackerGeneralMedals,
    'defenderGeneralMedals': defenderGeneralMedals,
  };

  static QuickBattleInput fromJson(Map<String, dynamic> json) =>
      QuickBattleInput(
        attackerFactionId: json['attackerFactionId'] as String,
        defenderFactionId: json['defenderFactionId'] as String,
        provinceId: json['provinceId'] as String,
        regionId: json['regionId'] as String,
        attackerDeployment: QuickBattleDeployment.fromJson(
          Map<String, dynamic>.from(
            json['attackerDeployment'] as Map<dynamic, dynamic>,
          ),
        ),
        defenderDeployment: QuickBattleDeployment.fromJson(
          Map<String, dynamic>.from(
            json['defenderDeployment'] as Map<dynamic, dynamic>,
          ),
        ),
        fortLevel: json['fortLevel'] as int? ?? 0,
        emplacedGuns: (json['emplacedGuns'] as List<dynamic>? ?? [])
            .map(
              (e) => QuickBattleEmplacedGun.fromJson(
                Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
              ),
            )
            .toList(),
        provinceTerrain: json['provinceTerrain'] as String? ?? 'plains',
        seed: json['seed'] as int? ?? 0,
        maxRounds: json['maxRounds'] as int? ?? 3,
        attackerLeaderMultiplier:
            (json['attackerLeaderMultiplier'] as num?)?.toDouble() ?? 1.0,
        defenderLeaderMultiplier:
            (json['defenderLeaderMultiplier'] as num?)?.toDouble() ?? 1.0,
        attackerCavalryShare:
            (json['attackerCavalryShare'] as num?)?.toDouble() ?? 0.0,
        defenderCavalryShare:
            (json['defenderCavalryShare'] as num?)?.toDouble() ?? 0.0,
        attackerGeneralMedals: json['attackerGeneralMedals'] as int? ?? 0,
        defenderGeneralMedals: json['defenderGeneralMedals'] as int? ?? 0,
      );
}

/// Result of Quick Battle. Consumable by combat pipeline.
enum QuickBattleWinner { attacker, defender, mutualExhaustion }

class QuickBattleResult {
  const QuickBattleResult({
    required this.winner,
    required this.attackerCasualties,
    required this.defenderCasualties,
    required this.provinceFlips,
    this.attackerRouts = false,
    this.defenderRouts = false,
    this.fortDowngradeFromDestroyedEmplaced = false,
    this.emplacedGunOutcomes = const [],
  });

  final QuickBattleWinner winner;
  final List<String> attackerCasualties;
  final List<String> defenderCasualties;
  final bool provinceFlips;
  final bool attackerRouts;
  final bool defenderRouts;

  /// True iff all virtual emplaced guns were destroyed (siege Quick Battle).
  final bool fortDowngradeFromDestroyedEmplaced;
  final List<QuickBattleEmplacedGunOutcome> emplacedGunOutcomes;

  Map<String, dynamic> toJson() => {
    'winner': winner.name,
    'attackerCasualties': attackerCasualties,
    'defenderCasualties': defenderCasualties,
    'provinceFlips': provinceFlips,
    'attackerRouts': attackerRouts,
    'defenderRouts': defenderRouts,
    'fortDowngradeFromDestroyedEmplaced': fortDowngradeFromDestroyedEmplaced,
    'emplacedGunOutcomes': emplacedGunOutcomes.map((o) => o.toJson()).toList(),
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
        fortDowngradeFromDestroyedEmplaced:
            json['fortDowngradeFromDestroyedEmplaced'] as bool? ?? false,
        emplacedGunOutcomes:
            (json['emplacedGunOutcomes'] as List<dynamic>? ?? [])
                .map(
                  (e) => QuickBattleEmplacedGunOutcome.fromJson(
                    Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
                  ),
                )
                .toList(),
      );
}
