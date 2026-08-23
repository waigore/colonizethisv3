// Labour Controls subsection placement (Refs #2862 S7a, #4606 Slice D).
// SPEC/ui/production-panel.md § Labour Controls.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_panel_labour_support.dart';
import 'production_panel_test_support.dart';
import 'production_panel_widget_helpers.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  late Player fullPlayer;

  setUpAll(() {
    fullPlayer = productionPanelTestFullPlayer();
  });

  group('ProductionPanel Labour Controls (Refs #2862 S7a)', () {
    testWidgets(
      'Labour Controls CtSectionLabel appears below Effective Labour (Refs #2862 S7a)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildProductionPanelWithLabourCallbacks(player: fullPlayer),
        );
        await pumpSettleCapped(tester);

        final labourControlsLabel = find.descendant(
          of: find.byType(CtSectionLabel),
          matching: find.text('LABOUR CONTROLS'),
        );
        expect(labourControlsLabel, findsOneWidget);

        final effectiveLabour = find.textContaining('Labour this turn:');
        expect(effectiveLabour, findsOneWidget);

        final effectiveY = tester.getTopLeft(effectiveLabour).dy;
        final labourY = tester.getTopLeft(labourControlsLabel).dy;
        expect(
          labourY,
          greaterThan(effectiveY),
          reason:
              'Labour Controls section label must render below the '
              'Effective Labour line per SPEC § Labour Controls (12-A).',
        );
      },
    );

    testWidgets(
      'Labour Controls subsection is omitted when callbacks are not provided '
      '(no orphan section label; Refs #2862 S7a)',
      (WidgetTester tester) async {
        await pumpProductionPanelSettled(tester, player: fullPlayer);

        expect(
          find.descendant(
            of: find.byType(CtSectionLabel),
            matching: find.text('LABOUR CONTROLS'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Workers section uses Effective Labour line then Labour Controls label '
      '(no action buttons above Effective Labour; Refs #2862 S7a)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildProductionPanelWithLabourCallbacks(player: fullPlayer),
        );
        await pumpSettleCapped(tester);

        final effectiveLabour = find.textContaining('Labour this turn:');
        final l10n = lookupAppLocalizations(const Locale('en'));
        final apprenticeDisband = find.byKey(
          const ValueKey<String>('production_labour_disband_apprentices'),
        );
        if (apprenticeDisband.evaluate().isNotEmpty) {
          final effectiveY = tester.getTopLeft(effectiveLabour).dy;
          final disbandY = tester.getTopLeft(apprenticeDisband).dy;
          expect(
            disbandY,
            greaterThan(effectiveY),
            reason: 'Disband control must render below Effective Labour.',
          );
        }
        expect(find.text(l10n.production_workers_peasants), findsWidgets);
      },
    );
  });
}
