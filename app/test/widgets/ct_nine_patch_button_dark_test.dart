// Widget tests for the dark editorial-monocle visual contract on
// `CtNinePatchButton` (`Refs #2859` S2 / R1). Verifies the AC set:
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_nine_patch_button_dark_test_support.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('default state paints buttonGradient and 1px --border border', (
    WidgetTester tester,
  ) async {
    await pumpNinePatchButton(tester, onPressed: () {});
    final BoxDecoration decoration = ninePatchButtonSurfaceDecoration(tester);
    final LinearGradient gradient = decoration.gradient! as LinearGradient;
    expect(gradient.begin, Alignment.topCenter);
    expect(gradient.end, Alignment.bottomCenter);
    expect(gradient.colors, <Color>[
      EditorialMonoclePalette.surfaceLite,
      EditorialMonoclePalette.surface,
    ]);
    expect(gradient.colors, CtGradients.buttonGradient.colors);
    final Border? border = decoration.border as Border?;
    expect(border, isNotNull);
    expect(border!.top.width, CtNinePatchButton.borderWidth);
    expect(border.top.color, EditorialMonoclePalette.border);
  });

  testWidgets('hover brightens corner brackets and shifts border to --accent', (
    WidgetTester tester,
  ) async {
    await pumpNinePatchButton(tester, onPressed: () {});
    final TestGesture gesture = await hoverOverNinePatchButton(tester);
    expectNinePatchBorderColor(tester, EditorialMonoclePalette.accent);
    await gesture.moveTo(const Offset(-50, -50));
    await tester.pumpAndSettle();
    expectNinePatchBorderColor(tester, EditorialMonoclePalette.border);
  });

  testWidgets(
    'engraved label text uses a 1px downward shadow coloured from --surface',
    (WidgetTester tester) async {
      await pumpNinePatchButton(tester, onPressed: () {});
      expect(find.text('Confirm'), findsOneWidget);
      final List<Shadow>? shadows = ninePatchButtonLabelSpan(
        tester,
        'Confirm',
      ).style?.shadows;
      expect(shadows, isNotNull);
      expect(shadows!.length, 1);
      expect(shadows.first.offset, CtNinePatchButton.engravedShadowOffset);
      expect(shadows.first.blurRadius, 0);
      expect(shadows.first.color, EditorialMonoclePalette.surface);
    },
  );

}
