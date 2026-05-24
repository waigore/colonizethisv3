/// Pins the widget-tree contract of
/// [e2eAwaitExploreEnabledFromCivilianPanel]
/// (`app/integration_test/e2e_test_shared_bundled_explore_retry.dart`).
///
/// The post-bundle Explore scenario in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` calls this helper via
/// the AC1 barrel alias `awaitExploreEnabledFromCivilianPanel` to bridge
/// the strict bundled-Explore assertion (`anyExplorerHasEnabledExploreAssignFleet`)
/// with the bounded next-turn retry window that absorbs CI suggestion-
/// propagation lag.
///
/// A silent regression here would either:
///
///   - Drop the per-iteration `perf.bumpCounter(...)` call and orphan
///     every `E2E_COUNTER|...|name=bundled_explore_retry_iterations|...`
///     scraper / dashboard keyed on the bounded retry budget — hiding
///     Bottleneck 5 regressions.
///   - Flip the boolean encoding (return `true` on bounded exhaustion or
///     `false` on initial-check success) and silently invert the
///     post-bundle Explore-enabled assertion.
///   - Bump the default [kE2eDefaultBundledExploreMaxTurnRetries] (8) or
///     rename [kE2eDefaultBundledExploreRetryIterationCounter]
///     (`bundled_explore_retry_iterations`) and orphan every dashboard
///     keyed on the legacy literal.
///   - Skip the retry loop entirely on a `false` initial check —
///     converting a recoverable lag-window regression into an immediate
///     `fail()` and inflating the post-bundle scenario's failure rate
///     past the bounded-retry tolerance #2336 / #1869 absorbs.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test
/// layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / AC5 / Bottleneck 5.
library;

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildRoad, kWorkTargetExplore;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_helpers.dart';
import '../integration_test/e2e_test_shared.dart' as shared;

const String _human = 'gp1';

const TurnState _orderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const Orders _emptyOrders = Orders();

Game _game() => const Game(
  id: 'g1',
  worldState: WorldState(
    turnState: _orderingTurn,
    oldWorld: RegionData(),
    newWorld: RegionData(),
  ),
  players: [Player(id: _human, displayName: 'You', isHuman: true)],
);

CtE2eCivilianPanelSnapshot _civilianSnapshot({
  Map<String, List<String>> availableWorkTargets = const {},
}) => CtE2eCivilianPanelSnapshot(
  game: _game(),
  humanPlayerId: _human,
  currentOrders: _emptyOrders,
  availableWorkTargets: availableWorkTargets,
);

/// Mounts a hit-testable civilian panel root with a stub child so
/// [e2eOpenCivilianPanel] short-circuits on its
/// `civilianPanel.hitTestable().evaluate().isNotEmpty` precondition.
/// Combined with the snapshot short-circuit in
/// [e2eAnyExplorerHasEnabledExploreAssignFleet], this isolates the
/// retry-loop contract under test from the full game UI.
Widget _wrap() => MaterialApp(
  home: Scaffold(
    body: KeyedSubtree(
      key: kCtE2ECivilianPanelRootKey,
      child: ListView(children: const [ListTile(title: Text('Stub'))]),
    ),
  ),
);

/// Captures every `debugPrint` line emitted while [body] runs and restores
/// the original printer afterwards (defensive in `finally` so a thrown
/// expectation does not leak the override into later tests).
Future<List<String>> _captureDebugPrints(Future<void> Function() body) async {
  final captured = <String>[];
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    captured.add(message ?? '');
  };
  try {
    await body();
  } finally {
    debugPrint = original;
  }
  return captured;
}

