// Visual goldens for MAP20001 Political Establish Embassy variants (Refs #4739).

import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_establish_embassy_shortcut_goldens_cases.dart';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  for (final c in provinceEmbassyWideCases) {
    testWidgets('golden: ${c.name} (Refs #4739)', (WidgetTester tester) async {
      final boundaryKey = ValueKey<String>('province_embassy_${c.name}_golden');
      await pumpProvinceEmbassyGolden(
        tester,
        boundaryKey: boundaryKey,
        surface: const Size(640, 720),
        overlaySize: const Size(460, 680),
        c: c,
      );
      expect(tester.takeException(), isNull);
      final politicalHeader = find.text(
        l10n.provinceOverlay_sectionPolitical.toUpperCase(),
      );
      expect(politicalHeader, findsOneWidget);
      await tester.ensureVisible(politicalHeader);
      await tester.pump();
      assertProvinceEmbassyControl(tester, c, l10n);
      if (c.showControl) {
        final controlFinder = c.pending
            ? find.widgetWithText(
                CtActionTextButton,
                l10n.provinceOverlay_cancelEstablishEmbassyAction,
              )
            : find.widgetWithText(
                CtActionTextButton,
                l10n.provinceOverlay_establishEmbassyAction,
              );
        await tester.ensureVisible(controlFinder);
        await tester.pump();
      }
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(c.goldenFile),
      );
    });
  }

  testWidgets(
    'golden: Establish Embassy disabled wraps at 320 dp (Refs #4739)',
    (WidgetTester tester) async {
      const c = ProvinceEmbassyGoldenCase(
        name: 'Establish Embassy disabled 320',
        goldenFile: 'goldens/province_establish_embassy_disabled_320.png',
        showControl: true,
        enabled: false,
        pending: false,
        rejectionReason: provinceEmbassyGoldenExpertiseReason,
      );
      const boundaryKey = ValueKey<String>('province_embassy_320_golden');
      await pumpProvinceEmbassyGolden(
        tester,
        boundaryKey: boundaryKey,
        surface: const Size(400, 640),
        overlaySize: const Size(320, 640),
        c: c,
      );
      expect(tester.takeException(), isNull);
      assertProvinceEmbassyControl(tester, c, l10n);
      expect(find.text(provinceEmbassyGoldenExpertiseReason), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(c.goldenFile),
      );
    },
  );
}
