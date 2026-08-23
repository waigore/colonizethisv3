// Extracted from e2e_region_chip_selected_test.dart (#4598 Slice C).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'e2e_widget_pump_harness.dart';
import 'region_chip_host_harness.dart';

void registerE2eRegionChipSelectedGuardGroup() {
  group('e2eNewWorldRegionChipAppearsSelected', () {
    testWidgets('returns false when the keyed New World subtree is absent', (
      WidgetTester tester,
    ) async {
      // No KeyedSubtree(key: kCtE2ERegionTabNewWorldKey) → must short-circuit.
      await pumpE2eScaffold(
        tester,
        regionChipWithLabel(const Text('New World'), selected: true),
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
    });

    testWidgets(
      'returns false when the keyed subtree has no CtChoiceChip descendants',
      (WidgetTester tester) async {
        await pumpE2eScaffold(
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
        await pumpE2eScaffold(
          tester,
          KeyedSubtree(
            key: kCtE2ERegionTabNewWorldKey,
            child: Row(
              children: <Widget>[
                regionChipWithLabel(const Text('New World'), selected: true),
                regionChipWithLabel(const Text('New World'), selected: true),
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
        await pumpE2eScaffold(
          tester,
          KeyedSubtree(
            key: kCtE2ERegionTabNewWorldKey,
            child: regionChipWithLabel(
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
        await pumpE2eScaffold(
          tester,
          KeyedSubtree(
            key: kCtE2ERegionTabNewWorldKey,
            child: regionChipWithLabel(const Text('New World'), selected: true),
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
        await pumpE2eScaffold(
          tester,
          Column(
            children: <Widget>[
              regionChipWithLabel(const Text('New World'), selected: true),
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
