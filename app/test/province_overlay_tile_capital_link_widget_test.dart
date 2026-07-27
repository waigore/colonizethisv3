// Widget pins for Tile capital-link and extraction rows (Refs #4149).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_tile_capital_link_preview.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;

import 'province_overlay_test_harness.dart';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  group('tile capital-link label helpers', () {
    test('connected without transport cap', () {
      const preview = ProvinceTileCapitalLinkPreview(
        isCapitalConnected: true,
        extractionFull: 0,
      );
      expect(tileCapitalLinkLine(l10n, preview), l10n.provinceOverlay_tileCapitalLinkConnected);
    });

    test('not connected', () {
      const preview = ProvinceTileCapitalLinkPreview(
        isCapitalConnected: false,
        extractionEffective: 0,
        extractionFull: 3,
      );
      expect(
        tileCapitalLinkLine(l10n, preview),
        l10n.provinceOverlay_tileCapitalLinkNotConnected,
      );
      expect(
        tileExtractionFromTileLine(l10n, preview),
        l10n.provinceOverlay_tileExtractionFromTile(0, 3),
      );
    });
  });

  group('Tile section capital-link rows (widget)', () {
    testWidgets('disconnected improved tile shows capital link and 0 of full', (
      tester,
    ) async {
      await pumpProvinceOverlayAtDarkTheme(
        tester,
        game: demoGameForOverlay,
        displayId: sampleProvinceIdForOverlay,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
        tileCapitalLinkPreview: const ProvinceTileCapitalLinkPreview(
          isCapitalConnected: false,
          extractionEffective: 0,
          extractionFull: 2,
        ),
      );
      expect(
        find.text(l10n.provinceOverlay_tileCapitalLinkNotConnected),
        findsOneWidget,
      );
      expect(
        find.text(l10n.provinceOverlay_tileExtractionFromTile(0, 2)),
        findsOneWidget,
      );
    });

    testWidgets('connected tile shows connected line without extraction when F=0', (
      tester,
    ) async {
      await pumpProvinceOverlayAtDarkTheme(
        tester,
        game: demoGameForOverlay,
        displayId: sampleProvinceIdForOverlay,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
        tileCapitalLinkPreview: const ProvinceTileCapitalLinkPreview(
          isCapitalConnected: true,
          extractionFull: 0,
        ),
      );
      expect(
        find.text(l10n.provinceOverlay_tileCapitalLinkConnected),
        findsOneWidget,
      );
      expect(find.textContaining('Extraction from this tile'), findsNothing);
    });
  });
}
