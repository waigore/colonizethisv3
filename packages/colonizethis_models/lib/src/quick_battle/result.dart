import 'types.dart';

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
