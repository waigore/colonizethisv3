/// Pins the dialog-scoped `RadioListTile<…>` lookup contract of
/// [e2eRadioListTilesInAlertDialogs] (`app/integration_test/e2e_test_shared.dart`).
///
/// The fleet-reach move helper (`e2ePickMoveDestinationAndConfirm` in
/// `e2e_test_shared_panels.dart`) taps
/// `e2eRadioListTilesInAlertDialogs().first` to pick the destination sea
/// radio when no warp row is present. Two regressions would silently
/// re-introduce flakes / stalls if the helper drifted:
///
///   1. **Dropping the `find.byType(AlertDialog)` scope** would match
///      `RadioListTile`s outside the dialog — the unit/civilian/production
///      panel trees host their own radios for filters and settings, so an
///      unscoped finder can return a tile that lives in a side panel and
///      never advance the move dialog. The fleet-reach loop would stall
///      until the 35-tap cap (`_kMaxNextTurnTapsForNwFleetReach`) instead
///      of completing at the first qualifying sea radio.
///   2. **Binding the matcher to a concrete `RadioListTile<String>`**
///      would silently miss every future move dialog parameterised on a
///      different type (a destination enum, a province id record, etc.).
///      The current `runtimeType.toString().startsWith('RadioListTile<')`
///      contract matches **every** generic instantiation, which keeps the
///      helper resilient to type-argument changes in
///      `naval_tree_builder.dart` / move-fleet dialog widgets.
///
/// The integration suite cannot validate this directly (the
/// `app_e2e_linux` lane is a no-op per `SPEC/program/e2e-integration-tests.md`
/// § CI), so the widget-test layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2.
library;

