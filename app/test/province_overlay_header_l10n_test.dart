// Pins that the ProvinceSeaZoneDetailOverlay header title is sourced from
// AppLocalizations (no hardcoded English literal), per the project
// localization rule and SPEC § Dark-theme chrome (header title shows the
// localized `Province` / `Sea zone` label above the tab strip).
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleSeaZoneIdForOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';

Widget _overlay({required String displayId}) {
  final game = demoGameForOverlay;
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: const [Locale('en')],
    home: Scaffold(
      body: ProvinceSeaZoneDetailOverlay(
        game: game,
        region: demoRegionForOverlay,
        displayId: displayId,
        selectedTileKey: null,
        humanPlayerId: game.players.first.id,
        playerView: demoHumanPlayerViewForOverlay,
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

  group('ProvinceSeaZoneDetailOverlay header title localization', () {
    testWidgets('province header renders the localized province title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_overlay(displayId: sampleProvinceIdForOverlay));
      await tester.pumpAndSettle();

      expect(find.text(l10n.provinceOverlay_titleProvince), findsOneWidget);
    });

    testWidgets('sea-zone header renders the localized sea-zone title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_overlay(displayId: sampleSeaZoneIdForOverlay));
      await tester.pumpAndSettle();

      expect(find.text(l10n.provinceOverlay_titleSeaZone), findsOneWidget);
    });

    test('header title l10n keys expose the SPEC-defined labels', () {
      expect(l10n.provinceOverlay_titleProvince, 'Province');
      expect(l10n.provinceOverlay_titleSeaZone, 'Sea zone');
    });
  });
}
