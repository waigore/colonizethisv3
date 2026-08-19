import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'support/seed42_observer_campaign.dart';

/// Growth-stage planner seed-42 conquest gate (Refs #3371 AC7).
///
/// Migrated to the shared [runSeed42ObserverCampaign] harness (Refs #3749
/// step 2) with `growthStagePlannerEnabled: true` (H8 reactive boosts off).
void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'seed 42 turn 100 with growth-stage planner: per-GP OW conquest baselines',
    () {
      final campaign = runSeed42ObserverCampaign(
        turns: 100,
        growthStagePlannerEnabled: true,
      );

      int owProvincesFor(String gpId) => campaign.finalGame.worldState
          .oldWorld.provinces
          .where((p) => p.ownerId == gpId)
          .length;

      final gains = <String, int>{};
      for (var i = 1; i <= 6; i++) {
        final gpId = 'gp$i';
        final start = campaign.initialGame.worldState.oldWorld.provinces
            .where((p) => p.ownerId == gpId)
            .length;
        gains[gpId] = owProvincesFor(gpId) - start;
      }

      const baselines = <String, int>{
        'gp1': 6,
        'gp2': 6,
        'gp4': 3,
        'gp6': 10,
        'gp3': 3,
        'gp5': 3,
      };
      for (final entry in baselines.entries) {
        expect(
          gains[entry.key],
          greaterThanOrEqualTo(entry.value),
          reason:
              '${entry.key} OW gain=${gains[entry.key]} '
              'required>=${entry.value} allGains=$gains',
        );
      }
    },
    skip:
        'Refs #3371 AC7: growth-stage calibration pending — run with '
        'growthStagePlannerEnabled=true after constant tuning. H8 boosts are '
        'disabled in this path; baseline parity vs legacy seed-42 is not yet '
        'verified on dev HEAD.',
  );
}
