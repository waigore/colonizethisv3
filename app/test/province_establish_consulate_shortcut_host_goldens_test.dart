// Visual goldens for MAP20001 Political Establish Consulate variants (Refs #4346).

import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_establish_consulate_shortcut_goldens_cases.dart';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  for (final c in provinceConsulateWideCases) {
    testWidgets('golden: ${c.name} (Refs #4346)', (WidgetTester tester) async {
      final boundaryKey = ValueKey<String>(
        'province_consulate_${c.name}_golden',
      );
      await pumpProvinceConsulateGolden(
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
      assertProvinceConsulateControl(tester, c, l10n);
      if (c.showControl) {
        final controlFinder = c.pending
            ? find.widgetWithText(
                CtActionTextButton,
                l10n.provinceOverlay_cancelEstablishConsulateAction,
              )
            : find.widgetWithText(
                CtActionTextButton,
                l10n.provinceOverlay_establishConsulateAction,
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
    'golden: Establish Consulate disabled wraps at 320 dp (Refs #4346)',
    (WidgetTester tester) async {
      const c = ProvinceConsulateGoldenCase(
        name: 'Establish Consulate disabled 320',
        goldenFile: 'goldens/province_establish_consulate_disabled_320.png',
        showControl: true,
        enabled: false,
        pending: false,
        rejectionReason: provinceConsulateGoldenExpertiseReason,
      );
      const boundaryKey = ValueKey<String>('province_consulate_320_golden');
      await pumpProvinceConsulateGolden(
        tester,
        boundaryKey: boundaryKey,
        surface: const Size(400, 640),
        overlaySize: const Size(320, 640),
        c: c,
      );
      expect(tester.takeException(), isNull);
      assertProvinceConsulateControl(tester, c, l10n);
      expect(find.text(provinceConsulateGoldenExpertiseReason), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(c.goldenFile),
      );
    },
  );
}
