import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'support/seed42_observer_campaign.dart';

/// Seed-42 Path E lock-recovery declare-war acceptance regression (Refs #2924).
///
/// Pins the secondary AC: under the EXPAND geographic peer-war lock with
/// `treasury == 0` and `newWorldProvincesOwned == 0`, gp3–gp6 must emit
/// at least one NW-acquisition-supporting diplomatic order (`declareWar`
/// toward a tribe/minor) across the 100-turn campaign so the
/// declare-war → colonial military/naval → invasion chain can begin.
///
/// NW-bound army moves may remain zero until naval transport / home-army
/// mobility land (#2925 companion); this regression pins the upstream
/// diplomatic emission the issue's secondary AC requires.
///
/// Migrated to the shared [runSeed42ObserverCampaign] harness (Refs #3749
/// step 2): the init / handoff / 100-turn resolve loop is owned by
/// `test/support/seed42_observer_campaign.dart`; this test contributes only
/// its per-turn `onBeforeResolve` observation of the generated diplomatic
/// orders.
///
/// Skipped by default (~3 min). Re-run with `dart test --run-skipped` when
/// the lock-recovery colonial acquisition surface changes.
void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  const failingGpIds = ['gp3', 'gp4', 'gp5', 'gp6'];

  test(
    'seed 42: gp3–gp6 each emit at least one tribal declareWar within 100 '
    'turns (Refs #2924 Path E)',
    () {
      final tribalDeclareWarCount = <String, int>{
        for (final gpId in failingGpIds) gpId: 0,
      };

      runSeed42ObserverCampaign(
        turns: 100,
        onBeforeResolve: (turn, fullAi, game, topology, tileMap) {
          for (final gpId in failingGpIds) {
            for (final order
                in fullAi.orders.diplomaticOrdersByPlayerId[gpId] ?? const []) {
              if (order.type == DiplomaticOrderType.declareWar &&
                  !order.targetFactionId.startsWith('gp')) {
                tribalDeclareWarCount[gpId] = tribalDeclareWarCount[gpId]! + 1;
              }
            }
          }
        },
      );

      for (final gpId in failingGpIds) {
        expect(
          tribalDeclareWarCount[gpId]!,
          greaterThan(0),
          reason:
              'Refs #2924 Path E: $gpId must emit at least one tribal '
              'declareWar under the lock-recovery override '
              '(count=${tribalDeclareWarCount[gpId]}).',
        );
      }
    },
    skip:
        'Refs #2924: long-running seed-42 Path E acceptance (~3 min). '
        'Re-run with `dart test --run-skipped` after lock-recovery tuning.',
  );
}
