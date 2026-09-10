// Visual goldens for MAP20001 Political Grant Aid / Set Subsidy (Refs #4761).

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_grant_subsidy_shortcut_goldens_cases.dart';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  for (final c in provinceGrantSubsidyWideCases) {
    testWidgets('golden: ${c.name} (Refs #4761)', (WidgetTester tester) async {
      final boundaryKey = ValueKey<String>(
        'province_grant_subsidy_${c.name}_golden',
      );
      await pumpProvinceGrantSubsidyGolden(
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
      assertProvinceGrantSubsidyControl(tester, c, l10n);
      if (c.props.showGrantAid && !c.props.grantAidPending) {
        await tester.ensureVisible(
          find.widgetWithText(
            CtActionTextButton,
            l10n.provinceOverlay_grantAidAction,
          ),
        );
        await tester.pump();
      }
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(c.goldenFile),
      );
    });
  }

  testWidgets('golden: Grant Aid disabled wraps at 320 dp (Refs #4761)', (
    WidgetTester tester,
  ) async {
    final c = ProvinceGrantSubsidyGoldenCase(
      name: 'Grant Aid disabled 320',
      goldenFile: 'goldens/province_grant_subsidy_disabled_320.png',
      props: grantSubsidyGoldenProps(
        grantEnabled: false,
        grantReason: provinceGrantSubsidyGoldenTreasuryReason,
      ),
    );
    const boundaryKey = ValueKey<String>('province_grant_subsidy_320_golden');
    await pumpProvinceGrantSubsidyGolden(
      tester,
      boundaryKey: boundaryKey,
      surface: const Size(400, 640),
      overlaySize: const Size(320, 640),
      c: c,
    );
    expect(tester.takeException(), isNull);
    assertProvinceGrantSubsidyControl(tester, c, l10n);
    expect(find.text(provinceGrantSubsidyGoldenTreasuryReason), findsOneWidget);
    await expectLater(find.byKey(boundaryKey), matchesGoldenFile(c.goldenFile));
  });

  for (final c in [
    provinceGrantSubsidyWideCases[0],
    provinceGrantSubsidyWideCases[2],
    provinceGrantSubsidyWideCases[3],
  ]) {
    testWidgets('320 dp ${c.name} does not overflow (Refs #4761)', (
      WidgetTester tester,
    ) async {
      final boundaryKey = ValueKey<String>(
        'province_grant_subsidy_320_${c.name}',
      );
      await pumpProvinceGrantSubsidyGolden(
        tester,
        boundaryKey: boundaryKey,
        surface: const Size(400, 640),
        overlaySize: const Size(320, 640),
        c: c,
      );
      expect(tester.takeException(), isNull);
      assertProvinceGrantSubsidyControl(tester, c, l10n);
    });
  }
}
