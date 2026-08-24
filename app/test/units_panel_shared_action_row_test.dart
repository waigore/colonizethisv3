import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_circular_locate_button.dart';
import 'package:colonizethis_app/widgets/ct_danger_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/location_section_header.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/region_section_header.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/region_labels.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_row_chrome.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';

import 'units_panel_shared_widgets_test_support.dart';

void main() {
  suppressLogsForTests();
  group('UnitsEntityActionRow', () {
    testWidgets('renders details with text action label on wide width', (
      WidgetTester tester,
    ) async {
      await pumpUnitsEntityActionRow(
        tester,
        actions: [unitsEntityMoveAction()],
      );

      expect(find.text('Left details'), findsOneWidget);
      expect(find.text('Move'), findsOneWidget);
      expect(find.byType(UnitsPanelRowChrome), findsOneWidget);
    });

    testWidgets('switches action button to icon-only on narrow width', (
      WidgetTester tester,
    ) async {
      await pumpUnitsEntityActionRow(
        tester,
        width: 220,
        actions: [unitsEntityMoveAction()],
      );

      expect(find.byIcon(Icons.route), findsOneWidget);
      expect(find.text('Move'), findsNothing);
    });

    testWidgets(
      'renders mockup compact-pill family per action variant (#3514): '
      'neutral -> CtActionTextButton, danger -> CtDangerTextButton, '
      'iconOnly -> CtCircularLocateButton, and no CtNinePatchButton',
      (WidgetTester tester) async {
        await pumpUnitsEntityActionRow(
          tester,
          actions: [
            unitsEntityMoveAction(),
            UnitsEntityAction(
              tooltip: 'Cancel',
              icon: Icons.cancel_outlined,
              label: 'Cancel',
              variant: UnitsEntityActionVariant.danger,
              onPressed: () {},
            ),
            UnitsEntityAction(
              tooltip: 'Locate',
              icon: Icons.my_location,
              label: 'Locate',
              iconOnly: true,
              onPressed: () {},
            ),
          ],
        );

        expect(find.byType(CtActionTextButton), findsOneWidget);
        expect(find.byType(CtDangerTextButton), findsOneWidget);
        expect(find.byType(CtCircularLocateButton), findsOneWidget);
        expect(find.byType(CtNinePatchButton), findsNothing);
        // The iconOnly Locate control renders no text label (circular pill).
        expect(find.text('Locate'), findsNothing);
      },
    );

    testWidgets(
      'disabled action (onPressed == null) renders a disabled pill (#3514)',
      (WidgetTester tester) async {
        await pumpUnitsEntityActionRow(
          tester,
          actions: [unitsEntityMoveAction(enabled: false)],
        );

        final pill = tester.widget<CtActionTextButton>(
          find.byType(CtActionTextButton),
        );
        expect(pill.onPressed, isNull);
      },
    );
  });
}