void main() {
  suppressLogsForTests();

  final l10n = lookupAppLocalizations(const Locale('en'));

  setUp(() {
    ctE2eCivilianPanelSnapshot = null;
  });

  tearDown(() {
    ctE2eCivilianPanelSnapshot = null;
  });

  group('e2eAwaitExploreEnabledFromCivilianPanel — default constants', () {
    test('kE2eDefaultBundledExploreMaxTurnRetries preserves the legacy '
        'inline `maxBoundedTurnRetries = 8` literal', () {
      expect(
        kE2eDefaultBundledExploreMaxTurnRetries,
        8,
        reason:
            'Pre-lift fleet `for (var retryIdx = 0; ... retryIdx < 8; ...)` '
            'callers and downstream wall-clock budgeting expect the bounded '
            'retry window to remain at exactly 8 turns. A silent change '
            'here would either inflate the post-bundle Explore wall clock '
            'past the `_kMaxUiResponseWait (5s)` cap #2336 is reducing or '
            'shrink the window below the CI suggestion-propagation lag '
            'tolerance #1869 / Bottleneck 5 absorbs.',
      );
    });

    test('kE2eDefaultBundledExploreRetryIterationCounter preserves the '
        'legacy inline `bumpCounter` name', () {
      expect(
        kE2eDefaultBundledExploreRetryIterationCounter,
        'bundled_explore_retry_iterations',
        reason:
            'Pre-lift `perf.bumpCounter("bundled_explore_retry_iterations")` '
            'callers and downstream `E2E_COUNTER|test=...|name=...` '
            'log scrapers / AC8 dashboards expect this exact literal. A '
            'silent rename would orphan every dashboard counting bounded '
            'retry iterations and hide Bottleneck 5 regressions.',
      );
    });
  });

  group('e2eAwaitExploreEnabledFromCivilianPanel — initial-check '
      'short-circuit', () {
    testWidgets('snapshot says Explore enabled -> returns true and never '
        'increments the retry counter', (tester) async {
      ctE2eCivilianPanelSnapshot = _civilianSnapshot(
        availableWorkTargets: const {
          'explorer-1': [kWorkTargetExplore],
        },
      );
      await tester.pumpWidget(_wrap());
      final perf = shared.E2ePerfLog('await_explore_pin');
      late bool result;
      final lines = await _captureDebugPrints(() async {
        result = await e2eAwaitExploreEnabledFromCivilianPanel(
          tester,
          l10n,
          perf: perf,
          maxUiResponseWait: const Duration(seconds: 5),
        );
      });
      expect(result, isTrue);
      final retryCounterLines = lines
          .where(
            (line) =>
                line.startsWith('E2E_COUNTER|') &&
                line.contains(
                  '|name=$kE2eDefaultBundledExploreRetryIterationCounter|',
                ),
          )
          .toList();
      expect(
        retryCounterLines,
        isEmpty,
        reason:
            'A successful initial check must short-circuit without entering '
            'the retry loop. Bumping `bundled_explore_retry_iterations` '
            'on a first-pass success would inflate every post-bundle '
            'Explore-enabled run\'s retry attribution and skew Bottleneck 5 '
            'cost dashboards.',
      );
    });

    testWidgets('perf is null -> no E2E_COUNTER markers emitted on initial '
        'short-circuit', (tester) async {
      ctE2eCivilianPanelSnapshot = _civilianSnapshot(
        availableWorkTargets: const {
          'explorer-1': [kWorkTargetExplore],
        },
      );
      await tester.pumpWidget(_wrap());
      late bool result;
      final lines = await _captureDebugPrints(() async {
        result = await e2eAwaitExploreEnabledFromCivilianPanel(
          tester,
          l10n,
          maxUiResponseWait: const Duration(seconds: 5),
        );
      });
      expect(result, isTrue);
      expect(
        lines.where(
          (line) =>
              line.startsWith('E2E_COUNTER|') &&
              line.contains(
                '|name=$kE2eDefaultBundledExploreRetryIterationCounter|',
              ),
        ),
        isEmpty,
        reason:
            'Callers that opt out of perf logging (no shared `E2ePerfLog`) '
            'must not trigger spurious counter markers; the helper must '
            'guard the `perf?.bumpCounter(...)` call with a null check so '
            'unit tests / future stand-alone callers can use the helper '
            'without instantiating a perf log.',
      );
    });
  });

  group('e2eAwaitExploreEnabledFromCivilianPanel — zero-retry budget', () {
    testWidgets('maxBoundedTurnRetries: 0 with disabled snapshot -> returns '
        'false without entering the retry loop', (tester) async {
      ctE2eCivilianPanelSnapshot = _civilianSnapshot(
        availableWorkTargets: const {
          'unit-1': [kWorkTargetBuildRoad],
        },
      );
      await tester.pumpWidget(_wrap());
      final perf = shared.E2ePerfLog('await_explore_pin');
      late bool result;
      final lines = await _captureDebugPrints(() async {
        result = await e2eAwaitExploreEnabledFromCivilianPanel(
          tester,
          l10n,
          perf: perf,
          maxUiResponseWait: const Duration(seconds: 5),
          maxBoundedTurnRetries: 0,
        );
      });
      expect(result, isFalse);
      final retryCounterLines = lines
          .where(
            (line) =>
                line.startsWith('E2E_COUNTER|') &&
                line.contains(
                  '|name=$kE2eDefaultBundledExploreRetryIterationCounter|',
                ),
          )
          .toList();
      expect(
        retryCounterLines,
        isEmpty,
        reason:
            'A zero retry budget must structurally skip the retry loop, '
            'returning whatever the initial check reported. A regression '
            'that ran one iteration before testing the bound (`do { ... } '
            'while (...)`) would emit a spurious counter bump and drive '
            'the next-turn UI even when the caller explicitly opted out.',
      );
    });

    testWidgets('maxBoundedTurnRetries: 0 with enabled snapshot -> returns '
        'true (initial-check short-circuit still wins)', (tester) async {
      ctE2eCivilianPanelSnapshot = _civilianSnapshot(
        availableWorkTargets: const {
          'explorer-1': [kWorkTargetExplore],
        },
      );
      await tester.pumpWidget(_wrap());
      final perf = shared.E2ePerfLog('await_explore_pin');
      final result = await e2eAwaitExploreEnabledFromCivilianPanel(
        tester,
        l10n,
        perf: perf,
        maxBoundedTurnRetries: 0,
      );
      expect(
        result,
        isTrue,
        reason:
            'The retry budget bound only governs how many retry iterations '
            'run AFTER the initial check fails. An enabled snapshot must '
            'still return `true` even when `maxBoundedTurnRetries: 0`, '
            'since the initial check is structurally outside the loop.',
      );
    });
  });

  group('e2eAwaitExploreEnabledFromCivilianPanel — retry counter override',
      () {
    testWidgets('retryIterationCounter override propagates into the bumped '
        'counter name (zero-budget pin guards the no-op path)', (
      tester,
    ) async {
      // With maxBoundedTurnRetries: 0 the override never bumps in this
      // fixture, but the parameter must still be accepted at the call
      // site. A regression that hard-coded the default would surface in
      // the AC1 barrel-forwarding test below; this test pins the
      // implementation-side parameter as part of the contract.
      ctE2eCivilianPanelSnapshot = _civilianSnapshot(
        availableWorkTargets: const {
          'unit-1': [kWorkTargetBuildRoad],
        },
      );
      await tester.pumpWidget(_wrap());
      final perf = shared.E2ePerfLog('await_explore_pin');
      final result = await e2eAwaitExploreEnabledFromCivilianPanel(
        tester,
        l10n,
        perf: perf,
        maxBoundedTurnRetries: 0,
        retryIterationCounter: 'pin_custom_retry_counter',
      );
      expect(result, isFalse);
    });
  });

  group('e2eAwaitExploreEnabledFromCivilianPanel — AC1 barrel forwarding',
      () {
    testWidgets(
      'awaitExploreEnabledFromCivilianPanel (barrel alias) returns the '
      'same boolean as the lifted form',
      (tester) async {
        ctE2eCivilianPanelSnapshot = _civilianSnapshot(
          availableWorkTargets: const {
            'explorer-1': [kWorkTargetExplore],
          },
        );
        await tester.pumpWidget(_wrap());
        final result = await awaitExploreEnabledFromCivilianPanel(
          tester,
          l10n,
        );
        expect(
          result,
          isTrue,
          reason:
              'The AC1 barrel wrapper must forward all named arguments in '
              'the documented order and preserve the boolean return '
              'value. A regression that dropped `tester` / `l10n` from '
              'the signature, swapped `perf` with `maxUiResponseWait`, '
              'or fail-opened to `false` would surface here, not in the '
              'slow CI lane.',
        );
      },
    );

    test('awaitExploreEnabledFromCivilianPanel is re-exported as a '
        'tear-off (compile-time signature pin)', () {
      final Future<bool> Function(
        WidgetTester,
        AppLocalizations, {
        shared.E2ePerfLog? perf,
        Duration maxUiResponseWait,
        int maxBoundedTurnRetries,
        String retryIterationCounter,
      })
      ref = awaitExploreEnabledFromCivilianPanel;
      expect(
        ref,
        isNotNull,
        reason:
            'The AC1 barrel must continue to export the helper with the '
            'documented signature. A silent removal from the `show` '
            'clause, an arg-order swap on the wrapper, or a changed '
            'default for `maxBoundedTurnRetries` / '
            '`retryIterationCounter` / `maxUiResponseWait` would fail '
            'this assignment at compile time.',
      );
    });
  });
}
