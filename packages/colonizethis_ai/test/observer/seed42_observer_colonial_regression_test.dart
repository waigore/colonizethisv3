// Observer seed-42 turn-150 colonial expansion + economy regression
// gate (Refs #2848 / #2509 S7 / S4).
//
// Migrated to the shared [runSeed42ObserverCampaign] harness (Refs #3749
// step 2): the init / handoff / per-turn resolve loop is owned by
// `test/support/seed42_observer_campaign.dart`; this test reads only the
// campaign end game to assert the colonial expansion + improvement gates.
//
// Gate semantics pinned by this test (canonical source:
// `tool/run_observer_game/lib/observer_colonial_verify.dart`):
//   1. Every `newWorld|` province in `game.worldState.newWorld` is
//      owned by some Great Power gp1..gp6.
//   2. The fraction of GP-owned extractable resource tiles improved
//      (`improvementLevel >= 1`) is at least `kColonialImprovementMinRatio`
//      (0.70). Town tiles are excluded from the denominator.
//
// `kColonialImprovementMinRatio` mirrors the observer verifier's
// `kObserverColonialMinImprovementRatio` constant (0.70). The threshold
// is deliberately duplicated here rather than imported from the
// observer tool package to keep the ai-package test free of a
// `tool/run_observer_game` dependency (one-way dependency boundary:
// tools depend on packages, never the reverse).
//
// Skip-status precedent: see the S10 skip on
// `seed42_observer_conquest_regression_test.dart`. This test stays
// `skip`ped until either (a) #2848 (or the follow-up filed alongside)
// closes the colonial improvement gap on seed 42, or (b) the threshold
// is lowered intentionally via a SPEC change.
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'support/seed42_observer_campaign.dart';

/// Mirrors `kObserverColonialMinImprovementRatio` from
/// `tool/run_observer_game/lib/observer_colonial_verify.dart`. Kept as a
/// duplicate constant to avoid an `ai → tool` package dependency.
const double kColonialImprovementMinRatio = 0.70;

/// Mirrors `kObserverColonialCanonicalTurn` (150). The seed-42 colonial
/// gate is measured at this exact turn count.
const int kColonialRegressionTurns = 150;

/// Great Power factionIds the observer gate scopes to (gp1..gp6).
/// Matches `kObserverGreatPowerIds`.
const Set<String> kColonialRegressionGreatPowerIds = {
  'gp1',
  'gp2',
  'gp3',
  'gp4',
  'gp5',
  'gp6',
};

/// Province-id prefix for the New World region (mirrors
/// `kNewWorldProvinceIdPrefix` from the observer verifier).
const String _kNewWorldProvinceIdPrefix = 'newWorld|';

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'seed 42 turn $kColonialRegressionTurns: all newWorld provinces '
    'GP-owned AND extractable improvement ratio >= '
    '$kColonialImprovementMinRatio',
    () {
      final campaign = runSeed42ObserverCampaign(
        turns: kColonialRegressionTurns,
      );
      final game = campaign.finalGame;

      // AC1: every newWorld| province owned by a Great Power gp1..gp6.
      final nwProvinces = game.worldState.newWorld.provinces;
      final tribeHeldNwProvinces = <String>[];
      for (final p in nwProvinces) {
        if (!p.id.startsWith(_kNewWorldProvinceIdPrefix)) continue;
        final owner = p.ownerId;
        if (owner == null ||
            owner.isEmpty ||
            !kColonialRegressionGreatPowerIds.contains(owner)) {
          tribeHeldNwProvinces.add('${p.id}=${owner ?? "null"}');
        }
      }
      expect(
        tribeHeldNwProvinces,
        isEmpty,
        reason:
            'AC1 (Refs #2848 S0): every newWorld| province must be '
            'owned by gp1..gp6. Non-GP ownerships at turn '
            '$kColonialRegressionTurns: $tribeHeldNwProvinces',
      );

      // AC2: GP-owned extractable resource tiles improvement ratio
      // >= kColonialImprovementMinRatio. Denominator = extractable
      // resource tiles in GP-owned provinces minus town tile keys
      // (town tiles never carry resources per the world model);
      // numerator = those with improvementLevel >= 1.
      final gpOwnedProvinceIds = <String>{};
      final townTileKeys = <String>{};
      for (final region in <RegionData>[
        game.worldState.oldWorld,
        game.worldState.newWorld,
      ]) {
        for (final p in region.provinces) {
          final owner = p.ownerId;
          if (owner == null ||
              !kColonialRegressionGreatPowerIds.contains(owner)) {
            continue;
          }
          gpOwnedProvinceIds.add(p.id);
          final tk = p.townTileKey;
          if (tk != null && tk.isNotEmpty) {
            townTileKeys.add(tk);
          }
        }
      }
      var extractable = 0;
      var improved = 0;
      for (final entry in game.worldState.resourceByTileKey.entries) {
        final tileKey = entry.key;
        final resourceId = entry.value;
        if (resourceId.isEmpty) continue;
        final provinceId = Unit.provinceIdFromTileKey(tileKey);
        if (provinceId == null || !gpOwnedProvinceIds.contains(provinceId)) {
          continue;
        }
        if (townTileKeys.contains(tileKey)) continue;
        extractable++;
        if (game.worldState.tileState.improvementLevel(tileKey) >= 1) {
          improved++;
        }
      }
      final ratio = extractable == 0 ? 1.0 : improved / extractable;
      expect(
        ratio >= kColonialImprovementMinRatio,
        isTrue,
        reason:
            'AC2 (Refs #2848 S0): GP-owned extractable improvement ratio '
            '${ratio.toStringAsFixed(3)} ($improved/$extractable) below '
            'minimum ${kColonialImprovementMinRatio.toStringAsFixed(2)} '
            'at turn $kColonialRegressionTurns.',
      );
    },
    skip:
        'Refs #2848 S0 baseline (seed 42, turn '
        '$kColonialRegressionTurns): all 30 newWorld| provinces are '
        'tribe-owned (0/30 GP-owned) and the global GP-extractable '
        'improvement ratio is 0.039 (32/812) — well below the '
        '$kColonialImprovementMinRatio gate. The root cause is upstream '
        'of DEVELOP: GPs do not reach DEVELOP because the colonial NW '
        'acquisition pipeline stalls under seed 42 (Refs #2509 / #2847 '
        '— turn-100 conquest gate). The distance-aware Builder '
        'assignment landed for #2848 S2 cannot close the gap by itself; '
        'a follow-up issue tracks the broader colonial-acquisition '
        'tuning. Skip mirrors the S10 precedent on '
        'seed42_observer_conquest_regression_test.dart.',
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
