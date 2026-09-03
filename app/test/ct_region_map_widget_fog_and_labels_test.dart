// Concern split under repo.app_test_file_size (Refs #4013, #4352):
// land-base fog application.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';

import 'package:colonizethis_app/features/game/flame/caches/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show
        CtMapVisibilityMode,
        shouldApplyFogToFeatureOverlay,
        shouldApplyFogToInteriorPlainsVariantBase,
        shouldApplyFogToInteriorPlainsVariantOverlay,
        shouldApplyFogToLandBase;

import 'ct_region_map_test_support.dart';

void _expectLandFog({
  required CtMapVisibilityMode visibilityMode,
  required TerrainType terrain,
  required bool landBase,
  required bool featureOverlay,
  String? reason,
}) {
  expect(
    shouldApplyFogToLandBase(
      visibilityMode: visibilityMode,
      tileVisibility: TileVisibility.fogged,
      terrain: terrain,
    ),
    landBase,
    reason: reason,
  );
  expect(
    shouldApplyFogToFeatureOverlay(
      visibilityMode: visibilityMode,
      tileVisibility: TileVisibility.fogged,
      terrain: terrain,
    ),
    featureOverlay,
    reason: reason,
  );
}

Future<void> _pumpBlank(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  suppressLogsForTests();

  group('CtRegionMap (Flame map widget)', () {
    setUpAll(warmCtRegionMapCachesForTests);

    testWidgets(
      'land-base fog application skips feature terrains to prevent double darkening',
      (WidgetTester tester) async {
        await _pumpBlank(tester);
        const constrained = CtMapVisibilityMode.playerConstrained;
        _expectLandFog(
          visibilityMode: constrained,
          terrain: TerrainType.plains,
          landBase: true,
          featureOverlay: false,
          reason: 'Fogged plains darken in land-base only',
        );
        _expectLandFog(
          visibilityMode: constrained,
          terrain: TerrainType.desert,
          landBase: true,
          featureOverlay: false,
          reason: 'Fogged desert darkens in land-base only',
        );
        _expectLandFog(
          visibilityMode: constrained,
          terrain: TerrainType.swamp,
          landBase: false,
          featureOverlay: true,
          reason: 'Fogged feature tiles darken in overlay pass only',
        );
        _expectLandFog(
          visibilityMode: constrained,
          terrain: TerrainType.hardwoodForest,
          landBase: false,
          featureOverlay: true,
        );
        _expectLandFog(
          visibilityMode: CtMapVisibilityMode.full,
          terrain: TerrainType.plains,
          landBase: false,
          featureOverlay: false,
          reason: 'Full visibility mode must not apply fog',
        );
        _expectLandFog(
          visibilityMode: CtMapVisibilityMode.full,
          terrain: TerrainType.swamp,
          landBase: false,
          featureOverlay: false,
          reason: 'Full visibility mode must not apply fog',
        );
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'fogged interior plains variants apply fog exactly once on overlay pass',
      (WidgetTester tester) async {
        await _pumpBlank(tester);
        for (final case_
            in <
              ({
                CtMapVisibilityMode mode,
                TileVisibility visibility,
                bool base,
                bool overlay,
              })
            >[
              (
                mode: CtMapVisibilityMode.playerConstrained,
                visibility: TileVisibility.fogged,
                base: false,
                overlay: true,
              ),
              (
                mode: CtMapVisibilityMode.full,
                visibility: TileVisibility.fogged,
                base: false,
                overlay: false,
              ),
              (
                mode: CtMapVisibilityMode.playerConstrained,
                visibility: TileVisibility.visible,
                base: false,
                overlay: false,
              ),
            ]) {
          expect(
            shouldApplyFogToInteriorPlainsVariantBase(
              visibilityMode: case_.mode,
              tileVisibility: case_.visibility,
            ),
            case_.base,
            reason:
                'Variant base must remain un-fogged to avoid double darkening',
          );
          expect(
            shouldApplyFogToInteriorPlainsVariantOverlay(
              visibilityMode: case_.mode,
              tileVisibility: case_.visibility,
            ),
            case_.overlay,
            reason: 'Variant overlay is the single fog attenuation pass',
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'required civilian and province/sea label icon assets exist and are non-empty',
      (WidgetTester tester) async {
        await _pumpBlank(tester);
        for (final slug in kCivilianIconSlugs) {
          final colorPath = 'assets/icons/64/ui_icon_civ_$slug.png';
          final colorData = await rootBundle.load(colorPath);
          expect(
            colorData.lengthInBytes,
            greaterThan(0),
            reason: 'Civilian icon $colorPath is empty',
          );
        }
        for (final iconId in kProvinceLabelIconIds) {
          final path = 'assets/icons/64/ui_icon_$iconId.png';
          final data = await rootBundle.load(path);
          expect(
            data.lengthInBytes,
            greaterThan(0),
            reason: 'Province label icon $path is empty',
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'capital star icon asset resembles a gold star silhouette',
      (WidgetTester tester) async {
        await _pumpBlank(tester);
        await tester.runAsync(() async {
          final data = await rootBundle.load(
            'assets/icons/64/ui_icon_map_capital_star.png',
          );
          await expectCapitalStarSilhouette(data);
        });
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });
}
