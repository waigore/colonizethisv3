import 'types.dart';

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

  /// Initiative input from combat formula: cavalry units shares in [0.0, 1.0].
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
