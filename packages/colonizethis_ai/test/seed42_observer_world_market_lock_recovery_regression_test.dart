import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'support/seed42_observer_campaign.dart';

/// Seed-42 Path F lock-recovery acceptance regression (Refs #2924).
///
/// Pins the primary AC (owner clarification 2026-06-01): after 100 Full-AI
/// turns on seed 42, gp3–gp6 each fall below
/// `cheapestRegimentBuildTreasuryCost()` under the EXPAND geographic peer-war
/// lock, receive positive world-market seller credits, cross the threshold
/// again at least once from legitimate market income (no affordability bypass),
/// and emit at least one regiment `BuildUnitOrder` after recovery so the
/// unchanged build/affordability pipeline is exercised.
///
/// The run uses a faithful Full-AI handoff (every player `isHuman: false`,
/// every GP AI-controlled) so the diplomacy intervention resolver auto-resolves
/// AI interventions instead of pausing with
/// `TurnResolutionPendingIntervention` (which only arises for human players).
///
/// Migrated to the shared [runSeed42ObserverCampaign] harness (Refs #3749
/// step 2): the init / handoff / 100-turn resolve loop is owned by
/// `test/support/seed42_observer_campaign.dart`; this test contributes only its
/// per-turn `onBeforeResolve` (affordable-turn regiment-build tally) and
/// `onAfterResolve` (world-market seller credit + treasury recovery tracking)
/// observations.
///
/// Skipped by default (~4 min). Re-run with `dart test --run-skipped` when
/// the lock-recovery surface changes.
void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  const failingGpIds = ['gp3', 'gp4', 'gp5', 'gp6'];

  test(
    'seed 42: gp3–gp6 each cross regiment treasury threshold within 100 turns '
    '(Refs #2924 Path F)',
    () {
      final threshold = cheapestRegimentBuildTreasuryCost();
      final wasBrokeAfterStart = <String, bool>{
        for (final gpId in failingGpIds) gpId: false,
      };
      final recoveredAfterBroke = <String, bool>{
        for (final gpId in failingGpIds) gpId: false,
      };
      final maxTreasury = <String, int>{
        for (final gpId in failingGpIds) gpId: 0,
      };
      final lifetimeSellerCredit = <String, int>{
        for (final gpId in failingGpIds) gpId: 0,
      };
      final regimentBuildsWhileAffordable = <String, int>{
        for (final gpId in failingGpIds) gpId: 0,
      };

      runSeed42ObserverCampaign(
        turns: 100,
        onBeforeResolve: (turn, fullAi, game) {
          for (final gpId in failingGpIds) {
            final treasuryBeforeOrders = game.playerById(gpId)?.treasury ?? 0;
            if (treasuryBeforeOrders < threshold) continue;
            final orders =
                fullAi.orders.buildUnitOrdersByPlayerId[gpId] ?? const [];
            regimentBuildsWhileAffordable[gpId] =
                regimentBuildsWhileAffordable[gpId]! +
                orders
                    .where(
                      (o) => RegimentEconomyCatalog.byId.containsKey(o.unitType),
                    )
                    .length;
          }
        },
        onAfterResolve: (turn, game) {
          final activity = game.worldMarketState.lastTurnActivity;
          for (final entry in activity.entries) {
            for (final deal in entry.value.deals) {
              final seller = deal.sellerFactionId;
              if (!lifetimeSellerCredit.containsKey(seller)) continue;
              lifetimeSellerCredit[seller] = lifetimeSellerCredit[seller]! +
                  (deal.quantity * deal.pricePerUnit).round();
            }
          }

          for (final gpId in failingGpIds) {
            final treasury = game.playerById(gpId)?.treasury ?? 0;
            if (treasury > maxTreasury[gpId]!) {
              maxTreasury[gpId] = treasury;
            }
            if (turn > 0 && treasury < threshold) {
              wasBrokeAfterStart[gpId] = true;
            }
            if (wasBrokeAfterStart[gpId]! && treasury >= threshold) {
              recoveredAfterBroke[gpId] = true;
            }
          }
        },
      );

      for (final gpId in failingGpIds) {
        expect(
          wasBrokeAfterStart[gpId],
          isTrue,
          reason: 'Refs #2924 fixture: $gpId should fall below $threshold '
              'during the 100-turn EXPAND lock (maxTreasury='
              '${maxTreasury[gpId]}).',
        );
        expect(
          recoveredAfterBroke[gpId],
          isTrue,
          reason: 'Refs #2924: $gpId never recovered to treasury >= $threshold '
              'after being broke (maxTreasury=${maxTreasury[gpId]}, '
              'lifetimeSellerCredit=${lifetimeSellerCredit[gpId]}).',
        );
        expect(
          lifetimeSellerCredit[gpId],
          greaterThan(0),
          reason: 'Refs #2924 Path F: $gpId received zero world-market seller '
              'credits across 100 turns.',
        );
        expect(
          regimentBuildsWhileAffordable[gpId],
          greaterThan(0),
          reason: 'Refs #2924 Path F: $gpId emitted no regiment builds on a '
              'turn with treasury >= $threshold (maxTreasury='
              '${maxTreasury[gpId]}).',
        );
      }
    },
    skip:
        'Refs #2924: long-running seed-42 Path F acceptance (~4 min). '
        'Re-run with `dart test --run-skipped` after lock-recovery tuning.',
  );
}
