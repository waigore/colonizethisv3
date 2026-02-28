import 'package:colonizethis_models/colonizethis_models.dart';

/// Minor military parity step. SPEC/game/factions.md, SPEC/program/turn-resolution-phases.md.
///
/// At start of Combat phase: compute maxGreatPowerMilitaryLevel from all GPs;
/// set each MinorNation effectiveMilitaryLevel = max; set each Tribe effectiveMilitaryLevel = 1 (no parity).
Game applyMinorMilitaryParity(Game game) {
  int maxLevel = 1;
  for (final player in game.players) {
    final level = player.militaryLevel ?? 1;
    if (level > maxLevel) maxLevel = level;
  }

  final updatedMinors = <MinorNation>[];
  for (final m in game.minorNations) {
    updatedMinors.add(m.copyWith(effectiveMilitaryLevel: maxLevel));
  }

  const tribeEffectiveLevel = 1;
  final updatedTribes = <Tribe>[];
  for (final t in game.tribes) {
    updatedTribes.add(t.copyWith(effectiveMilitaryLevel: tribeEffectiveLevel));
  }

  if (updatedMinors.isEmpty && updatedTribes.isEmpty) return game;

  return game.copyWith(
    minorNations: updatedMinors.isEmpty ? game.minorNations : updatedMinors,
    tribes: updatedTribes.isEmpty ? game.tribes : updatedTribes,
  );
}
