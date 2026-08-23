library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'naval_fleet_move_harness.dart';

void registerTapMoveOnFirstNonHomeFleetSeparatorGroup() {
  group('e2eTapMoveOnFirstNonHomeFleet — subtitle separators', () {
    testWidgets(
      'em-dash, en-dash and hyphen NW subtitles all qualify as preferred',
      (tester) async {
        for (final separator in const ['—', '–', '-']) {
          await tester.pumpWidget(
            wrapNavalScrollBody(
              navalPanelRoot(
                children: [
                  fleetMoveTile(
                    title: 'Fleet 9',
                    subtitle: 'New World $separator Outer Sea',
                  ),
                ],
              ),
            ),
          );
          expect(
            await e2eTapMoveOnFirstNonHomeFleet(tester),
            isTrue,
            reason:
                'Move on a non-home fleet should fire for separator '
                '"$separator" (e2eTextLooksLikeNewWorldLocationLine '
                'accepts em / en / hyphen variants).',
          );
          expect(find.byType(AlertDialog), findsOneWidget);
          // Dismiss before the next pumpWidget so showDialog routes do not
          // leak across the loop iterations.
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
