import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';

import '../config/ga_config.dart';
import '../engine/ga_seeds.dart';
import '../genetics/operators.dart';

/// A prior-generation winner eligible for 7-GP opponent seating.
class PriorGenerationWinner {
  const PriorGenerationWinner({
    required this.profile,
    required this.fitness,
    required this.generation,
  });

  final AiProfile profile;
  final double fitness;
  final int generation;
}

/// Builds the six opponent profiles (`gp2`–`gp7`) for a 7-GP stage.
///
/// [subjectProfile] is always seated as `gp1` by the caller and is excluded
/// from opponents. SPEC/program/ga-runner.md. Refs #3488.
List<AiProfile> buildSevenGpOpponentRoster({
  required AiProfile subjectProfile,
  required List<PriorGenerationWinner> priorWinners,
  required List<AiProfile> blessedProfiles,
  required GaConfig config,
  required math.Random rng,
  required int masterSeed,
  required int generation,
  required int subjectIndex,
}) {
  final opponents = <AiProfile>[];
  final usedProfileIds = <String>{subjectProfile.profileId};

  void tryAdd(AiProfile profile) {
    if (opponents.length >= 6) return;
    if (usedProfileIds.contains(profile.profileId)) return;
    opponents.add(profile);
    usedProfileIds.add(profile.profileId);
  }

  final ordered = _orderPriorWinners(
    priorWinners: priorWinners,
    selection: config.sevenGpOpponentSelection,
    masterSeed: masterSeed,
    generation: generation,
    subjectIndex: subjectIndex,
  );
  for (final winner in ordered) {
    tryAdd(winner.profile);
  }

  if (config.sevenGpUseBlessedProfiles) {
    for (final blessed in blessedProfiles) {
      tryAdd(blessed);
    }
  }

  var remaining = 6 - opponents.length;
  if (remaining <= 0) {
    return opponents;
  }

  var defaultSeats = math.min(config.sevenGpFallbackDefaultAiSeats, remaining);
  var randomSeats = remaining - defaultSeats;

  for (final leaderId in seedAiProfileLeaderIds) {
    if (defaultSeats <= 0) break;
    final leader = seedAiProfilesById[leaderId]!;
    if (usedProfileIds.contains(leader.profileId)) continue;
    tryAdd(leader);
    defaultSeats--;
    remaining--;
  }

  randomSeats += defaultSeats;
  for (var seat = 0; seat < randomSeats; seat++) {
    final seedProfile = seedAiProfiles[rng.nextInt(seedAiProfiles.length)];
    final seatSeed = deriveSevenGpSeatSeed(
      masterSeed,
      generation,
      subjectIndex,
      opponents.length + seat,
    );
    final mutatedBase = mutateProfile(seedProfile, math.Random(seatSeed));
    tryAdd(
      AiProfile(
        schemaVersion: mutatedBase.schemaVersion,
        profileId: 'seven-gp-rand-$generation-$subjectIndex-$seat',
        displayName: 'seven-gp-rand-$generation-$subjectIndex-$seat',
        parameters: mutatedBase.parameters,
      ),
    );
  }

  if (opponents.length != 6) {
    throw StateError(
      '7-GP roster must seat 6 opponents (got ${opponents.length})',
    );
  }
  return opponents;
}

/// Orders the prior-generation-winner pool for seating per the configured
/// [selection] policy. SPEC/program/ga-runner.md § Opponent selection modes.
/// Refs #3488.
///
/// * `top_fitness`: fitness descending, generation ascending tiebreak.
/// * `random`: deterministic seeded shuffle keyed by
///   [deriveSevenGpSelectionSeed] so the order is identical for fixed master
///   seed, generation, subject index, and pool.
List<PriorGenerationWinner> _orderPriorWinners({
  required List<PriorGenerationWinner> priorWinners,
  required String selection,
  required int masterSeed,
  required int generation,
  required int subjectIndex,
}) {
  final ordered = List<PriorGenerationWinner>.from(priorWinners);
  switch (selection) {
    case 'top_fitness':
      ordered.sort((a, b) {
        final byFitness = b.fitness.compareTo(a.fitness);
        if (byFitness != 0) return byFitness;
        return a.generation.compareTo(b.generation);
      });
      return ordered;
    case 'random':
      final selectionRng = math.Random(
        deriveSevenGpSelectionSeed(masterSeed, generation, subjectIndex),
      );
      for (var i = ordered.length - 1; i > 0; i--) {
        final j = selectionRng.nextInt(i + 1);
        final tmp = ordered[i];
        ordered[i] = ordered[j];
        ordered[j] = tmp;
      }
      return ordered;
    default:
      throw StateError(
        'unsupported seven_gp_opponent_selection: $selection',
      );
  }
}