// The production move-fleet dialog (`move_fleet_dialog.dart`) constructs
// `RadioListTile<_MovePick>` with the legacy `groupValue` / `onChanged`
// API; the AC1 helper matches on `runtimeType.toString()`, so the test
// fixtures must build the same widget shape (not the newer RadioGroup-
// based API) for the pin to validate the production code path.
// ignore_for_file: deprecated_member_use

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  required List<Widget> dialogChildren,
  List<Widget> outsideDialog = const <Widget>[],
}) async {
  await tester.pumpWidget(
    _wrap(
      Column(
        children: [
          ...outsideDialog,
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) =>
                        AlertDialog(content: Column(children: dialogChildren)),
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ],
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(
    find.byType(AlertDialog),
    findsOneWidget,
    reason:
        'Test harness sanity: the AlertDialog must be mounted before '
        'asserting against the dialog-scoped finder.',
  );
}

void main() {
  suppressLogsForTests();

  group('e2eRadioListTilesInAlertDialogs — false / empty branches', () {
    testWidgets('no AlertDialog mounted -> findsNothing', (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(
        e2eRadioListTilesInAlertDialogs(),
        findsNothing,
        reason:
            'Without an AlertDialog in the tree the descendant lookup must '
            'short-circuit to zero matches. A regression that dropped the '
            '`of: find.byType(AlertDialog)` scope would match nothing here '
            'too (no radios at all), so this test must be paired with the '
            '"radio outside dialog ignored" branch below to catch the '
            'scope-drop regression on its own.',
      );
    });

    testWidgets('AlertDialog with no RadioListTile -> findsNothing', (
      tester,
    ) async {
      await _pumpDialog(
        tester,
        dialogChildren: const [Text('Pick a destination')],
      );
      expect(
        e2eRadioListTilesInAlertDialogs(),
        findsNothing,
        reason:
            'AlertDialog content that holds only Text (the move dialog '
            'fall-back when no legal sea step exists) must keep the helper '
            'empty. A wrapper that matched any descendant — or that '
            'misread the AlertDialog body as a RadioListTile parent — '
            'would surface false positives here.',
      );
    });

    testWidgets('RadioListTile outside any AlertDialog -> findsNothing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          RadioListTile<String>(
            title: const Text('panel-side'),
            value: 'a',
            groupValue: 'b',
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        e2eRadioListTilesInAlertDialogs(),
        findsNothing,
        reason:
            'A panel-side RadioListTile (settings sheet, civilian panel '
            'filter, etc.) must NOT leak into the dialog-scoped lookup. '
            'Dropping the `find.byType(AlertDialog)` scope would match '
            'this tile and let the fleet-reach move helper tap the wrong '
            'control, stalling the loop at the 35-tap cap.',
      );
    });

    testWidgets(
      'AlertDialog without RadioListTile + RadioListTile outside dialog -> findsNothing',
      (tester) async {
        await _pumpDialog(
          tester,
          dialogChildren: const [Text('Confirm warp?')],
          outsideDialog: [
            RadioListTile<int>(
              title: const Text('outside'),
              value: 1,
              groupValue: 2,
              onChanged: (_) {},
            ),
          ],
        );
        expect(
          e2eRadioListTilesInAlertDialogs(),
          findsNothing,
          reason:
              'Composite of the previous two branches: even with a '
              'mounted AlertDialog the lookup must remain empty when the '
              'only RadioListTile lives outside the dialog. A regression '
              'that swapped the descendant scope for an ancestor scope '
              '(or dropped it entirely) would match the panel-side tile.',
        );
      },
    );
  });

  group('e2eRadioListTilesInAlertDialogs — true branches', () {
    testWidgets('single RadioListTile<String> inside AlertDialog -> 1 match', (
      tester,
    ) async {
      await _pumpDialog(
        tester,
        dialogChildren: [
          RadioListTile<String>(
            title: const Text('sea1'),
            value: 'sea1',
            groupValue: '',
            onChanged: (_) {},
          ),
        ],
      );
      expect(
        e2eRadioListTilesInAlertDialogs(),
        findsOneWidget,
        reason:
            'The canonical fleet-reach move dialog parameterises '
            'destination tiles on `RadioListTile<String>` (the sea-zone '
            'id). A single radio must surface as exactly one match — the '
            'fleet helper calls `.first` on it, so any over-count would '
            'still pass but any under-count (matcher too strict) would '
            'fail this assertion.',
      );
    });

    testWidgets('multiple RadioListTile<String> inside AlertDialog -> N', (
      tester,
    ) async {
      await _pumpDialog(
        tester,
        dialogChildren: [
          for (final id in const ['sea1', 'sea2', 'sea3'])
            RadioListTile<String>(
              title: Text(id),
              value: id,
              groupValue: '',
              onChanged: (_) {},
            ),
        ],
      );
      expect(
        e2eRadioListTilesInAlertDialogs(),
        findsNWidgets(3),
        reason:
            'Move dialogs with multiple legal destinations must surface '
            'every radio (the helper later disambiguates via `.first`). '
            'A regression that short-circuited after the first match — '
            'or that filtered to a single index — would break multi-'
            'destination probing.',
      );
    });

    testWidgets(
      'RadioListTile with non-String type argument is still matched',
      (tester) async {
        await _pumpDialog(
          tester,
          dialogChildren: [
            RadioListTile<int>(
              title: const Text('int-typed'),
              value: 1,
              groupValue: 2,
              onChanged: (_) {},
            ),
          ],
        );
        expect(
          e2eRadioListTilesInAlertDialogs(),
          findsOneWidget,
          reason:
              'The contract uses `runtimeType.toString().startsWith('
              '`'
              'RadioListTile<'
              '`'
              ')` so any generic instantiation (`RadioListTile<int>`, '
              '`RadioListTile<MyEnum>`, etc.) is in scope. Hard-binding '
              'the matcher to `RadioListTile<String>` would silently miss '
              'future move dialogs that parameterise on a different '
              'destination type.',
        );
      },
    );

    testWidgets(
      'RadioListTiles inside AlertDialog co-exist with siblings outside',
      (tester) async {
        await _pumpDialog(
          tester,
          dialogChildren: [
            RadioListTile<String>(
              title: const Text('inside-1'),
              value: 'a',
              groupValue: 'b',
              onChanged: (_) {},
            ),
            RadioListTile<String>(
              title: const Text('inside-2'),
              value: 'b',
              groupValue: 'b',
              onChanged: (_) {},
            ),
          ],
          outsideDialog: [
            RadioListTile<String>(
              title: const Text('outside-1'),
              value: 'x',
              groupValue: 'y',
              onChanged: (_) {},
            ),
          ],
        );
        expect(
          e2eRadioListTilesInAlertDialogs(),
          findsNWidgets(2),
          reason:
              'The dialog-scoped lookup must count exactly the two '
              'in-dialog tiles, never the outside sibling. This is the '
              'canonical "panel + dialog co-mounted" regression guard for '
              'move-dialog tapping (Bottleneck 4 of #2336).',
        );
      },
    );
  });

  group('e2eRadioListTilesInAlertDialogs — regression guards', () {
    testWidgets('plain ListTile (no Radio prefix) is rejected', (tester) async {
      await _pumpDialog(
        tester,
        dialogChildren: const [ListTile(title: Text('plain-list-tile'))],
      );
      expect(
        e2eRadioListTilesInAlertDialogs(),
        findsNothing,
        reason:
            'A plain `ListTile` inside the dialog must NOT match the '
            'finder. The fleet-reach helper depends on tapping the '
            'RadioListTile (so the tile selection updates before '
            'Confirm); matching a plain ListTile would dispatch the tap '
            'to the wrong widget and silently miss the destination set.',
      );
    });

    testWidgets('CheckboxListTile inside the dialog is rejected', (
      tester,
    ) async {
      await _pumpDialog(
        tester,
        dialogChildren: [
          CheckboxListTile(
            title: const Text('checkbox-list-tile'),
            value: false,
            onChanged: (_) {},
          ),
        ],
      );
      expect(
        e2eRadioListTilesInAlertDialogs(),
        findsNothing,
        reason:
            'Even though `CheckboxListTile` shares the `ListTile` family, '
            'the `runtimeType.toString().startsWith("RadioListTile<")` '
            'prefix excludes it deterministically. A regression to a '
            'substring-style match (`contains("ListTile")`) would '
            'surface this checkbox and break the move-dialog tap path.',
      );
    });

    testWidgets('successive calls return fresh, idle Finder objects', (
      tester,
    ) async {
      await _pumpDialog(
        tester,
        dialogChildren: [
          RadioListTile<String>(
            title: const Text('only'),
            value: 'a',
            groupValue: '',
            onChanged: (_) {},
          ),
        ],
      );
      final first = e2eRadioListTilesInAlertDialogs();
      final second = e2eRadioListTilesInAlertDialogs();
      expect(
        identical(first, second),
        isFalse,
        reason:
            'The helper must construct a fresh Finder on each call (no '
            'caching). A shared/cached Finder would resolve against a '
            'stale Element tree across pump frames and silently report '
            'matches from a previous frame.',
      );
      expect(first.evaluate().length, 1);
      expect(second.evaluate().length, 1);
    });

    testWidgets('finder is lazy: constructible without a pumped tree', (
      tester,
    ) async {
      final finder = e2eRadioListTilesInAlertDialogs();
      expect(
        finder,
        isNotNull,
        reason:
            'The helper must not query the WidgetTester on construction; '
            'returning a lazy Finder keeps it safe to compose / store '
            'before pumping. A regression that resolved the Finder '
            'eagerly would throw outside an active tester binding.',
      );
      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(finder.evaluate(), isEmpty);
    });
  });
}
