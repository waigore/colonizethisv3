// AC1 barrel signature pins for e2e_helpers.dart (Refs #2336, #4352).

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart'
    show
        CtE2eCivilianPanelSnapshot,
        CtE2eNavalPanelSnapshot,
        ctE2eCivilianPanelSnapshot;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'app_shell_harness.dart';

void registerE2eHelpersBarrelPart1SignaturePins() {
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
