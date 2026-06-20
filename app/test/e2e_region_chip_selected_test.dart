/// Pins the multi-branch behavior of the **region-chip selection** helpers
/// `e2eOldWorldRegionChipAppearsSelected` and
/// `e2eNewWorldRegionChipAppearsSelected` in
/// `app/integration_test/e2e_test_shared.dart`
/// (Refs GitHub #2336 / `SPEC/program/e2e-integration-tests.md`
/// § Adaptive poll pacing).
///
/// Both helpers are used as **`condition` predicates** by
/// [e2ePumpUntilConditionOrIdle] in the fleet E2E hot path:
///
/// - `app/integration_test/new_game_fleet_reaches_new_world_e2e_helpers.dart`
///   `_tapNewWorldRegionTabIfPresent` (`_tryNavalMoveSegment` H1–H4 path) —
///   short-circuits the post-tap region-tab settle as soon as the New World
///   chip flips to selected.
/// - `app/integration_test/new_game_fleet_reaches_new_world_e2e_helpers.dart`
///   `_tapOldWorldRegionTab` — same pattern for the Old World region tab on
///   the OW-split fleet move path.
///
/// Both call sites run inside the bounded
/// `_kMaxNextTurnTapsForNwFleetReach = 35` turn loop, so a regression that
/// causes either helper to return `true` spuriously (or fail to return
/// `true` when the chip is selected) regresses the wall-clock-bound
/// fleet test suite that #2336 is shrinking — the polling timeout is
/// burned every iteration on top of the 200–500 ms post-tap pump budget.
///
/// The existing `e2e_test_shared_smoke_test.dart` pins only the happy
/// path (matching label + `selected: true`) for both helpers. The
/// **false-return** branches — missing chips, mismatched label text,
/// non-`Text` labels, unselected chips, multi-chip keyed subtree, and
/// missing keyed-subtree — have no dedicated coverage today. A silent
/// regression in any of them (e.g. removing the `lw is Text` guard, or
/// changing the `.length != 1` check to `>= 1`) would only surface as a
/// fleet-loop slowdown or an `_tryNavalMoveSegment` flake on Linux CI.
///
/// `integration_test/` runs behind a no-op `app_e2e_linux` lane today
/// (`SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer is the only per-PR enforcement gate for the region-chip
/// predicate contract.
library;

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

CtChoiceChip _chipWithLabel(
  Widget label, {
  required bool selected,
  Key? key,
}) {
  return CtChoiceChip(
    key: key,
    label: label,
    selected: selected,
    onSelected: (_) {},
  );
}

Future<void> _pumpScaffold(WidgetTester tester, Widget body) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: body),
    ),
  );
}

