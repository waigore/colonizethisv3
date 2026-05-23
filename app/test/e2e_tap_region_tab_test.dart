/// Pins the **tap-and-settle** contract of `e2eTapNewWorldRegionTabIfPresent`
/// and `e2eTapOldWorldRegionTab` (`app/integration_test/e2e_test_shared.dart`).
///
/// Both helpers were lifted from
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart` so the
/// `kCtE2ERegionTabNewWorldKey` and `CtChoiceChip + region_oldWorld` tap
/// contracts are shared, canonical, and unit-pinned at the widget layer
/// (Refs GitHub #2336 AC1 / AC2 / AC5). They sit on the fleet-reach hot path
/// (`_tryNavalMoveSegment`, `_awaitNwCoastalOrVisibleLandForBundledExploreE2e`)
/// inside the `_kMaxNextTurnTapsForNwFleetReach = 35` turn loop, so a silent
/// regression — for example dropping the `.hitTestable()` guard, throwing on
/// timeout, or skipping the chip-selected poll — would regress the
/// wall-clock-bound paths #2336 is shrinking.
///
/// Because `integration_test/` runs behind a no-op `app_e2e_linux` lane today
/// (`SPEC/program/e2e-integration-tests.md` § CI), these widget-test pins are
/// the only per-PR enforcement gate for the tap contracts. The existing
/// `e2e_region_chip_selected_test.dart` pins the **predicate** branches of the
/// `e2eOldWorldRegionChipAppearsSelected` / `e2eNewWorldRegionChipAppearsSelected`
/// helpers; this file pins the **tap-and-poll wrappers** that compose them.
library;

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Toggling host for a single [CtChoiceChip] wrapped in a [KeyedSubtree] with
/// the [kCtE2ERegionTabNewWorldKey] so `find.byKey(...).hitTestable()` resolves
/// and an `onSelected` flip drives [e2eNewWorldRegionChipAppearsSelected] true.
class _NewWorldRegionTabHost extends StatefulWidget {
  const _NewWorldRegionTabHost();

  @override
  State<_NewWorldRegionTabHost> createState() => _NewWorldRegionTabHostState();
}

class _NewWorldRegionTabHostState extends State<_NewWorldRegionTabHost> {
  bool selected = false;
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: kCtE2ERegionTabNewWorldKey,
      child: CtChoiceChip(
        label: const Text('New World'),
        selected: selected,
        onSelected: (next) {
          taps++;
          setState(() => selected = next);
        },
      ),
    );
  }
}

/// Toggling host for a single Old World [CtChoiceChip] (no keyed subtree —
/// `e2eTapOldWorldRegionTab` matches by label text via `widgetWithText`).
class _OldWorldRegionTabHost extends StatefulWidget {
  const _OldWorldRegionTabHost({required this.label});

  final String label;

  @override
  State<_OldWorldRegionTabHost> createState() => _OldWorldRegionTabHostState();
}

class _OldWorldRegionTabHostState extends State<_OldWorldRegionTabHost> {
  bool selected = false;
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    return CtChoiceChip(
      label: Text(widget.label),
      selected: selected,
      onSelected: (next) {
        taps++;
        setState(() => selected = next);
      },
    );
  }
}

Future<void> _pumpScaffold(WidgetTester tester, Widget body) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: body)),
  );
}

void main() {
  suppressLogsForTests();

  group('e2eTapNewWorldRegionTabIfPresent', () {
    testWidgets(
      'no-op when the keyed New World subtree is absent (no exception)',
      (WidgetTester tester) async {
        await _pumpScaffold(tester, const SizedBox());
        await e2eTapNewWorldRegionTabIfPresent(tester);
        // Helper must keep the silent-absent contract so scenarios where the
        // map controls have not mounted yet (e.g. capital-panel paths) can
        // compose it unconditionally without paying a failure or pump cost.
      },
    );

    testWidgets(
      'no-op when the keyed subtree exists but is not hit-testable',
      (WidgetTester tester) async {
        // `IgnorePointer` makes the keyed subtree non-hit-testable while
        // keeping `find.byKey(...)` non-empty — the helper must rely on the
        // `.hitTestable()` filter, not raw presence.
        await _pumpScaffold(
          tester,
          const IgnorePointer(
            child: KeyedSubtree(
              key: kCtE2ERegionTabNewWorldKey,
              child: SizedBox(width: 40, height: 24),
            ),
          ),
        );
        await e2eTapNewWorldRegionTabIfPresent(tester);
        // No tap fires; helper returns cleanly. A regression that dropped
        // `.hitTestable()` would attempt to tap a non-hit-testable target and
        // surface a flaky `warnIfMissed` log on Linux CI.
      },
    );

    testWidgets(
      'taps the keyed subtree and short-circuits once the chip flips selected',
      (WidgetTester tester) async {
        await _pumpScaffold(tester, const _NewWorldRegionTabHost());
        final hostState = tester.state<_NewWorldRegionTabHostState>(
          find.byType(_NewWorldRegionTabHost),
        );
        expect(hostState.selected, isFalse);
        expect(hostState.taps, 0);

        final sw = Stopwatch()..start();
        await e2eTapNewWorldRegionTabIfPresent(tester);
        sw.stop();

        expect(
          hostState.taps,
          1,
          reason:
              'Helper must tap exactly once when the keyed subtree is '
              'hit-testable; a missed tap or double-tap would either stall the '
              'region-tab settle or thrash the chip back to its original state.',
        );
        expect(
          hostState.selected,
          isTrue,
          reason:
              'After the tap, the chip is selected and the adaptive post-tap '
              'settle must observe the flip via '
              'e2eNewWorldRegionChipAppearsSelected so the helper returns.',
        );
        expect(
          e2eNewWorldRegionChipAppearsSelected(),
          isTrue,
          reason:
              'The composed predicate must remain in sync with the chip state '
              'so downstream callers (fleet-reach turn loop) can re-check it '
              'without re-tapping.',
        );
        expect(
          sw.elapsed < const Duration(seconds: 2),
          isTrue,
          reason:
              'Helper must settle well within the bounded 500ms post-tap cap; '
              'a regression that ballooned the cap (or never short-circuited) '
              'would directly inflate the 35-turn fleet-reach wall clock '
              '(#2336 Bottleneck 4).',
        );
      },
    );

    testWidgets(
      'returns without throwing when the chip never flips selected',
      (WidgetTester tester) async {
        // CtChoiceChip + InkWell will record taps, but our host swaps
        // `onSelected` for a no-op so selection never flips — the helper
        // must hit the timeout without throwing (best-effort settle).
        await _pumpScaffold(
          tester,
          KeyedSubtree(
            key: kCtE2ERegionTabNewWorldKey,
            child: CtChoiceChip(
              label: const Text('New World'),
              selected: false,
              onSelected: (_) {},
            ),
          ),
        );

        Object? caught;
        try {
          await e2eTapNewWorldRegionTabIfPresent(tester);
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNull,
          reason:
              'Helper composes the best-effort '
              'e2ePumpUntilConditionOrIdle and MUST NOT throw on timeout — '
              'callers treat the wait as an optional post-tap settle '
              '(#2336 AC5).',
        );
        expect(
          e2eNewWorldRegionChipAppearsSelected(),
          isFalse,
          reason:
              'Sanity: with onSelected stubbed to no-op the chip stays '
              'unselected, exercising the timeout branch of the helper.',
        );
      },
    );
  });

  group('e2eTapOldWorldRegionTab', () {
    testWidgets(
      'no-op when no CtChoiceChip with the Old World label is mounted',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await _pumpScaffold(tester, const SizedBox());
        await e2eTapOldWorldRegionTab(tester, l10n);
        // No chip → no tap fires; helper returns cleanly. Required so the
        // _tryNavalMoveSegment OW path can compose unconditionally without
        // paying a fail() on screens that have not mounted the OW tab.
      },
    );

    testWidgets(
      'no-op when matching chip exists but is not hit-testable',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await _pumpScaffold(
          tester,
          IgnorePointer(
            child: CtChoiceChip(
              label: Text(l10n.region_oldWorld),
              selected: false,
              onSelected: (_) {},
            ),
          ),
        );
        await e2eTapOldWorldRegionTab(tester, l10n);
        // Helper must rely on the `.hitTestable()` filter — otherwise a
        // chip behind IgnorePointer (during a bottom-sheet route push, for
        // example) would absorb a no-op tap and trip warnIfMissed on CI.
      },
    );

    testWidgets(
      'taps the matching chip and short-circuits once selection flips',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await _pumpScaffold(
          tester,
          _OldWorldRegionTabHost(label: l10n.region_oldWorld),
        );
        final hostState = tester.state<_OldWorldRegionTabHostState>(
          find.byType(_OldWorldRegionTabHost),
        );
        expect(hostState.selected, isFalse);
        expect(hostState.taps, 0);

        final sw = Stopwatch()..start();
        await e2eTapOldWorldRegionTab(tester, l10n);
        sw.stop();

        expect(
          hostState.taps,
          1,
          reason:
              'Helper must tap the matching chip exactly once; a missed tap '
              'would stall the OW region-tab settle on the fleet-reach OW '
              'split path.',
        );
        expect(
          hostState.selected,
          isTrue,
          reason:
              'After the tap, the OW chip is selected; the adaptive settle '
              'must observe it via e2eOldWorldRegionChipAppearsSelected so '
              'the helper returns promptly.',
        );
        expect(
          e2eOldWorldRegionChipAppearsSelected(l10n),
          isTrue,
          reason:
              'Composed predicate stays in sync with the chip state so the '
              'caller can re-check without re-tapping.',
        );
        expect(
          sw.elapsed < const Duration(seconds: 2),
          isTrue,
          reason:
              'Settle must short-circuit well within the bounded 500ms cap; '
              'a regression here would inflate the 35-turn fleet-reach wall '
              'clock alongside the NW-tab variant (#2336 Bottleneck 4).',
        );
      },
    );

    testWidgets(
      'taps only the first matching chip when multiple OW labels are mounted',
      (WidgetTester tester) async {
        // The helper uses `find.widgetWithText(CtChoiceChip, ...).hitTestable().first`.
        // A regression that switched to `last` or `at(n)` could tap a stale
        // chip during a rebuild (the fleet-loop region tab briefly hosts two
        // chip instances during a tab flip).
        final l10n = lookupAppLocalizations(const Locale('en'));
        await _pumpScaffold(
          tester,
          Column(
            children: <Widget>[
              _OldWorldRegionTabHost(label: l10n.region_oldWorld),
              _OldWorldRegionTabHost(label: l10n.region_oldWorld),
            ],
          ),
        );

        final hostStates = tester
            .stateList<_OldWorldRegionTabHostState>(
              find.byType(_OldWorldRegionTabHost),
            )
            .toList();
        expect(hostStates, hasLength(2));

        await e2eTapOldWorldRegionTab(tester, l10n);

        expect(
          hostStates[0].taps,
          1,
          reason:
              'Helper must tap the FIRST matching chip so the post-tap '
              'predicate observes a deterministic chip flip; tapping a later '
              'chip would tie ordering to render order on Linux CI.',
        );
        expect(
          hostStates[1].taps,
          0,
          reason:
              'Only the first matching chip must receive the tap; tapping '
              'multiple chips would leak side effects into adjacent panels.',
        );
      },
    );

    testWidgets(
      'returns without throwing when the chip never flips selected',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await _pumpScaffold(
          tester,
          CtChoiceChip(
            label: Text(l10n.region_oldWorld),
            selected: false,
            onSelected: (_) {},
          ),
        );

        Object? caught;
        try {
          await e2eTapOldWorldRegionTab(tester, l10n);
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNull,
          reason:
              'Helper composes the best-effort '
              'e2ePumpUntilConditionOrIdle and MUST NOT throw on timeout — '
              'callers treat the wait as an optional post-tap settle '
              '(#2336 AC5).',
        );
        expect(
          e2eOldWorldRegionChipAppearsSelected(l10n),
          isFalse,
          reason:
              'Sanity: stubbed onSelected keeps the chip unselected so the '
              'timeout branch is exercised end-to-end.',
        );
      },
    );
  });
}
