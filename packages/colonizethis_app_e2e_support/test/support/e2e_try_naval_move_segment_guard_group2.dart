// Extracted from e2e_try_naval_move_segment_test.dart (#4598 Slice C).
library;

// ignore_for_file: deprecated_member_use
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'naval_fleet_move_harness.dart';

void registerE2eTryNavalMoveSegmentGuardGroup2() {
  group('e2eTryNavalMoveSegment — perf markers', () {
    testWidgets('records no_non_home_move_control when Move not tapped', (
      tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final perf = E2ePerfLog('no_non_home_move');
      await tester.pumpWidget(
        wrapNavalScrollBody(
          navalPanelRoot(children: const [Text('loading fleets')]),
        ),
      );
      final lines = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        lines.add(message ?? '');
      };
      try {
        await e2eTryNavalMoveSegment(
          tester,
          l10n,
          navalPanelAlreadyOpen: true,
          perf: perf,
        );
      } finally {
        debugPrint = original;
      }
      expect(
        lines.any(
          (line) =>
              line.contains('fleet_move_segment') &&
              line.contains('no_non_home_move_control'),
        ),
        isTrue,
      );
    });

    testWidgets('records no_legal_step when adjacent-sea message shown', (
      tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final perf = E2ePerfLog('no_legal_step');
      await tester.pumpWidget(
        wrapNavalScrollBody(
          navalPanelRoot(
            children: [
              fleetMoveTile(
                title: 'Fleet 2',
                subtitle: 'New World — Outer Sea',
                dialogBuilder: (context) => AlertDialog(
                  content: Text(l10n.moveFleet_noAdjacentSeaZones),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.common_cancel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      final lines = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        lines.add(message ?? '');
      };
      try {
        await e2eTryNavalMoveSegment(
          tester,
          l10n,
          navalPanelAlreadyOpen: true,
          perf: perf,
        );
      } finally {
        debugPrint = original;
      }
      expect(
        lines.any(
          (line) =>
              line.contains('fleet_move_segment') &&
              line.contains('no_legal_step'),
        ),
        isTrue,
      );
    });
  });
}
