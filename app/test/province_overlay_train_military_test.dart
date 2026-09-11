// Widget pins for MAP20001 Military Train on the human capital (Refs #4769).

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  Widget wrap(Widget child) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      home: Scaffold(body: child),
    );
  }

  ProvinceSeaZoneDetailOverlay overlay({
    required bool show,
    VoidCallback? onTap,
  }) {
    final game = demoGameForOverlay;
    return ProvinceSeaZoneDetailOverlay(
      game: game,
      region: demoRegionForOverlay,
      displayId: sampleProvinceIdForOverlay,
      selectedTileKey: sampleTileKeyForProvinceOverlay,
      humanPlayerId: game.players.first.id,
      playerView: demoHumanPlayerViewForOverlay,
      omniscientDetail: true,
      showTrainMilitaryControl: show,
      onTrainMilitaryTap: onTap,
      onClose: () {},
    );
  }

  testWidgets('enabled Train is visible with Home Army gist', (tester) async {
    var taps = 0;
    await tester.pumpWidget(wrap(overlay(show: true, onTap: () => taps++)));
    await tester.pumpAndSettle();
    final finder = find.byKey(kProvinceOverlayTrainMilitaryKey);
    expect(finder, findsOneWidget);
    expect(tester.widget<CtActionTextButton>(finder).enabled, isTrue);
    expect(
      tester.widget<CtActionTextButton>(finder).label,
      l10n.provinceOverlay_trainMilitaryAction,
    );
    expect(find.text(l10n.provinceOverlay_trainMilitaryGist), findsOneWidget);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
    expect(taps, 1);
    expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
  });

  testWidgets('hidden Train is absent', (tester) async {
    await tester.pumpWidget(wrap(overlay(show: false)));
    await tester.pumpAndSettle();
    expect(find.byKey(kProvinceOverlayTrainMilitaryKey), findsNothing);
    expect(find.text(l10n.provinceOverlay_trainMilitaryGist), findsNothing);
  });
}
