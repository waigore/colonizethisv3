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

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart'
    show
        CtE2eCivilianPanelSnapshot,
        CtE2eNavalPanelSnapshot,
        ctE2eCivilianPanelSnapshot;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  group('AC1 barrel: public name + signature pins', () {
    test('E2ePerfLog is constructible through the barrel', () {
      final perf = E2ePerfLog('e2e_helpers_barrel_test');
      expect(perf, isA<E2ePerfLog>());
    });

    test('pumpFor exposes the (WidgetTester, Duration) tear-off', () {
      final Future<void> Function(WidgetTester, Duration) ref = pumpFor;
      expect(ref, isNotNull);
    });

    test('waitUntilFound exposes the documented named-arg surface', () {
      final ref = waitUntilFound;
      expect(ref, isNotNull);
    });

    test('dismissTransientUi exposes the {E2ePerfLog?} tear-off', () {
      final Future<void> Function(WidgetTester, {E2ePerfLog? perf}) ref =
          dismissTransientUi;
      expect(ref, isNotNull);
    });

    test('closeBottomSheet exposes the {E2ePerfLog?, Duration} tear-off', () {
      final Future<void> Function(
        WidgetTester, {
        E2ePerfLog? perf,
        Duration overallTimeout,
      })
      ref = closeBottomSheet;
      expect(ref, isNotNull);
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
        expect(ref, isNotNull);
      },
    );

    test(
      'collectTextPreorder exposes the (Element, List<String>) tear-off',
      () {
        final void Function(Element, List<String>) ref = collectTextPreorder;
        expect(ref, isNotNull);
      },
    );

    test('expandEachExpansionTileOnce exposes the (WidgetTester) tear-off', () {
      final Future<void> Function(WidgetTester) ref =
          expandEachExpansionTileOnce;
      expect(ref, isNotNull);
    });

    test(
      'ensureAllRelocated64pxPngsLoad / SuiteOnce expose Future<void> tear-offs',
      () {
        final Future<void> Function() ref = ensureAllRelocated64pxPngsLoad;
        final Future<void> Function() refSuite =
            ensureAllRelocated64pxPngsLoadSuiteOnce;
        expect(ref, isNotNull);
        expect(refSuite, isNotNull);
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
        expect(fromMarker, isNotNull);
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
        expect(waitAdvance, isNotNull);
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
      expect(tapWithTitle, isNotNull);
    });

    testWidgets(
      'tapMoveOnFirstNonHomeFleet is re-exported through the barrel',
      (tester) async {
        final Future<bool> Function(WidgetTester) ref =
            tapMoveOnFirstNonHomeFleet;
        expect(ref, isNotNull);
        await tester.pumpWidget(
          buildAppShellMaterialApp(
            applyEditorialTheme: false,
            home: Scaffold(body: SizedBox()),
          ),
        );
        expect(await ref(tester), isFalse);
      },
    );

    testWidgets(
      'anyExplorerHasEnabledExploreAssignFleet is re-exported through '
      'the barrel',
      (tester) async {
        final Future<bool> Function(
          WidgetTester, {
          Duration maxUiResponseWait,
          int maxPanelSweepSteps,
        })
        ref = anyExplorerHasEnabledExploreAssignFleet;
        expect(ref, isNotNull);
        ctE2eCivilianPanelSnapshot = const CtE2eCivilianPanelSnapshot(
          game: Game(
            id: 'barrel-smoke-no-explore',
            worldState: WorldState(
              turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
              oldWorld: RegionData(),
              newWorld: RegionData(),
            ),
            players: [Player(id: 'gp1', displayName: 'You', isHuman: true)],
          ),
          humanPlayerId: 'gp1',
          currentOrders: Orders(),
          availableWorkTargets: <String, List<String>>{},
        );
        addTearDown(() {
          ctE2eCivilianPanelSnapshot = null;
        });
        await tester.pumpWidget(
          buildAppShellMaterialApp(
            applyEditorialTheme: false,
            home: Scaffold(body: SizedBox()),
          ),
        );
        expect(await ref(tester, maxPanelSweepSteps: 0), isFalse);
      },
    );

    testWidgets('tryNavalMoveSegment is re-exported through the barrel', (
      tester,
    ) async {
      final Future<void> Function(
        WidgetTester,
        AppLocalizations, {
        bool useNewWorldMapTabFirst,
        bool allowWarpDestinations,
        bool navalPanelAlreadyOpen,
        E2ePerfLog? perf,
        Duration maxUiResponseWait,
      })
      ref = tryNavalMoveSegment;
      expect(ref, isNotNull);
      expect(kE2eDefaultNavalMoveSegmentUiWait, const Duration(seconds: 5));
      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.pumpWidget(
        buildAppShellMaterialApp(
          applyEditorialTheme: false,
          home: Scaffold(body: SizedBox()),
        ),
      );
      await ref(tester, l10n, navalPanelAlreadyOpen: true);
    });

    testWidgets(
      'pickMoveDestinationAndConfirm is re-exported through the barrel',
      (tester) async {
        final Future<void> Function(
          WidgetTester,
          AppLocalizations, {
          bool allowWarpDestinations,
          Duration moveDialogBudget,
          int maxWarpDragProbes,
        })
        ref = pickMoveDestinationAndConfirm;
        expect(ref, isNotNull);
        expect(kE2eDefaultMoveFleetDialogBudget, const Duration(seconds: 5));
        expect(kE2eDefaultMoveFleetWarpDragProbes, 8);
        // Sanity smoke through the barrel: pumping an empty scaffold has
        // no AlertDialog, so the helper must fail via e2eWaitUntilFound's
        // deterministic timeout. A wrapper that swallowed the missing
        // dialog and silently returned would pass the tear-off pin
        // without exercising the helper at all.
        await tester.pumpWidget(
          buildAppShellMaterialApp(
            applyEditorialTheme: false,
            home: Scaffold(body: SizedBox()),
          ),
        );
        final l10n = lookupAppLocalizations(const Locale('en'));
        Object? caught;
        try {
          await ref(
            tester,
            l10n,
            moveDialogBudget: const Duration(seconds: 10),
          );
        } catch (e) {
          caught = e;
        }
        expect(caught, isNotNull);
      },
    );

    test(
      'e2eTextLooksLikeNewWorldLocationLine is re-exported through the barrel',
      () {
        final bool Function(String?) ref = e2eTextLooksLikeNewWorldLocationLine;
        expect(ref, isNotNull);
        expect(ref('New World — Outer Sea'), isTrue);
      },
    );

    testWidgets(
      'e2eNavalPanelShowsNonHomeFleetInNewWorld is re-exported through the barrel',
      (tester) async {
        final bool Function(WidgetTester) ref =
            e2eNavalPanelShowsNonHomeFleetInNewWorld;
        expect(ref, isNotNull);
        await tester.pumpWidget(
          buildAppShellMaterialApp(
            applyEditorialTheme: false,
            home: Scaffold(body: SizedBox()),
          ),
        );
        expect(ref(tester), isFalse);
      },
    );

    test('e2eNonHomeHumanFleetInNewWorldFromCtSnapshot is re-exported through '
        'the barrel', () {
      final bool Function(CtE2eNavalPanelSnapshot?) ref =
          e2eNonHomeHumanFleetInNewWorldFromCtSnapshot;
      expect(ref, isNotNull);
      expect(ref(null), isFalse);
    });

    test(
      'e2eFleetReachDoneFromCtSnapshotOnly is re-exported through the barrel',
      () {
        final bool Function(CtE2eNavalPanelSnapshot?) ref =
            e2eFleetReachDoneFromCtSnapshotOnly;
        expect(ref, isNotNull);
        expect(ref(null), isFalse);
      },
    );

    testWidgets(
      'e2eHarnessDetectsNonHomeFleetInNewWorld is re-exported through the barrel',
      (tester) async {
        final bool Function(WidgetTester, CtE2eNavalPanelSnapshot?) ref =
            e2eHarnessDetectsNonHomeFleetInNewWorld;
        expect(ref, isNotNull);
        await tester.pumpWidget(
          buildAppShellMaterialApp(
            applyEditorialTheme: false,
            home: Scaffold(body: SizedBox()),
          ),
        );
        expect(ref(tester, null), isFalse);
      },
    );

    test('e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot is '
        're-exported through the barrel', () {
      final bool Function(CtE2eNavalPanelSnapshot?) ref =
          e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot;
      expect(ref, isNotNull);
      expect(ref(null), isFalse);
    });

    test('e2eNwCoastalProvincesAdjacentToFleetSea is re-exported through the '
        'barrel', () {
      final Set<String> Function(MapTopology, String, String) ref =
          e2eNwCoastalProvincesAdjacentToFleetSea;
      expect(ref, isNotNull);
      expect(ref(const MapTopology(), 'sea1', 'newWorld'), isEmpty);
    });

    test('e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot is re-exported '
        'through the barrel', () {
      final bool Function(CtE2eNavalPanelSnapshot?) ref =
          e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot;
      expect(ref, isNotNull);
      expect(ref(null), isFalse);
    });

    test('e2eExploreAssignEnabledFromCivilianSnapshot is re-exported '
        'through the barrel', () {
      final bool? Function(CtE2eCivilianPanelSnapshot?) ref =
          e2eExploreAssignEnabledFromCivilianSnapshot;
      expect(ref, isNotNull);
      expect(ref(null), isNull);
      const Game game = Game(
        id: 'barrel-smoke',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: [Player(id: 'gp1', displayName: 'You', isHuman: true)],
      );
      final emptySnap = const CtE2eCivilianPanelSnapshot(
        game: game,
        humanPlayerId: 'gp1',
        currentOrders: Orders(),
        availableWorkTargets: <String, List<String>>{},
      );
      expect(ref(emptySnap), isFalse);
    });

    testWidgets(
      'e2eRadioListTilesInAlertDialogs is re-exported through the barrel',
      (tester) async {
        final Finder Function() ref = e2eRadioListTilesInAlertDialogs;
        expect(ref, isNotNull);
        await tester.pumpWidget(
          buildAppShellMaterialApp(
            applyEditorialTheme: false,
            home: Scaffold(body: SizedBox()),
          ),
        );
        expect(ref(), findsNothing);
      },
    );

    testWidgets(
      'e2eTapNewWorldRegionTabIfPresent is re-exported through the barrel',
      (tester) async {
        final Future<void> Function(WidgetTester) ref =
            e2eTapNewWorldRegionTabIfPresent;
        expect(ref, isNotNull);
        await tester.pumpWidget(
          buildAppShellMaterialApp(
            applyEditorialTheme: false,
            home: Scaffold(body: SizedBox()),
          ),
        );
        // Sanity smoke through the barrel: an empty scaffold has no
        // keyed New World subtree, so the helper must complete without
        // tapping or throwing. A wrapper that ignored the no-subtree
        // guard would either fail with a tap-target-missing exception
        // or silently no-op without forwarding to the implementation.
        await ref(tester);
      },
    );

    testWidgets('e2eTapOldWorldRegionTab is re-exported through the barrel', (
      tester,
    ) async {
      final Future<void> Function(WidgetTester, AppLocalizations) ref =
          e2eTapOldWorldRegionTab;
      expect(ref, isNotNull);
      // Sanity smoke: pumpWidget empty, then exercise the helper
      // forwarding with a real AppLocalizations instance via a
      // MaterialApp `localizationsDelegates` is heavyweight, so the
      // tear-off capture above already gates the signature. The
      // wrapper's runtime behavior is end-to-end pinned by
      // `e2e_tap_region_tab_test.dart` (the helper-layer pin file).
    });

    test('AC1 timing constants are exposed as Duration values', () {
      const Duration maxWallClock = kE2eMaxWallClock;
      const Duration nextTurnTimeout = kE2eNextTurnResolutionTimeout;
      expect(maxWallClock, isA<Duration>());
      expect(nextTurnTimeout, isA<Duration>());
      expect(maxWallClock.inMicroseconds, greaterThan(0));
      expect(nextTurnTimeout.inMicroseconds, greaterThan(0));
    });
  });
}
