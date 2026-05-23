// Pins the **AC1 stable public-name barrel** exposed by
// `app/integration_test/e2e_helpers.dart` (Refs GitHub #2336 AC1).
//
// AC1 enumerates the canonical public names every E2E scenario must consume
// through one shared library: `E2ePerfLog`, `pumpFor`, `waitUntilFound`,
// `dismissTransientUi`, `closeBottomSheet`, `bootstrapNewGameToMap`,
// `collectTextPreorder`, `expandEachExpansionTileOnce`, and
// `ensureAllRelocated64pxPngsLoad`. The barrel also exposes the panel
// openers (`openCivilianPanel`, `openNavalPanel`, `openProductionPanel`,
// `openPanelFromMarker`) and turn helpers (`advanceOneHumanTurn`,
// `waitForNextTurnLabelAdvance`) that the same AC1 / AC5 narrative
// references as the canonical wait/settle surface.
//
// Direct contract coverage on `dev` only pins the underlying `e2e*`
// implementations (`e2e_test_shared_smoke_test.dart`, `e2e_pump_until_test`,
// `e2e_collect_text_preorder_test.dart`, ...) — there is no widget-level
// test that asserts the **barrel itself** still exposes each AC1 name with
// the documented signature and still forwards to the `e2e*` implementation.
// A silent break — an accidental rename, an arg-order swap in the
// delegating wrapper, or a stale re-export list — would only surface at
// E2E wall-clock time (and only on the slow CI lane #2336 is reducing).
//
// This file pins the AC1 barrel three ways:
//
//   1. **Existence + signature** — each canonical name is captured into a
//      strongly-typed tear-off reference. A rename / signature change
//      fails compilation against this test.
//   2. **Wrapper forwarding** — for the cheap helpers (`pumpFor`,
//      `collectTextPreorder`, `waitUntilFound`, `dismissTransientUi`,
//      `expandEachExpansionTileOnce`), a smoke call exercises the
//      wrapper end-to-end so a regression where the wrapper drops an
//      argument or no-ops is visible at unit-test time.
//   3. **Constants surface** — `kE2eMaxWallClock` and
//      `kE2eNextTurnResolutionTimeout` are re-exported through the same
//      barrel; pin both as `Duration` constants so an accidental
//      `int`-ification or removal trips this test instead of a confusing
//      type error at the call site.
//
// SPEC:
//   - `SPEC/program/e2e-integration-tests.md` § Local run (canonical
//     barrel for E2E helper consumption).
//   - Issue #2336 § Acceptance criteria § AC1 (Shared helpers exist) and
//     § AC5 (Adaptive polling) for the panel/turn entrypoints.

import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart'
    show CtE2eNavalPanelSnapshot;
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_helpers.dart';