void main() {
  suppressLogsForTests();

  group('e2eOldWorldRegionChipAppearsSelected', () {
    testWidgets(
      'returns false on an empty scaffold (no CtChoiceChip widgets)',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await _pumpScaffold(tester, const SizedBox());
        expect(
          e2eOldWorldRegionChipAppearsSelected(l10n),
          isFalse,
          reason:
              'Absent CtChoiceChip widgets must surface as `false` so '
              '_tapOldWorldRegionTab does not short-circuit the post-tap '
              'settle before the chip is even mounted (#2336 fleet H1–H4).',
        );
      },
    );

    testWidgets(
      'returns false when chips exist but none carry the Old World label',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await _pumpScaffold(
          tester,
          Column(
            children: <Widget>[
              _chipWithLabel(
                Text(l10n.region_newWorld),
                selected: true,
              ),
              _chipWithLabel(
                const Text('Some Other Region'),
                selected: true,
              ),
            ],
          ),
        );
        expect(
          e2eOldWorldRegionChipAppearsSelected(l10n),
          isFalse,
          reason:
              'A scaffold with a *selected* New World chip but no Old '
              'World chip must not satisfy the OW predicate — otherwise '
              '_tapOldWorldRegionTab would return immediately on the New '
              'World tab and the OW-split fleet move would fire from the '
              'wrong region.',
        );
      },
    );

    testWidgets(
      'returns false when matching chip exists but is not selected',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await _pumpScaffold(
          tester,
          _chipWithLabel(
            Text(l10n.region_oldWorld),
            selected: false,
          ),
        );
        expect(
          e2eOldWorldRegionChipAppearsSelected(l10n),
          isFalse,
          reason:
              'Helper must surface the chip selection state, not just '
              'chip presence — otherwise the adaptive post-tap settle '
              'would exit before the tab finishes flipping to selected.',
        );
      },
    );

    testWidgets(
      'returns false when matching chip uses a non-Text label widget',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        // The helper guards on `lw is Text`; an Icon label (or any non-Text
        // widget) must not be treated as a label match even when selected.
        await _pumpScaffold(
          tester,
          _chipWithLabel(
            const Icon(Icons.public),
            selected: true,
          ),
        );
        expect(
          e2eOldWorldRegionChipAppearsSelected(l10n),
          isFalse,
          reason:
              'Helper must keep the `lw is Text` guard so future UI changes '
              'that swap chip labels for icons/decorations do not silently '
              'satisfy the OW predicate on the wrong tab.',
        );
      },
    );

    testWidgets(
      'returns true when the matching Old World chip is selected',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await _pumpScaffold(
          tester,
          Row(
            children: <Widget>[
              _chipWithLabel(
                Text(l10n.region_oldWorld),
                selected: true,
              ),
              _chipWithLabel(
                Text(l10n.region_newWorld),
                selected: false,
              ),
            ],
          ),
        );
        expect(
          e2eOldWorldRegionChipAppearsSelected(l10n),
          isTrue,
          reason:
              'Happy-path positive: a selected OW chip alongside an '
              'unselected NW chip must satisfy the predicate so the '
              'adaptive post-tap settle short-circuits.',
        );
      },
    );

    testWidgets(
      'returns the first matching chip\'s selected state when multiple OW labels are present',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        // The helper iterates `find.byType(CtChoiceChip)` and returns on the
        // first label match — pin that order-sensitive behavior so future
        // changes (e.g., switching to `lastWhere`) are caught.
        await _pumpScaffold(
          tester,
          Row(
            children: <Widget>[
              _chipWithLabel(
                Text(l10n.region_oldWorld),
                selected: false,
              ),
              _chipWithLabel(
                Text(l10n.region_oldWorld),
                selected: true,
              ),
            ],
          ),
        );
        expect(
          e2eOldWorldRegionChipAppearsSelected(l10n),
          isFalse,
          reason:
              'Helper must reflect the *first* matching chip\'s selected '
              'state. A later-iteration match that flips the result would '
              'tie predicate truth to render order — non-deterministic on '
              'Linux CI where panel mounts may interleave.',
        );
      },
    );
  });

  group('e2eNewWorldRegionChipAppearsSelected', () {
    testWidgets(
      'returns false when the keyed New World subtree is absent',
      (WidgetTester tester) async {
        // No KeyedSubtree(key: kCtE2ERegionTabNewWorldKey) → must short-circuit.
        await _pumpScaffold(
          tester,
          _chipWithLabel(
            const Text('New World'),
            selected: true,
          ),
        );
        expect(
          e2eNewWorldRegionChipAppearsSelected(),
          isFalse,
          reason:
              'A selected chip outside the keyed subtree must NOT satisfy '
              'the predicate — the helper must scope its match to the '
              'kCtE2ERegionTabNewWorldKey subtree so the bottom-sheet '
              'New-World chip rendered in another panel does not race '
              'the region-tab settle.',
        );
      },
    );

    testWidgets(
      'returns false when the keyed subtree has no CtChoiceChip descendants',
      (WidgetTester tester) async {
        await _pumpScaffold(
          tester,
          const KeyedSubtree(
            key: kCtE2ERegionTabNewWorldKey,
            child: SizedBox.shrink(),
          ),
        );
        expect(
          e2eNewWorldRegionChipAppearsSelected(),
          isFalse,
          reason:
              'Keyed root with no chip child must return false; otherwise '
              'the adaptive post-tap settle could exit while the chip is '
              'still mounting on slow Linux CI.',
        );
      },
    );

    testWidgets(
      'returns false when the keyed subtree has more than one CtChoiceChip',
      (WidgetTester tester) async {
        // The helper requires exactly one chip in the subtree so duplicate
        // / mid-rebuild chips do not accidentally satisfy the predicate.
        await _pumpScaffold(
          tester,
          KeyedSubtree(
            key: kCtE2ERegionTabNewWorldKey,
            child: Row(
              children: <Widget>[
                _chipWithLabel(
                  const Text('New World'),
                  selected: true,
                ),
                _chipWithLabel(
                  const Text('New World'),
                  selected: true,
                ),
              ],
            ),
          ),
        );
        expect(
          e2eNewWorldRegionChipAppearsSelected(),
          isFalse,
          reason:
              'Helper must keep the `length != 1` guard so a duplicate '
              'chip render during a rebuild does not satisfy the '
              'predicate prematurely (a fleet-loop region tab rebuild '
              'briefly hosts two chip instances).',
        );
      },
    );

    testWidgets(
      'returns false when the keyed subtree has exactly one unselected chip',
      (WidgetTester tester) async {
        await _pumpScaffold(
          tester,
          KeyedSubtree(
            key: kCtE2ERegionTabNewWorldKey,
            child: _chipWithLabel(
              const Text('New World'),
              selected: false,
            ),
          ),
        );
        expect(
          e2eNewWorldRegionChipAppearsSelected(),
          isFalse,
          reason:
              'Helper must reflect chip selection, not chip presence; '
              'otherwise _tapNewWorldRegionTabIfPresent would exit while '
              'the tab is still flipping to selected.',
        );
      },
    );

    testWidgets(
      'returns true when the keyed subtree has exactly one selected chip',
      (WidgetTester tester) async {
        // Happy path with explicit keyed-subtree scoping to mirror the
        // map controls' kCtE2ERegionTabNewWorldKey rendering.
        await _pumpScaffold(
          tester,
          KeyedSubtree(
            key: kCtE2ERegionTabNewWorldKey,
            child: _chipWithLabel(
              const Text('New World'),
              selected: true,
            ),
          ),
        );
        expect(
          e2eNewWorldRegionChipAppearsSelected(),
          isTrue,
          reason:
              'Single selected chip inside the keyed subtree must satisfy '
              'the predicate so the adaptive post-tap settle '
              'short-circuits as soon as the tab flip lands.',
        );
      },
    );

    testWidgets(
      'returns false when an unrelated selected chip lives outside the keyed subtree',
      (WidgetTester tester) async {
        // Mixed-render case: bottom-sheet chip selected outside the
        // map-controls keyed root must not be confused with a map-tab flip.
        await _pumpScaffold(
          tester,
          Column(
            children: <Widget>[
              _chipWithLabel(
                const Text('New World'),
                selected: true,
              ),
              const KeyedSubtree(
                key: kCtE2ERegionTabNewWorldKey,
                child: SizedBox.shrink(),
              ),
            ],
          ),
        );
        expect(
          e2eNewWorldRegionChipAppearsSelected(),
          isFalse,
          reason:
              'Helper must scope the chip lookup to the keyed subtree so '
              'a selected chip in another panel does not satisfy the '
              'region-tab predicate.',
        );
      },
    );
  });
}
