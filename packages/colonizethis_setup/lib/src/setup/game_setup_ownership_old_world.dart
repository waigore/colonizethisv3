import 'dart:math';

import 'game_setup_ownership_paint.dart';

void assertGpProvincesOnAssignedLandmass({
  required String gpId,
  required int expectedLm,
  required Map<String, String> owners,
  required Map<String, int> landmassIds,
}) {
  for (final e in owners.entries) {
    if (e.value != gpId) continue;
    final pidLm = landmassIds[e.key];
    if (pidLm != expectedLm) {
      throw StateError(
        'GP $gpId violates one-continent rule: province ${e.key} is on '
        'landmass $pidLm but GP is assigned to $expectedLm',
      );
    }
  }
}

Map<String, String> assignOldWorldSingleLandmass({
  required int lmId,
  required Set<String> provs,
  required List<String> gpHere,
  required List<String> minorHere,
  required Map<String, int> targetPerGp,
  required int minProvincesPerMinor,
  required Map<String, String> gpSeeds,
  required Map<String, Set<String>> neighbours,
  required Map<String, int> landmassIds,
  required Random? assignmentRandom,
  required bool lockedSixMinorsOnFourContinents,
}) {
  final targets = <String, int>{
    for (final g in gpHere) g: targetPerGp[g]!,
    for (final m in minorHere) m: minProvincesPerMinor,
  };

  final mandatoryGpSeedProvinceByFaction = <String, String>{};
  for (final g in gpHere) {
    final seedEntry = gpSeeds.entries.firstWhere((e) => e.value == g);
    final sp = seedEntry.key;
    if (!provs.contains(sp)) {
      throw StateError(
        'GP $g sea-bound seed $sp not on expected landmass provinces',
      );
    }
    mandatoryGpSeedProvinceByFaction[g] = sp;
  }

  final factionIds = [...gpHere, ...minorHere];

  if (lockedSixMinorsOnFourContinents) {
    return paintLandmass(
      mode: LandmassPaintMode.locked,
      landmassProvinceIds: provs,
      neighbours: neighbours,
      factionIds: factionIds,
      targetPerFaction: targets,
      mandatorySeedProvinceByFaction: mandatoryGpSeedProvinceByFaction,
      assignmentRandom: assignmentRandom,
    );
  }

  final seeds = <String, String>{
    for (final e in mandatoryGpSeedProvinceByFaction.entries) e.value: e.key,
  };
  for (final m in minorHere) {
    final candidates = provs.difference(seeds.keys.toSet()).toList()..sort();
    if (candidates.isEmpty) {
      throw StateError('No province left for minor $m seed on landmass $lmId');
    }
    if (assignmentRandom != null) candidates.shuffle(assignmentRandom);
    seeds[candidates.first] = m;
  }
  final factionLandmassIds = {
    for (final g in gpHere) g: lmId,
    for (final m in minorHere) m: lmId,
  };
  // Cap total assignments so greedy leftovers cannot consume provinces reserved
  // for minors assigned later on the OW remainder (non-locked painting path).
  final maxTotalAssignment = targets.values.fold<int>(0, (a, b) => a + b);
  return paintLandmass(
    mode: LandmassPaintMode.bfs,
    landmassProvinceIds: Set<String>.from(provs),
    neighbours: neighbours,
    factionIds: factionIds,
    targetPerFaction: targets,
    bfsSeeds: seeds,
    landmassIds: landmassIds,
    factionLandmassIds: factionLandmassIds,
    maxTotal: maxTotalAssignment,
    assignmentRandom: assignmentRandom,
  );
}
