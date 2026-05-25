/// Pins the AC1-barrel forwarding contract for the four per-panel
/// snapshot-text matchers lifted in this slice
/// (`app/integration_test/e2e_test_shared_panel_text_match.dart`):
///
///   - [e2eExpectCivilianPanelMatchesE2eSnapshot]
///   - [e2eExpectNavalPanelMatchesE2eSnapshot]
///   - [e2eExpectProductionPanelMatchesE2eSnapshot]
///   - [e2eExpectProvincePanelMatchesE2eSnapshot]
///
/// The wrappers encapsulate per-panel root keys, snapshot globals, and
/// canonical phase-label literals. A silent regression in any of those
/// would either:
///
///   - Collapse the per-panel `E2E_TIMING` attribution into a single
///     `wait_until_found_panel_for_text_assertion` bucket (defeats the
///     AC8 timing tables that key on `wait_until_found_civilian_panel` /
///     `_naval_panel` / `_production_panel` / `open_panel_province`).
///   - Swap the panel-root key forwarded into the underlying
///     [e2eExpectPanelTextsMatchSnapshot], causing the null-snapshot guard
///     to surface a `reason:` line that names the wrong panel — pinning the
///     key by exercising the null-snapshot path keeps the diagnosis aligned.
///   - Drop the wider 30-second timeout for the province panel back to the
///     20-second default; the capital scenario mounts the province panel
///     later than the rail panels in `new_game_full_turn_e2e_test.dart`, so
///     the wider budget is required.
///   - Strip the `fleetTilesExpanded`-aware `anyOf` fallback from the naval
///     wrapper, re-introducing the pre-#2336 flake when the post-tap settle
///     lands on the collapsed mirror.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per `SPEC/program/e2e-integration-tests.md`
/// § CI), so this widget-test layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
library;

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_helpers.dart';
import '../integration_test/e2e_test_shared.dart' as shared;

/// Mounts a hit-testable panel root with the given children so the
/// `e2eWaitUntilFound` gate inside the underlying helper short-circuits on
/// the first poll. The wrapper exits before its timeout ever elapses,
/// isolating the contract under test to the panel-specific keys / phase
/// labels / snapshot global wiring composed by the wrapper.
Widget _wrap(Key panelRootKey, List<Widget> children) => MaterialApp(
  home: Scaffold(
    body: KeyedSubtree(
      key: panelRootKey,
      child: ListView(children: children),
    ),
  ),
);

/// Drops the four per-panel snapshot globals back to `null` so each
/// null-snapshot guard test starts from a clean slate; an earlier test
/// leaving a real snapshot in place would short-circuit the guard and
/// silently green the pin.
void _resetSnapshots() {
  ctE2eLastPanelSnapshot = null;
  ctE2eCivilianPanelSnapshot = null;
  ctE2eNavalPanelSnapshot = null;
  ctE2eProductionPanelSnapshot = null;
}

