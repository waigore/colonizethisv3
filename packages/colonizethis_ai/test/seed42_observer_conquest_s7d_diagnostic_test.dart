import 'dart:convert';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/army_conquest_prep.dart'
    show regimentCountForPlayer;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
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
///   * **H4 [highest signal]: geographic peer-war lock starves
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
///     peace (45-turn mutual offer + war reopens). Two follow-up
///     tuning surfaces remain:
///
///     **H4-a [implemented]:** widen the `planExpandPeace` carve-out
///     so peace fires on every at-war turn when adjacency collapses
///     to a single at-war peer GP, regardless of whether uninvaded
///     OW minors remain elsewhere on the map. Landed in this PR via
///     the new [expandIsGeographicPeerWarLock] helper and a parallel
///     carve-out arm inside [planExpandPeace]; SPEC update at
///     `SPEC/ai/ai-architecture.md` § EXPAND and
///     `SPEC/ai/phase-planner-architecture.md` AC list (Refs #2847
///     § H4-a). Lifts the peace-fire ratio from ~45 / 53 at-war
///     turns toward 53 / 53 in the seed-42 gp3↔gp4 and gp5↔gp6
///     locks; a refreshed S7-D run after this lands should show
///     the gain.
///
///     **H4-b [deferred — refresh evidence below]:** extend the
///     stalled-expansion own-territory frontier-march in
///     `runConquestArmyMovePlanner` (`SPEC/ai/phase-planner-architecture.md`
///     § Acceptance criteria #2) to at-war minor / tribe owned OW
///     provinces reachable *through* the at-war peer GP's
///     territory. The post-H4-a refresh below shows the failing
///     GPs hold **1 regiment + 0 treasury** at turn 99 — a
///     longer reach without offensive strength would not close
///     the gate. This is now deferred behind H5 / H3 below.
///
/// ## S7-D refresh (captured 2026-05-26 against `feat/issue-2847-s7d-diagnostic`
///     with the H4-a peace-widening slice in place)
///
/// Re-running the diagnostic with the H4-a `planExpandPeace`
/// carve-out landed (commit `0f1f0a7295`) reveals that **H4-a
/// alone does not close the +3 OW gate**. Headline numbers:
///
///   * **OW gain (+3 gate):** gp3=+2, gp4=+1, gp5=+1, gp6=+2
///     (all still failing — same band as the original baseline).
///     gp1=+6, gp2=+2 (unchanged passes).
///   * **Phase distribution unchanged:** gp3 / gp4 / gp5 stay in
///     EXPAND for all 100 turns; gp6 reaches COLONIAL only at
///     turn 94+ (94 expand / 6 colonial). H4-a does not unlock
///     the EXPAND → COLONIAL transition for the failing GPs.
///   * **Peer-war at-war turn count drops modestly:**
///     gp3↔gp4 stays at war 45 / 100 (down from 53 / 100 in the
///     pre-H4-a baseline — the peace fires every turn now via
///     the carve-out, but the war is **re-declared** by the peer
///     a few turns later because both sides still satisfy the
///     same EXPAND declare-war priority arms). gp5↔gp6 stays at
///     war 45 / 100 (already at 45 in baseline, no movement).
///   * **Economy bottleneck dominates:** every failing GP holds
///     **1 regiment + 0 treasury** at turn 99 with
///     `cheapestRegimentBuildTreasuryCost = 2000`.
///     `boostTreasuryRecoveryCargo` fires 91–97 turns per failing
///     GP but treasury never crosses 2000 because the failing GPs
///     hold zero NW provinces and have no overseas riches to
///     deliver — `boostTreasuryRecoveryCargo` boosts cargo
///     preference for an income path that does not exist.
///     `forceCheapestRegimentBuild` fires only **3 turns** per GP
///     (Arm A's `regimentCount == 0` gate; Arm B requires
///     `effectiveTreasury >= 2000` which never happens).
///   * **Geographic peer-war lock unchanged at turn 99:**
///     `adjacentOwnerFactionIdsSorted` still collapses to a single
///     at-war (or recently-at-war) peer per failing GP — gp4 for
///     gp3, gp3 for gp4, gp6 for gp5, gp5 for gp6 — and the
///     invadable OW set (5–8 provinces per GP) is owned entirely
///     by that peer.
///
/// ## Updated S7-T tuning surface (ordered by post-H4-a evidence)
///
/// Constraint per issue § Scope constraint stays unchanged:
/// **phase-planner logic only**, **no new config constants**,
/// **no value changes** to existing constants in
/// `packages/colonizethis_data/lib/src/ai_victory_config.dart`.
///
///   1. **H5 (new, highest signal): treasury-recovery cargo
///      futility under geographic peer-war lock.**
///      `boostTreasuryRecoveryCargo` is set on 91–97 turns per
///      failing GP but `gpTreasuryUnderCheapestRegimentTurns` /
///      treasury / `gpOwGain` show the boost never lifts the
///      regiment-build gate — the failing GPs hold **zero NW
///      provinces** and **zero NW invadables in EXPAND** (NW
///      acquisition is structurally suppressed in EXPAND) so the
///      cargo-preference signal targets an income path that the
///      GP cannot reach. The single highest-signal slice is to
///      detect the geographic peer-war lock + zero NW ownership +
///      EXPAND combination and either suppress the futile cargo
///      boost, route the economy-weight bonus toward a different
///      income arm (OW trade with neighbors, OW build queue,
///      forced cheapest-regiment build under a relaxed treasury
///      gate), or surface the dead-end as a deferred-survival
///      signal so a future SPEC slice can authorise an OW-only
///      trade-recovery arm. Phase-planner-only; no new constants.
///   2. **H3 (still open): `planExpandEconomy` Arm A semantics
///      under the lock.** Arm A's `regimentCount == 0` gate fires
///      only 3 turns per GP because the failing GPs **always have
///      ≥ 1 regiment** (the EXPAND-trap predicate
///      `isBelowQuotaPeaceInsufficientRegiments` was already
///      lifted to Arm B but Arm B requires `effectiveTreasury >=
///      cheapestRegimentBuildTreasuryCost`). Investigate widening
///      Arm A — `forceCheapestRegimentBuild: true` — to also fire
///      under geographic peer-war lock + below quota +
///      insufficient regiments **without** the affordable-treasury
///      gate, paired with H5. The build pipeline still applies
///      its own affordability check, so this is a directive change
///      not a budget change.
///   3. **H4-b [deferred]: stalled-expansion frontier-march
///      extension through peer-GP territory.** The +3 OW gate
///      cannot close while the failing GPs hold 1 regiment and
///      0 treasury — extending reach without fixing the offensive
///      strength gap would still leave combat outcomes
///      unfavourable. Re-evaluate after H5 / H3 lift the
///      regiment / treasury floor.
///   4. **H2 (still open): mutual-plateau peer-war exit lax.**
///      H4-a is the canonical fix here; the residual peer-war
///      re-declare oscillation (45-turn at-war count after H4-a)
///      remains and can be tuned in a follow-up declare-war
///      cooldown slice.
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
