/// Pins the widget-tree contract of
/// [e2ePickFirstValidWorkTileAndAwaitOverlayClear] (strict) and
/// [e2eMaybePickFirstValidWorkTileAndAwaitOverlayClear] (best-effort) in
/// `app/integration_test/e2e_test_shared_civilian_work_tile_pick.dart`.
///
/// The full-turn E2E scenario in `new_game_full_turn_e2e_test.dart` calls
/// the strict variant once after tapping the **Build improvement**
/// civilian action, and the best-effort variant once after tapping the
/// Explorer **Prospect** civilian action, so the
/// `kCtE2ESelectFirstValidWorkTileKey` overlay [InkWell] is tapped exactly
/// once per panel and the post-tap settle clears the overlay before the
/// next panel-close handoff (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6).
///
/// A silent rename or behavioural drift here would either:
///
///   - Skip the strict `e2eWaitUntilFound` gate and let the test pass on
///     a panel that silently failed to mount the overlay — masking a
///     work-target regression until the next phase fails for unrelated
///     reasons; or
///   - Drop the best-effort `meta=skipped_no_valid_tile_on_e2e_map`
///     timing entry and orphan the AC8 dashboard attribution for the
///     "Prospect on this map had no valid tile" branch; or
///   - Convert the `warnIfMissed: false` tap into the default `true`
///     and re-introduce the warning flood the legacy block intentionally
///     silenced on the off-by-one frame between predicate and tap.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
library;

import 'package:colonizethis_app/config/ct_e2e.dart'
    show kCtE2ESelectFirstValidWorkTileKey;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Mounts an [InkWell] keyed by [kCtE2ESelectFirstValidWorkTileKey] inside
/// a [Material] ancestor so [WidgetTester.tap] resolves the same gesture
/// surface as the production overlay in `game_map_area_part2.dart`. The
/// host removes the overlay on tap so the strict and best-effort
/// `pump_until_work_tile_overlay_cleared_*` settles see the same
/// "tap → unmount" transition the real overlay produces.
class _OverlayHost extends StatefulWidget {
  const _OverlayHost();

  @override
  State<_OverlayHost> createState() => _OverlayHostState();
}

class _OverlayHostState extends State<_OverlayHost> {
  bool _visible = true;
  int taps = 0;

