// Pins the multi-row title-fallback contract of
// `e2eTapAssignOnCivilianRowWithTitle` (Refs GitHub #2336 Bottleneck 2 / H9 —
// `_tapAssignOnCivilianRowWithTitle` is one of the highest-impact pump sites
// in the E2E suite).
//
// The helper is non-trivial: when multiple civilian rows share the same unit
// title (`Builder`, `Merchant`, etc.), the panel may already have one of
// them assigned to a work order (no `Assign` button) while another idle
// row is still actionable. The helper must skip rows whose `ListTile`
// subtree no longer contains a tappable `Assign` and pick the first row
// that does — otherwise scenarios that exercise multi-unit panels would
// fail mid-test when the first match is already busy.
//
// The sibling helper `e2eTapFirstAssignInCivilianPanel` shares the
// downstream "wait until work menu" contract; pinning both helpers in one
// file keeps the civilian-row tap contract together (existing pins for the
// surrounding bottom-sheet / dismiss helpers live in
// `app/test/e2e_close_bottom_sheet_test.dart` and
// `app/test/e2e_dismiss_transient_ui_test.dart`).
//
// `integration_test/` is not part of the PR `quality` workflow
// (`SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
// layer is the only per-PR pin for these civilian-row helpers.
//
// Coverage layers:
//   - Single matching row: helper taps the row's `Assign`, work menu
//     surfaces.
//   - Multi-row title fallback: when the first row with the matching
//     title has no `Assign` (already assigned), the helper falls through
//     to the next row that still exposes one.
//   - No-Assign fail-fast: when every matching row lacks an `Assign`
//     descendant, the helper fails with a descriptive message rather
//     than hanging.
//   - First-Assign sibling: `e2eTapFirstAssignInCivilianPanel` taps the
//     lexically first `Assign` regardless of row title.
library;

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show kUnitTypeBuilder, kUnitTypeMerchant;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// One row spec for the synthetic civilian panel host (title + whether the
/// row exposes an `Assign` button).
class _RowSpec {
  const _RowSpec({required this.title, required this.hasAssign});

  final String title;
  final bool hasAssign;
}

class _CivilianPanelHost extends StatefulWidget {
  const _CivilianPanelHost({required this.rows});

  final List<_RowSpec> rows;

  @override
  State<_CivilianPanelHost> createState() => _CivilianPanelHostState();
}

class _CivilianPanelHostState extends State<_CivilianPanelHost> {
  /// Index of the row whose `Assign` was tapped. `-1` means no tap yet.
  int _tappedRowIndex = -1;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          key: kCtE2ECivilianPanelRootKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    for (var i = 0; i < widget.rows.length; i++)
                      ListTile(
                        title: Text(widget.rows[i].title),
                        trailing: widget.rows[i].hasAssign
                            ? TextButton(
                                onPressed: () {
                                  setState(() {
                                    _tappedRowIndex = i;
                                  });
                                },
                                child: const Text('Assign'),
                              )
                            : const Text('Busy'),
                      ),
                  ],
                ),
              ),
              if (_tappedRowIndex >= 0)
                // The helper polls for any of {Build improvement, Prospect,
                // Explore} after tapping Assign. Showing one of those labels
                // here is the synthetic equivalent of the work-menu surfacing
                // in the production scaffold.
                const Text('Build improvement'),
            ],
          ),
        ),
      ),
    );
  }
}

int _tappedRowIndexOf(WidgetTester tester) {
  final stateFinder = find.byType(_CivilianPanelHost);
  if (stateFinder.evaluate().isEmpty) {
    return -1;
  }
  final state = tester.state<_CivilianPanelHostState>(stateFinder);
  return state._tappedRowIndex;
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'e2eTapAssignOnCivilianRowWithTitle taps Assign on the single matching row',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const _CivilianPanelHost(
          rows: [
            _RowSpec(title: kUnitTypeBuilder, hasAssign: true),
            _RowSpec(title: kUnitTypeMerchant, hasAssign: true),
          ],
        ),
      );

      await e2eTapAssignOnCivilianRowWithTitle(tester, kUnitTypeBuilder);

      expect(
        _tappedRowIndexOf(tester),
        0,
        reason:
            'Single Builder row must have its Assign tapped (not the '
            'Merchant row at index 1).',
      );
    },
  );

  testWidgets(
    'e2eTapAssignOnCivilianRowWithTitle skips matching rows without Assign and taps the first idle row',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const _CivilianPanelHost(
          rows: [
            // First Builder is already assigned (no Assign button).
            _RowSpec(title: kUnitTypeBuilder, hasAssign: false),
            // Second Builder is still idle and must be picked.
            _RowSpec(title: kUnitTypeBuilder, hasAssign: true),
            // Trailing rows guard against helpers that accidentally tap an
            // off-title row when the matching rows look exhausted.
            _RowSpec(title: kUnitTypeMerchant, hasAssign: true),
          ],
        ),
      );

      await e2eTapAssignOnCivilianRowWithTitle(tester, kUnitTypeBuilder);

      expect(
        _tappedRowIndexOf(tester),
        1,
        reason:
            'Helper must skip the first Builder row (no Assign descendant) '
            'and tap the second Builder row, not fall through to the '
            'Merchant row at index 2 (#2336 H9 multi-row contract).',
      );
    },
  );

  testWidgets(
    'e2eTapAssignOnCivilianRowWithTitle fails when no matching row exposes Assign',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const _CivilianPanelHost(
          rows: [
            _RowSpec(title: kUnitTypeBuilder, hasAssign: false),
            _RowSpec(title: kUnitTypeBuilder, hasAssign: false),
            // Off-title row with Assign present to verify the helper does
            // not lower its title filter when matching rows look exhausted.
            _RowSpec(title: kUnitTypeMerchant, hasAssign: true),
          ],
        ),
      );

      Object? caught;
      try {
        await e2eTapAssignOnCivilianRowWithTitle(tester, kUnitTypeBuilder);
      } catch (e) {
        caught = e;
      }

      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'When no row with the requested title exposes Assign, the '
            'helper must surface a TestFailure rather than tap the wrong '
            'unit type or hang (#2336 H9 fail-fast contract).',
      );
      expect(
        _tappedRowIndexOf(tester),
        -1,
        reason:
            'Off-title Merchant row at index 2 must not be tapped when the '
            'caller requested a Builder.',
      );
    },
  );

  testWidgets(
    'e2eTapFirstAssignInCivilianPanel taps the first Assign regardless of row title',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const _CivilianPanelHost(
          rows: [
            // First row deliberately uses a non-Builder title to confirm
            // the helper picks Assign by position, not by title match.
            _RowSpec(title: kUnitTypeMerchant, hasAssign: true),
            _RowSpec(title: kUnitTypeBuilder, hasAssign: true),
          ],
        ),
      );

      await e2eTapFirstAssignInCivilianPanel(tester);

      expect(
        _tappedRowIndexOf(tester),
        0,
        reason:
            'First-Assign sibling must tap the Merchant row at index 0 '
            '(first Assign in list order) rather than the Builder row at '
            'index 1.',
      );
    },
  );
}