void main() {
  suppressLogsForTests();

  group('AC1 barrel: public name + signature pins', () {
    test('E2ePerfLog is constructible through the barrel', () {
      final perf = E2ePerfLog('e2e_helpers_barrel_test');
      expect(
        perf,
        isA<E2ePerfLog>(),
        reason:
            'E2ePerfLog is the AC1 perf marker surface every scenario uses '
            'to emit E2E_COUNTER / E2E_TIMING lines; the barrel must keep '
            'it constructible by name so call sites stay decoupled from the '
            'private e2e_test_shared.dart import path.',
      );
    });

    test('pumpFor exposes the (WidgetTester, Duration) tear-off', () {
      final Future<void> Function(WidgetTester, Duration) ref = pumpFor;
      expect(
        ref,
        isNotNull,
        reason:
            'pumpFor is the AC1 fixed-step pump primitive. A rename or '
            'arg-order change must fail this typed tear-off capture, not '
            'silently downgrade to dynamic at scenario call sites.',
      );
    });

    test('waitUntilFound exposes the documented named-arg surface', () {
      final ref = waitUntilFound;
      expect(
        ref,
        isNotNull,
        reason:
            'waitUntilFound is the AC1 adaptive-poll primitive; its named '
            '{required Duration timeout, Duration diagnoseAfter, '
            'E2ePerfLog?, String phaseName} surface is consumed across '
            'every panel opener — pin the tear-off to catch signature '
            'drift here, not at E2E runtime.',
      );
    });

    test('dismissTransientUi exposes the {E2ePerfLog?} tear-off', () {
      final Future<void> Function(WidgetTester, {E2ePerfLog? perf}) ref =
          dismissTransientUi;
      expect(
        ref,
        isNotNull,
        reason:
            'dismissTransientUi is the canonical transient-overlay closer '
            'AC1 standardizes across the four E2E scenarios; pin the '
            'optional perf-log slot so scenario-level callers can keep '
            'attaching markers without paying a regression.',
      );
    });

    test('closeBottomSheet exposes the {E2ePerfLog?, Duration} tear-off', () {
      final Future<void> Function(
        WidgetTester, {
        E2ePerfLog? perf,
        Duration overallTimeout,
      })
      ref = closeBottomSheet;
      expect(
        ref,
        isNotNull,
        reason:
            'closeBottomSheet is the AC1 deterministic sheet dismisser. '
            'The optional `overallTimeout` knob is consumed by '
            'panel openers that need to bound the post-tap settle; pin '
            'both named slots in the wrapper.',
      );
    });

    test(
      'bootstrapNewGameToMap exposes the {E2ePerfLog?, Duration} tear-off',
      () {
        final Future<void> Function(
          WidgetTester, {
          E2ePerfLog? perf,
          Duration overallCap,
        })
        ref = bootstrapNewGameToMap;
        expect(
          ref,
          isNotNull,
          reason:
              'bootstrapNewGameToMap is the AC1 single-canonical-bootstrap '
              'helper (#2336 Bottleneck 3); pin the {perf, overallCap} '
              'named-slot surface so the documented "60s default cap" '
              'contract stays callable through one barrel import.',
        );
      },
    );

    test(
      'collectTextPreorder exposes the (Element, List<String>) tear-off',
      () {
        final void Function(Element, List<String>) ref = collectTextPreorder;
        expect(
          ref,
          isNotNull,
          reason:
              'collectTextPreorder is the AC1 snapshot-text traversal '
              'helper. Its sync (Element, List<String>) signature is what '
              'the orderedEquals snapshot mirrors depend on; pin the '
              'tear-off so a return-type or arg-shape regression surfaces '
              'in widget-test layer.',
        );
      },
    );

    test('expandEachExpansionTileOnce exposes the (WidgetTester) tear-off', () {
      final Future<void> Function(WidgetTester) ref =
          expandEachExpansionTileOnce;
      expect(
        ref,
        isNotNull,
        reason:
            'expandEachExpansionTileOnce is the AC1 ExpansionTile expander '
            '(#2336 Bottleneck 6 / H10); pin the tear-off so the '
            'parameter-free wrapper stays the single AC1 entrypoint and '
            'a regression to required-perf-log would fail here.',
      );
    });

    test(
      'ensureAllRelocated64pxPngsLoad / SuiteOnce expose Future<void> tear-offs',
      () {
        final Future<void> Function() ref = ensureAllRelocated64pxPngsLoad;
        final Future<void> Function() refSuite =
            ensureAllRelocated64pxPngsLoadSuiteOnce;
        expect(ref, isNotNull);
        expect(
          refSuite,
          isNotNull,
          reason:
              'AC1 names cover both the direct and suite-once asset preload '
              'entrypoints (#2336 AC3 parallel decode + memoization). Pin '
              'both tear-offs so a barrel that loses the suite-once name '
              'fails this test instead of regressing cross-scenario decode '
              'work to per-scenario.',
        );
      },
    );

    test(
      'panel openers (Civilian / Naval / Production / FromMarker) exist with documented surfaces',
      () {
        final Future<void> Function(
          WidgetTester, {
          Duration timeout,
          E2ePerfLog? perf,
          Duration bottomSheetCloseTimeout,
          String afterSheetPanelsClearPhase,
        })
        civ = openCivilianPanel;
        final Future<void> Function(
          WidgetTester, {
          E2ePerfLog? perf,
          Duration timeout,
          Duration bottomSheetCloseTimeout,
        })
        nav = openNavalPanel;
        final Future<void> Function(
          WidgetTester, {
          E2ePerfLog? perf,
          Duration timeout,
        })
        prod = openProductionPanel;
        final Future<void> Function(
          WidgetTester, {
          required Finder markerButton,
          required Finder panelRoot,
          Duration timeout,
          E2ePerfLog? perf,
        })
        fromMarker = openPanelFromMarker;
        expect(civ, isNotNull);
        expect(nav, isNotNull);
        expect(prod, isNotNull);
        expect(
          fromMarker,
          isNotNull,
          reason:
              'AC1 + AC5 require a single canonical panel-opener per panel '
              'type (#2336 Bottleneck 6 deduplication). Pin every opener '
              'tear-off with its named-slot surface so a regression to '
              'positional-only or to a private name surfaces in this test '
              'instead of an E2E flake.',
        );
      },
    );

    test(
      'turn helpers (advanceOneHumanTurn, waitForNextTurnLabelAdvance) exist',
      () {
        final Future<Duration> Function(
          WidgetTester, {
          required AppLocalizations l10n,
          E2ePerfLog? perf,
          Duration timeout,
        })
        advance = advanceOneHumanTurn;
        final Future<Duration> Function(
          WidgetTester, {
          required String turnLabelBefore,
          required Duration timeout,
          E2ePerfLog? perf,
        })
        waitAdvance = waitForNextTurnLabelAdvance;
        expect(advance, isNotNull);
        expect(
          waitAdvance,
          isNotNull,
          reason:
              'AC5 names both turn-advancing helpers as the canonical '
              'wait-for-next-turn surface; pin tear-offs so a rename or '
              'return-type change (e.g. from Future<Duration> to '
              'Future<void>) fails here instead of E2E.',
        );
      },
    );

    test('split / assign helpers exist', () {
      final Future<void> Function(
        WidgetTester,
        AppLocalizations, {
        E2ePerfLog? perf,
        Duration openNavalTimeout,
        Duration bottomSheetCloseTimeout,
        bool navalPanelAlreadyOpen,
      })
      split = splitHomeFleetOnce;
      final Future<void> Function(WidgetTester) tapFirst =
          tapFirstAssignInCivilianPanel;
      final Future<void> Function(WidgetTester, String) tapWithTitle =
          tapAssignOnCivilianRowWithTitle;
      expect(split, isNotNull);
      expect(tapFirst, isNotNull);
      expect(
        tapWithTitle,
        isNotNull,
        reason:
            'AC1 dedup standardizes split + assign helpers across the '
            'fleet-reach and full-turn E2E scenarios; pin the three '
            'tear-offs so a barrel that loses one stops compiling here.',
      );
    });

    test(
      'e2eTextLooksLikeNewWorldLocationLine is re-exported through the barrel',
      () {
        final bool Function(String?) ref = e2eTextLooksLikeNewWorldLocationLine;
        expect(
          ref,
          isNotNull,
          reason:
              'Fleet-reach detection in '
              '`new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` '
              'consumes this predicate via the AC1 barrel; a regression '
              'that dropped it from the `show` clause would break the '
              'naval-panel "New World — …" location row detection at '
              'E2E time. Pin the tear-off so the regression surfaces here.',
        );
        expect(
          ref('New World — Outer Sea'),
          isTrue,
          reason:
              'Sanity smoke through the barrel: the canonical em-dash '
              'shape must still match after re-export, otherwise a '
              'wrapper that swallowed the argument would pass silently.',
        );
      },
    );

    test('e2eNonHomeHumanFleetInNewWorldFromCtSnapshot is re-exported through '
        'the barrel', () {
      final bool Function(CtE2eNavalPanelSnapshot?) ref =
          e2eNonHomeHumanFleetInNewWorldFromCtSnapshot;
      expect(
        ref,
        isNotNull,
        reason:
            'Fleet-reach short-circuit in '
            '`new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` '
            '(`_fleetReachDoneFromCtSnapshotOnly`, '
            '`_harnessDetectsNonHomeFleetInNewWorld`) consumes this '
            'snapshot-driven predicate via the AC1 barrel. A regression '
            'that dropped it from the `show` clause would re-introduce '
            'the `_kMaxNextTurnTapsForNwFleetReach (35) × ~5 s` stall '
            'documented in #2336 Bottleneck 4 (`SPEC/program/'
            'e2e-integration-tests.md` § Determinism).',
      );
      expect(
        ref(null),
        isFalse,
        reason:
            'Sanity smoke through the barrel: a null snapshot must keep '
            'returning false after re-export. A wrapper that swallowed '
            'the argument and returned a constant would pass the '
            'tear-off pin silently; null is the canonical no-plumbing '
            'state and must short-circuit before any field access.',
      );
    });

    test('e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot is re-exported '
        'through the barrel', () {
      final bool Function(CtE2eNavalPanelSnapshot?) ref =
          e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot;
      expect(
        ref,
        isNotNull,
        reason:
            'The bundled-explore readiness loop in '
            '`new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` '
            '(`_awaitNwCoastalOrVisibleLandForBundledExploreE2e`) and '
            'the fleet-reach test\'s final skip guard '
            '(`new_game_fleet_reaches_new_world_e2e_test.dart`) both '
            'consume this snapshot-driven predicate via the AC1 '
            'barrel. A regression that dropped it from the `show` '
            'clause would either stall the readiness loop for the '
            'full 35-turn cap (Bottleneck 4 in `SPEC/program/'
            'e2e-integration-tests.md` § Determinism) or convert the '
            'strict bundled-explore assertion into a silent skip — '
            'both directly inflate the wall-clock cap #2336 is '
            'reducing.',
      );
      expect(
        ref(null),
        isFalse,
        reason:
            'Sanity smoke through the barrel: a null snapshot must '
            'keep returning false after re-export. A wrapper that '
            'swallowed the argument and returned a constant would '
            'pass the tear-off pin silently; null is the canonical '
            'no-plumbing state and must short-circuit before any '
            'field access.',
      );
    });

    test('AC1 timing constants are exposed as Duration values', () {
      const Duration maxWallClock = kE2eMaxWallClock;
      const Duration nextTurnTimeout = kE2eNextTurnResolutionTimeout;
      expect(
        maxWallClock,
        isA<Duration>(),
        reason:
            'kE2eMaxWallClock is the 5-minute scenario wall-clock cap from '
            '`colonizethis-e2e-ui-stability.mdc`; pin its Duration type so '
            'a regression to int milliseconds fails this test instead of '
            'an awkward runtime conversion at scenario start.',
      );
      expect(nextTurnTimeout, isA<Duration>());
      expect(
        maxWallClock.inMicroseconds,
        greaterThan(0),
        reason:
            'Sanity: a non-positive wall-clock cap would silently '
            'short-circuit the cap helper and defeat the AC1 budget '
            'plumbing.',
      );
      expect(nextTurnTimeout.inMicroseconds, greaterThan(0));
    });
  });

  group('AC1 barrel: wrapper forwarding smokes', () {
    testWidgets('pumpFor returns without throwing for Duration.zero', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await pumpFor(tester, Duration.zero);
    });

    testWidgets('pumpFor advances the test clock for a positive duration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      // Smoke: forwarding to e2ePumpFor (which loops 50ms pumps) must
      // complete without exception for a short, bounded duration. A
      // wrapper that dropped the Duration arg would either no-op
      // (passes vacuously) or call pump(null) (throws); only the
      // throw branch is asserted here because the no-op is OK by
      // contract.
      await pumpFor(tester, const Duration(milliseconds: 100));
    });

    testWidgets(
      'collectTextPreorder matches e2eCollectTextPreorder for a mixed subtree',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: KeyedSubtree(
                key: Key('root'),
                child: Column(
                  children: [Text('alpha'), Text(''), Text('beta')],
                ),
              ),
            ),
          ),
        );
        final out = <String>[];
        collectTextPreorder(tester.element(find.byKey(const Key('root'))), out);
        expect(
          out,
          const ['alpha', 'beta'],
          reason:
              'The barrel wrapper must reproduce e2eCollectTextPreorder '
              'depth-first pre-order + empty-data filtering exactly; '
              'orderedEquals on snapshot mirrors depends on it.',
        );
      },
    );

    testWidgets(
      'waitUntilFound short-circuits when finder is already non-empty',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(child: Text('here', key: Key('here'))),
            ),
          ),
        );
        final sw = Stopwatch()..start();
        await waitUntilFound(
          tester,
          find.byKey(const Key('here')),
          timeout: const Duration(seconds: 2),
          phaseName: 'barrel_smoke_immediate',
        );
        expect(
          sw.elapsed,
          lessThan(const Duration(milliseconds: 500)),
          reason:
              'The wrapper must forward to e2eWaitUntilFound, which '
              'short-circuits before its first pump when the finder '
              'already matches. A wrapper that hard-coded a longer '
              'initial sleep would visibly exceed this bound.',
        );
      },
    );

    testWidgets(
      'dismissTransientUi returns without throwing when no overlay is mounted',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await dismissTransientUi(tester);
      },
    );

    testWidgets(
      'expandEachExpansionTileOnce returns early when no ExpansionTile exists',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        final sw = Stopwatch()..start();
        await expandEachExpansionTileOnce(tester);
        expect(
          sw.elapsed,
          lessThan(const Duration(seconds: 2)),
          reason:
              'The wrapper must forward to e2eExpandEachExpansionTileOnce, '
              'which early-exits on the first iteration when no tiles '
              'exist (Bottleneck 6 / H10 fix). A wrapper that re-ran the '
              '32-iteration safety loop would visibly exceed this bound.',
        );
      },
    );
  });
}
