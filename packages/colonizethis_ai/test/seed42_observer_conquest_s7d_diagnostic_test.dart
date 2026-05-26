import 'dart:convert';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/army_conquest_prep.dart'
    show regimentCountForPlayer;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

/// Seed-42 turn-100 EXPAND-arm S7-D diagnostic (Refs #2847).
///
/// Per the issue's S7-D subtask, this test runs the 100-turn seed-42
/// scenario (matching `seed42_observer_conquest_regression_test`) and
/// records, **per GP per turn**:
///
///   * `observerGoalPhaseFor` phase classification (EXPAND /
///     COLONIAL-lite / COLONIAL / DEVELOP).
///   * `planExpandDeclareWar` target (or `null` — none of the priority
///     arms qualified this turn).
///   * `planExpandPeace` peace-target set.
///   * `planExpandEconomy` arm flags (forceCheapestRegimentBuild /
///     boostTreasuryRecoveryCargo).
///   * Key snapshot fields gating the EXPAND arms: invadable OW count,
///     adjacent owner set, at-war set, treasury, regimentCount,
///     OW provinces owned.
///
/// The aggregated per-GP rollup (phase distribution, declare-war target
/// distribution, peace-target distribution, OW gain) is printed to
/// stdout for inclusion in the S7-D diagnostic note posted to the
/// issue / PR description. The test asserts only that diagnostic data
/// was collected (per-GP phase count totals match turn count) — it
/// does **not** pin any arm-fire counts so the diagnostic surface can
/// move freely as the planner is tuned in subsequent slices.
///
/// ## S7-D findings (captured 2026-05-26)
///
/// First run on `dev` @ `e6b4fff225` produced the per-GP rollup pasted
/// into the issue's S7-D diagnostic note. Headline observations:
///
///   * **gp1 / gp2 PASS** the +3 OW gate (+6 each). gp2's previously
///     unconfirmed status is therefore **PASS** — the failing set is
///     exactly `gp3, gp4, gp5, gp6` as the original skip message said.
///   * **gp3, gp4, gp5 stay in EXPAND for all 100 turns** (gp6 reaches
///     COLONIAL only at turn 94+). They never satisfy
///     `kObserverConquestMinOwProvincesPerGp` (OW ≥ 10).
///   * **`planExpandDeclareWar` returns `null` 93–98% of the time** for
///     every GP. The treasury floor on arms 1 and 3 (≥
///     `cheapestRegimentBuildTreasuryCost` = 2000) is the dominant
///     skip clause: every GP spends 97 of 100 turns with `treasury <
///     2000`.
///   * **`boostTreasuryRecoveryCargo` fires 91–97 turns per GP** for
///     `gp3..gp6` (vs 2–4 for `gp1`/`gp2`). The failing GPs are
///     chronically below the cheapest regiment cost.
///   * **gp3 ↔ gp4 stay at war 53 turns; gp5 ↔ gp6 stay at war 45
///     turns.** Both pairs are mutual-plateau peers locked in below-
///     quota GP wars; `planExpandPeace` picks the peer ~44–45% of
///     turns but the war never permanently closes.
///   * **Targets exist for the failing GPs** — turn-99 snapshot shows
///     gp3/gp4/gp5/gp6 with 6–8 invadable OW provinces each, yet only
///     1–2 regiments and treasury 0–50.
///   * **Geographic peer-war lock (turn-99 snapshot, all four failing
///     GPs)** — `adjacentOwnerFactionIdsSorted` collapses to a single
///     entry per GP: `gp4` for gp3, `gp3` for gp4, `gp6` for gp5,
///     `gp5` for gp6. Every invadable OW province is owned by that
///     peer; the at-war minors in `ThreatSummary.atWarWith` are not
///     adjacent and therefore never reach the `atWarMinors` set
///     inside `planExpandDeclareWar`. This is the proximate cause
///     of the arm-2 underfire — refutes H1 and elevates the new
///     hypothesis H4 below.
///
/// ## S7-T tuning surface (issue § S7-T hypotheses, ordered by S7-D
///     evidence)
///
/// **H1 refuted** (re-run 2026-05-26, captured in
/// `expand_phase_planner_declare_war_test.dart` ›
/// `Refs #2847 S7-D H1 refutation` pin). The turn-99 snapshot for
/// every failing GP shows `adjacentOwnerFactionIdsSorted` containing
/// **only the at-war peer GP** (gp4 for gp3, gp3 for gp4, gp6 for gp5,
/// gp5 for gp6). Because `ConquestSummary.invadableProvinceIdsSorted`
/// is a P–P neighbor scan, **no at-war minor owns any invadable
/// province by mid-late game** for the failing GPs — they are
/// geographically surrounded by their peer GP and cut off from the
/// minor frontier. Arm 2 therefore has zero candidates structurally,
/// not because of a candidate-filtering bug. Tuning the `atWarMinors`
/// set construction or the `adjacentOwners` cross-check will not
/// produce arm-2 fires the planner is currently missing because the
/// inputs already correctly exclude non-adjacent minors. The 3 arm-2
/// fires gp3 does emit (`minor1` ×3) occur in earlier turns when the
/// geography still routes through a minor.
///
///   * **H1 [refuted]: planExpandDeclareWar arm-2 candidate filtering.**
///     Spec gives no arm for at-war minors that own no invadable
///     province. The proximate cause for the missing arm-2 fires is
///     **upstream of the planner** — the geographic peer-war lock
///     (see H4) keeps the at-war minor owners outside the invadable
///     set in the first place.
///   * **H2: mutual-plateau peer-war exit is too lax for the gp3↔gp4
///     and gp5↔gp6 pairs.** Both pairs spend ~45 turns at war with
///     each other while invadable minor targets remain on the wider
///     map (just not reachable from the failing GP's own anchors).
///     The `belowQuotaPeerGpPeaceTargets` /
///     `mutualExhaustedBelowQuotaGpStalematePeaceTargets` deciders
///     fire ~44% of turns but the war reopens. Investigate whether
///     the declare-war path re-opens the war the same turn peace is
///     offered, or whether a later EXPAND decider override is
///     keeping the peer war live.
///   * **H3: economy rebuild arm A flag does not translate to
///     regiment builds.** `forceCheapestRegimentBuild` fires only 3
///     turns per GP across the entire 100-turn run (every GP),
///     including `gp3..gp6` who spend ≥91 turns flagged for cargo
///     boost. Investigate why arm A's `regimentCount == 0` gate
///     rarely triggers despite the failing GPs holding 1–2
///     regiments — does the build pipeline cap arm A to once-per-
///     drop-to-zero, or is the arm gate semantically wrong for the
///     "1–2 regiments stuck" case?
///   * **H4 [new, highest signal]: geographic peer-war lock starves
///     the failing GPs of reachable conquest targets.** For each of
///     the four failing GPs, `adjacentOwnerFactionIdsSorted` collapses
///     to a single at-war peer GP by mid-game, every invadable OW
///     province is owned by that peer, and the
///     `kStalledMinRegimentCountWhenGpBlockerAtWar` (22) plus
///     province-deficit scaling pushes the `minRegimentFloor`
///     above 22 while the GP has 1–2 regiments and treasury 0–50.
///     `boostTreasuryRecoveryCargo` fires 91–97 turns per failing
///     GP but treasury never climbs to `cheapestRegimentBuildTreasuryCost`
///     (2000). The peer war cannot be broken via declare-war
///     (already at war), army-move (insufficient regiments), or
///     peace (45-turn mutual offer + war reopens). Investigate
///     **(a)** whether `planExpandPeace` should include the sole
///     at-war GP blocker more aggressively when the failing GP's
///     adjacency collapses to that single peer (today's gate
///     requires `mutualPlateau && gpOnlyFrontier && !hasUninvadedOldWorldMinor`
///     and excludes the blocker otherwise — see
///     `expand_phase_planner.dart::planExpandPeace`), and
///     **(b)** whether the stalled-expansion own-territory frontier-march
///     in `runConquestArmyMovePlanner` (SPEC/ai/phase-planner-architecture.md
///     § Acceptance criteria #2) should extend to at-war minor/tribe
///     owned OW provinces reachable through the at-war peer GP's
///     territory (currently the multi-turn march targets minor/tribe
///     destinations adjacent to *own* territory only).
///
/// ## How to refresh
///
/// Skipped by default (long-running, ~4 minutes on the project
/// reference host). Run manually with:
///
/// ```
/// (cd packages/colonizethis_ai && dart test \
///     test/seed42_observer_conquest_s7d_diagnostic_test.dart \
///     --run-skipped)
/// ```
///
/// and copy the `S7D_DIAGNOSTIC_JSON_*`-delimited block into a fresh
/// comment on issue #2847 if the diagnostic surface shifts after a
/// tuning slice lands.
void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'seed 42 turn 100 S7-D diagnostic: per-GP EXPAND arm decision trace',
    () {
      final init = runInitGame(
        config: GameSetupConfig(seed: 42),
        options: const InitGameOptions(
          cellSize: 24,
          renderPng: false,
          skipFillLakes: false,
        ),
      );
      var game = init.game.copyWith(
        aiControlByGpId: {for (final p in init.game.players) p.id: true},
      );
      final topo = init.combinedTopology;
      final tileMap = init.tileMapByRegion;

      final gpIds = [for (var i = 1; i <= 6; i++) 'gp$i'];
      final owStart = <String, int>{
        for (final gpId in gpIds)
          gpId: game.worldState.oldWorld.provinces
              .where((p) => p.ownerId == gpId)
              .length,
      };

      // Per-GP rollups; populated as the simulation advances.
      final phaseCounts = <String, Map<ObserverGoalPhase, int>>{
        for (final gpId in gpIds)
          gpId: <ObserverGoalPhase, int>{
            for (final ph in ObserverGoalPhase.values) ph: 0,
          },
      };
      final declareWarPicks = <String, Map<String, int>>{
        for (final gpId in gpIds) gpId: <String, int>{},
      };
      final peaceTargetPicks = <String, Map<String, int>>{
        for (final gpId in gpIds) gpId: <String, int>{},
      };
      final economyArmCounts = <String, Map<String, int>>{
        for (final gpId in gpIds)
          gpId: <String, int>{
            'forceCheapestRegimentBuild': 0,
            'boostTreasuryRecoveryCargo': 0,
          },
      };
      final invadableEmptyTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final atWarTurnsByPeer = <String, Map<String, int>>{
        for (final gpId in gpIds) gpId: <String, int>{},
      };
      final treasuryUnderCheapestTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final lastSnapshotFields = <String, Map<String, Object?>>{};

      for (var t = 0; t < 100; t++) {
        // Capture phase / arm decisions *before* the turn resolves so the
        // diagnostic reflects what the planner saw entering turn t+1.
        for (final gpId in gpIds) {
          final view = buildPlayerView(game, topo, gpId);
          final snap = AIWorldSnapshot.fromPlayerView(view, topology: topo);
          final outcome = runPhasePlanners(game: game, snapshot: snap);
          phaseCounts[gpId]![outcome.phase] =
              (phaseCounts[gpId]![outcome.phase] ?? 0) + 1;
          final dwKey = outcome.expandDeclareWarTargetFactionId ?? '(null)';
          declareWarPicks[gpId]![dwKey] =
              (declareWarPicks[gpId]![dwKey] ?? 0) + 1;
          final peaceKey = outcome.expandPeaceTargetFactionIdsSorted.isEmpty
              ? '(none)'
              : outcome.expandPeaceTargetFactionIdsSorted.join(',');
          peaceTargetPicks[gpId]![peaceKey] =
              (peaceTargetPicks[gpId]![peaceKey] ?? 0) + 1;
          if (outcome.expandEconomyPlan.forceCheapestRegimentBuild) {
            economyArmCounts[gpId]!['forceCheapestRegimentBuild'] =
                (economyArmCounts[gpId]!['forceCheapestRegimentBuild'] ?? 0) +
                1;
          }
          if (outcome.expandEconomyPlan.boostTreasuryRecoveryCargo) {
            economyArmCounts[gpId]!['boostTreasuryRecoveryCargo'] =
                (economyArmCounts[gpId]!['boostTreasuryRecoveryCargo'] ?? 0) +
                1;
          }
          if (snap.conquest.invadableProvinceIdsSorted.isEmpty) {
            invadableEmptyTurns[gpId] = (invadableEmptyTurns[gpId] ?? 0) + 1;
          }
          for (final peer in snap.threats.atWarWith) {
            atWarTurnsByPeer[gpId]![peer] =
                (atWarTurnsByPeer[gpId]![peer] ?? 0) + 1;
          }
          final player = game.playerById(gpId);
          if (player != null) {
            final cheapest = cheapestRegimentBuildTreasuryCost();
            if (player.treasury < cheapest) {
              treasuryUnderCheapestTurns[gpId] =
                  (treasuryUnderCheapestTurns[gpId] ?? 0) + 1;
            }
          }
          // Cache the turn-99 snapshot fields for the final rollup.
          if (t == 99) {
            lastSnapshotFields[gpId] = <String, Object?>{
              'oldWorldProvincesOwned': snap.conquest.oldWorldProvincesOwned,
              'invadableProvinceCount':
                  snap.conquest.invadableProvinceIdsSorted.length,
              'nwInvadableCount':
                  snap.colonial.invadableNewWorldProvinceIdsSorted.length,
              'atWarWith': snap.threats.atWarWith.toList()..sort(),
              'adjacentOwnerFactionIdsSorted':
                  snap.conquest.adjacentOwnerFactionIdsSorted,
              'treasury': player?.treasury,
              'regimentCount': regimentCountForPlayer(game, gpId),
              'cheapestRegimentBuildTreasuryCost':
                  cheapestRegimentBuildTreasuryCost(),
            };
          }
        }

        final fullAi = generateOrdersForGameFullAI(
          game,
          topo,
          tileMapByRegion: tileMap,
        );
        final merged = mergeOrderLists(
          humanOrders: const Orders(),
          aiOrders: fullAi.orders,
        );
        final assignments = fullAi.economyPlansByPlayerId.map(
          (pid, plan) => MapEntry(pid, plan.productionAssignments),
        );
        final result = validateOrdersAndResolveTurnFromTrustedOrders(
          game: fullAi.game,
          topology: topo,
          orders: merged,
          tileMapByRegion: tileMap,
          defaultAssignmentsByPlayerId: assignments,
        );
        expect(result, isA<TurnResolutionComplete>());
        game = (result as TurnResolutionComplete).game;
      }

      final gains = <String, int>{
        for (final gpId in gpIds)
          gpId:
              game.worldState.oldWorld.provinces
                  .where((p) => p.ownerId == gpId)
                  .length -
              owStart[gpId]!,
      };

      // Structured JSON dump for inclusion in the S7-D diagnostic note.
      final diagnostic = <String, Object?>{
        'issue': 2847,
        'subtask': 'S7-D',
        'seed': 42,
        'turns': 100,
        'gpOwGain': gains,
        'gpOwStart': owStart,
        'gpPhaseTurnCount': {
          for (final gpId in gpIds)
            gpId: {
              for (final entry in phaseCounts[gpId]!.entries)
                entry.key.name: entry.value,
            },
        },
        'gpDeclareWarPickDistribution': declareWarPicks,
        'gpExpandPeacePickDistribution': peaceTargetPicks,
        'gpExpandEconomyArmCounts': economyArmCounts,
        'gpInvadableEmptyTurns': invadableEmptyTurns,
        'gpAtWarTurnsByPeer': atWarTurnsByPeer,
        'gpTreasuryUnderCheapestRegimentTurns': treasuryUnderCheapestTurns,
        'gpTurn99Snapshot': lastSnapshotFields,
      };
      // Re-enable info-level logging so the structured diagnostic JSON
      // surfaces in stdout via the package logger (the simulation above
      // intentionally ran with logging off to suppress planner noise).
      // Routing through `aiLogger` keeps this test compliant with the
      // disallowed-AST `avoid_print_suppression` rule while preserving
      // greppable BEGIN/END markers for issue-comment transcription.
      CtLogger.level = Level.info;
      final log = aiLogger('s7d-diagnostic');
      log.i('S7D_DIAGNOSTIC_JSON_BEGIN');
      log.i(const JsonEncoder.withIndent('  ').convert(diagnostic));
      log.i('S7D_DIAGNOSTIC_JSON_END');

      // Lightweight assertion: data was actually collected. The diagnostic
      // does not pin arm-fire counts so the planner can be tuned freely
      // in S7-T without churn here.
      for (final gpId in gpIds) {
        expect(
          phaseCounts[gpId]!.values.fold<int>(0, (a, b) => a + b),
          100,
          reason: '$gpId phase-count total should equal turn count',
        );
      }
    },
    skip:
        'Refs #2847 S7-D: long-running (~4 min) per-GP EXPAND-arm '
        'diagnostic. Captured findings live in the doc comment above '
        'and in the issue\'s S7-D note. Re-run with `dart test '
        '--run-skipped` when the diagnostic surface shifts after a '
        'tuning slice lands.',
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