void main() {
  suppressLogsForTests();

  group('per-panel matcher default constants', () {
    test('kE2eExpectCivilianPanelTextsPhase preserves canonical literal', () {
      expect(
        kE2eExpectCivilianPanelTextsPhase,
        'wait_until_found_civilian_panel',
        reason:
            'The pre-lift inline closure forwarded this literal into '
            '`expectPanelTextsMatchSnapshot`; AC8 timing tables key on it. '
            'A silent rename here would orphan the civilian-panel `E2E_TIMING` '
            'attribution bucket.',
      );
    });

    test('kE2eExpectNavalPanelTextsPhase preserves canonical literal', () {
      expect(
        kE2eExpectNavalPanelTextsPhase,
        'wait_until_found_naval_panel',
        reason:
            'The pre-lift inline closure forwarded this literal; AC8 timing '
            'tables key on it. A silent rename would orphan the naval-panel '
            'attribution bucket.',
      );
    });

    test('kE2eExpectProductionPanelTextsPhase preserves canonical literal', () {
      expect(
        kE2eExpectProductionPanelTextsPhase,
        'wait_until_found_production_panel',
        reason:
            'The pre-lift inline closure forwarded this literal; AC8 timing '
            'tables key on it.',
      );
    });

    test(
      'kE2eExpectProvincePanelTextsPhase preserves capital-scenario literal',
      () {
        expect(
          kE2eExpectProvincePanelTextsPhase,
          'open_panel_province',
          reason:
              'The capital-panel scenario pre-lift passed this literal '
              'explicitly (matching the rest of the capital-scenario AC8 '
              'tags); a rename would orphan that bucket too.',
        );
      },
    );

    test('kE2eExpectProvincePanelTextsTimeout preserves the explicit 30-second '
        'budget used by the pre-lift capital-panel assertion', () {
      expect(
        kE2eExpectProvincePanelTextsTimeout,
        const Duration(seconds: 30),
        reason:
            'The capital-panel scenario mounts the province panel later in '
            'its run than the rail panels in the full-turn scenario; the '
            'pre-lift inline call passed 30s explicitly. Collapsing back to '
            'the 20-second default would surface as a flaky capital-panel '
            'wait on the slow CI lane only.',
      );
    });
  });

  group('e2eExpectCivilianPanelMatchesE2eSnapshot — null snapshot fails with '
      'civilian-panel root key in reason', () {
    testWidgets('null civilian snapshot → reason names panel root key', (
      tester,
    ) async {
      _resetSnapshots();
      await tester.pumpWidget(
        _wrap(kCtE2ECivilianPanelRootKey, const [Text('x')]),
      );
      final l10n = lookupAppLocalizations(const Locale('en'));
      try {
        await e2eExpectCivilianPanelMatchesE2eSnapshot(tester, l10n);
        fail(
          'expected the helper to throw a TestFailure when the civilian '
          'snapshot global is null',
        );
      } on TestFailure catch (e) {
        expect(
          e.message,
          isNotNull,
          reason: 'TestFailure messages must be populated for diagnosis.',
        );
        expect(
          e.message!,
          contains(kCtE2ECivilianPanelRootKey.toString()),
          reason:
              'A regression that forwarded the wrong panel-root key into '
              '`e2eExpectPanelTextsMatchSnapshot` would surface a '
              'reason: line that names a different panel; pinning the '
              'civilian root key in the failure message catches that drift '
              'without depending on the slow CI lane.',
        );
      }
    });
  });

  group('e2eExpectNavalPanelMatchesE2eSnapshot — null snapshot fails with '
      'naval-panel root key in reason', () {
    testWidgets(
      'null naval snapshot (expanded: false) → reason names panel root key',
      (tester) async {
        _resetSnapshots();
        await tester.pumpWidget(
          _wrap(kCtE2ENavalPanelRootKey, const [Text('x')]),
        );
        final l10n = lookupAppLocalizations(const Locale('en'));
        try {
          await e2eExpectNavalPanelMatchesE2eSnapshot(
            tester,
            l10n,
            expanded: false,
          );
          fail(
            'expected the helper to throw a TestFailure when the naval '
            'snapshot global is null',
          );
        } on TestFailure catch (e) {
          expect(
            e.message!,
            contains(kCtE2ENavalPanelRootKey.toString()),
            reason:
                'Forwarded panel-root key drift must be caught by the '
                'naval-panel pin.',
          );
        }
      },
    );

    testWidgets(
      'null naval snapshot (expanded: true) → reason still names panel '
      'root key (alternative fallback never reaches builder)',
      (tester) async {
        _resetSnapshots();
        await tester.pumpWidget(
          _wrap(kCtE2ENavalPanelRootKey, const [Text('x')]),
        );
        final l10n = lookupAppLocalizations(const Locale('en'));
        try {
          await e2eExpectNavalPanelMatchesE2eSnapshot(
            tester,
            l10n,
            expanded: true,
          );
          fail(
            'expected the helper to throw a TestFailure when the naval '
            'snapshot global is null even with the alternative-expected '
            'fallback wired',
          );
        } on TestFailure catch (e) {
          expect(
            e.message!,
            contains(kCtE2ENavalPanelRootKey.toString()),
            reason:
                'The `buildAlternativeExpected` fallback must NOT short-'
                'circuit the null-snapshot guard — the guard runs before '
                'either builder is invoked, so dereferencing `snap!` in '
                'the alternative would never be safe.',
          );
        }
      },
    );
  });

  group('e2eExpectProductionPanelMatchesE2eSnapshot — null snapshot fails with '
      'production-panel root key in reason', () {
    testWidgets('null production snapshot → reason names panel root key', (
      tester,
    ) async {
      _resetSnapshots();
      await tester.pumpWidget(
        _wrap(kCtE2EProductionPanelRootKey, const [Text('x')]),
      );
      final l10n = lookupAppLocalizations(const Locale('en'));
      try {
        await e2eExpectProductionPanelMatchesE2eSnapshot(tester, l10n);
        fail(
          'expected the helper to throw a TestFailure when the production '
          'snapshot global is null',
        );
      } on TestFailure catch (e) {
        expect(
          e.message!,
          contains(kCtE2EProductionPanelRootKey.toString()),
          reason:
              'Forwarded panel-root key drift must be caught by the '
              'production-panel pin.',
        );
      }
    });
  });

  group('e2eExpectProvincePanelMatchesE2eSnapshot — null snapshot fails with '
      'province-panel root key in reason', () {
    testWidgets('null province snapshot → reason names panel root key', (
      tester,
    ) async {
      _resetSnapshots();
      await tester.pumpWidget(
        _wrap(kCtE2EProvincePanelRootKey, const [Text('x')]),
      );
      final l10n = lookupAppLocalizations(const Locale('en'));
      try {
        await e2eExpectProvincePanelMatchesE2eSnapshot(tester, l10n);
        fail(
          'expected the helper to throw a TestFailure when the province '
          'snapshot global is null',
        );
      } on TestFailure catch (e) {
        expect(
          e.message!,
          contains(kCtE2EProvincePanelRootKey.toString()),
          reason:
              'Forwarded panel-root key drift must be caught by the '
              'province-panel pin.',
        );
      }
    });
  });

  group(
    'per-panel matchers — AC1 barrel forwarding (compile-time signature pin)',
    () {
      test(
        'expectCivilianPanelMatchesE2eSnapshot is re-exported as a tear-off',
        () {
          final Future<void> Function(
            WidgetTester,
            AppLocalizations, {
            shared.E2ePerfLog? perf,
          })
          ref = expectCivilianPanelMatchesE2eSnapshot;
          expect(
            ref,
            isNotNull,
            reason:
                'A silent removal from the AC1 barrel `show` clause, an '
                'arg-order swap, or a signature change would fail this '
                'assignment at compile time, not at slow-CI E2E time.',
          );
        },
      );

      test(
        'expectNavalPanelMatchesE2eSnapshot is re-exported as a tear-off',
        () {
          final Future<void> Function(
            WidgetTester,
            AppLocalizations, {
            required bool expanded,
            shared.E2ePerfLog? perf,
          })
          ref = expectNavalPanelMatchesE2eSnapshot;
          expect(
            ref,
            isNotNull,
            reason:
                'The naval wrapper must keep the required `expanded:` named '
                'parameter on the AC1 barrel; dropping it back to the '
                'pre-lift positional inline closure shape would break the '
                'full-turn scenario at compile time.',
          );
        },
      );

      test(
        'expectProductionPanelMatchesE2eSnapshot is re-exported as a tear-off',
        () {
          final Future<void> Function(
            WidgetTester,
            AppLocalizations, {
            shared.E2ePerfLog? perf,
          })
          ref = expectProductionPanelMatchesE2eSnapshot;
          expect(ref, isNotNull);
        },
      );

      test(
        'expectProvincePanelMatchesE2eSnapshot is re-exported as a tear-off',
        () {
          final Future<void> Function(
            WidgetTester,
            AppLocalizations, {
            shared.E2ePerfLog? perf,
          })
          ref = expectProvincePanelMatchesE2eSnapshot;
          expect(ref, isNotNull);
        },
      );
    },
  );
}