  void _onTap() {
    taps++;
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: !_visible
              ? const SizedBox.shrink(key: ValueKey('overlay-cleared'))
              : SizedBox(
                  width: 64,
                  height: 64,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: kCtE2ESelectFirstValidWorkTileKey,
                      onTap: _onTap,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Mounts no overlay at all so the appearance-wait branches (strict
/// `e2eWaitUntilFound` fail / best-effort `e2ePumpUntilConditionOrIdle`
/// false) both see a permanently absent finder.
class _EmptyHost extends StatelessWidget {
  const _EmptyHost();

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: Scaffold(body: SizedBox.shrink()));
}

void main() {
  suppressLogsForTests();

  group('e2ePickFirstValidWorkTileAndAwaitOverlayClear — happy path', () {
    testWidgets('taps the overlay once and pumps until it unmounts', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const _OverlayHost());
      expect(find.byKey(kCtE2ESelectFirstValidWorkTileKey), findsOneWidget);

      await e2ePickFirstValidWorkTileAndAwaitOverlayClear(
        tester,
        appearPhase: 'wait_until_first_valid_work_tile_after_build_improvement',
        clearPhase: 'pump_until_work_tile_overlay_cleared_build',
      );

      final state = tester.state<_OverlayHostState>(find.byType(_OverlayHost));
      expect(
        state.taps,
        1,
        reason:
            'Helper must tap the overlay exactly once; a regression that '
            'fell through both branches would tap twice.',
      );
      expect(
        find.byKey(kCtE2ESelectFirstValidWorkTileKey),
        findsNothing,
        reason:
            'The pump-until-cleared loop must observe the unmount before '
            'returning — otherwise the next panel-open in the full-turn '
            'scenario would race a stale InkWell.',
      );
    });
  });

  group('e2ePickFirstValidWorkTileAndAwaitOverlayClear — missing overlay', () {
    testWidgets('fails the test when the overlay never becomes hit-testable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const _EmptyHost());

      Object? caught;
      try {
        await e2ePickFirstValidWorkTileAndAwaitOverlayClear(
          tester,
          appearPhase:
              'wait_until_first_valid_work_tile_after_build_improvement',
          clearPhase: 'pump_until_work_tile_overlay_cleared_build',
          appearTimeout: const Duration(milliseconds: 50),
          clearTimeout: const Duration(milliseconds: 50),
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'The strict variant must fail the test (via e2eWaitUntilFound) '
            'when the overlay never appears — the Build improvement contract '
            'guarantees a valid tile on the E2E map; silent skip would mask '
            'a regression.',
      );
    });
  });

  group('e2eMaybePickFirstValidWorkTileAndAwaitOverlayClear — happy path', () {
    testWidgets(
      'taps the overlay once with warnIfMissed=false and returns true',
      (WidgetTester tester) async {
        await tester.pumpWidget(const _OverlayHost());

        final picked = await e2eMaybePickFirstValidWorkTileAndAwaitOverlayClear(
          tester,
          appearPhase: 'pump_until_prospect_work_tile_optional',
          clearPhase: 'pump_until_work_tile_overlay_cleared_prospect',
          skippedTimingLabel: 'prospect_work_tile',
          skippedMeta: 'skipped_no_valid_tile_on_e2e_map',
        );

        expect(picked, isTrue);
        final state = tester.state<_OverlayHostState>(
          find.byType(_OverlayHost),
        );
        expect(state.taps, 1);
        expect(find.byKey(kCtE2ESelectFirstValidWorkTileKey), findsNothing);
      },
    );
  });

  group('e2eMaybePickFirstValidWorkTileAndAwaitOverlayClear — skip branch', () {
    testWidgets(
      'returns false and emits the skipped meta timing when the overlay never '
      'appears',
      (WidgetTester tester) async {
        await tester.pumpWidget(const _EmptyHost());

        final perf = E2ePerfLog('prospect_skip');
        final lines = <String>[];
        final original = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          lines.add(message ?? '');
        };
        bool picked;
        try {
          picked = await e2eMaybePickFirstValidWorkTileAndAwaitOverlayClear(
            tester,
            appearPhase: 'pump_until_prospect_work_tile_optional',
            clearPhase: 'pump_until_work_tile_overlay_cleared_prospect',
            skippedTimingLabel: 'prospect_work_tile',
            skippedMeta: 'skipped_no_valid_tile_on_e2e_map',
            appearTimeout: const Duration(milliseconds: 50),
            clearTimeout: const Duration(milliseconds: 50),
            perf: perf,
          );
        } finally {
          debugPrint = original;
        }

        expect(
          picked,
          isFalse,
          reason:
              'Best-effort variant must return false (not throw) when the '
              'overlay never appears — Prospect is allowed to no-op on E2E '
              'maps that lack a valid tile.',
        );
        expect(
          lines.any(
            (l) =>
                l.startsWith('E2E_TIMING') &&
                l.contains('phase=prospect_work_tile') &&
                l.contains('ms=0') &&
                l.contains('meta=skipped_no_valid_tile_on_e2e_map'),
          ),
          isTrue,
          reason:
              'Skip branch must emit perf.timing(skippedTimingLabel, '
              'Duration.zero, meta: skippedMeta) so AC8 dashboards keep '
              'attribution for the "no valid tile" branch separate from a '
              'regression in the Build improvement contract.',
        );
      },
    );

    testWidgets(
      'does not emit the skipped meta when perf is null but still returns false',
      (WidgetTester tester) async {
        await tester.pumpWidget(const _EmptyHost());

        final lines = <String>[];
        final original = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          lines.add(message ?? '');
        };
        bool picked;
        try {
          picked = await e2eMaybePickFirstValidWorkTileAndAwaitOverlayClear(
            tester,
            appearPhase: 'pump_until_prospect_work_tile_optional',
            clearPhase: 'pump_until_work_tile_overlay_cleared_prospect',
            skippedTimingLabel: 'prospect_work_tile',
            skippedMeta: 'skipped_no_valid_tile_on_e2e_map',
            appearTimeout: const Duration(milliseconds: 50),
            clearTimeout: const Duration(milliseconds: 50),
          );
        } finally {
          debugPrint = original;
        }

        expect(picked, isFalse);
        expect(
          lines.any(
            (l) =>
                l.startsWith('E2E_TIMING') &&
                l.contains('phase=prospect_work_tile'),
          ),
          isFalse,
          reason:
              'The helper must guard the perf.timing call with `perf?.` so '
              'callers without an E2ePerfLog (test fixtures, smoke probes) do '
              'not throw a null reference exception.',
        );
      },
    );
  });

  group('Default constants', () {
    test(
      'kE2eDefaultCivilianWorkTileAppearTimeout matches legacy 15 s budget',
      () {
        expect(
          kE2eDefaultCivilianWorkTileAppearTimeout,
          const Duration(seconds: 15),
          reason:
              'A silent budget bump would change wall-clock guarantees for '
              'every call site that relies on the default; require an explicit '
              'override at the call site instead. Refs GitHub #2336 / AC4.',
        );
      },
    );

    test(
      'kE2eDefaultCivilianWorkTileClearTimeout matches legacy 5 s budget',
      () {
        expect(
          kE2eDefaultCivilianWorkTileClearTimeout,
          const Duration(seconds: 5),
          reason:
              'A silent budget bump would change wall-clock guarantees for '
              'every call site that relies on the default; require an explicit '
              'override at the call site instead. Refs GitHub #2336 / AC4.',
        );
      },
    );
  });

  group('Perf wiring', () {
    testWidgets(
      'strict variant forwards appearPhase and clearPhase verbatim through '
      'e2eWaitUntilFound and e2ePumpUntil',
      (WidgetTester tester) async {
        await tester.pumpWidget(const _OverlayHost());
        final perf = E2ePerfLog('work_tile_strict_phase');

        final lines = <String>[];
        final original = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          lines.add(message ?? '');
        };
        try {
          await e2ePickFirstValidWorkTileAndAwaitOverlayClear(
            tester,
            appearPhase: 'custom_appear_phase',
            clearPhase: 'custom_clear_phase',
            perf: perf,
          );
        } finally {
          debugPrint = original;
        }

        expect(
          lines.any(
            (l) =>
                l.startsWith('E2E_TIMING') &&
                l.contains('phase=custom_appear_phase'),
          ),
          isTrue,
          reason:
              'appearPhase must be forwarded verbatim to e2eWaitUntilFound — '
              'log scrapers and dashboards key on the exact phase literal.',
        );
        expect(
          lines.any(
            (l) =>
                l.startsWith('E2E_TIMING') &&
                l.contains('phase=custom_clear_phase'),
          ),
          isTrue,
          reason:
              'clearPhase must be forwarded verbatim to e2ePumpUntil — log '
              'scrapers and dashboards key on the exact phase literal.',
        );
      },
    );
  });
}
