import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('MapBaseLayerFlags cycle (Refs #4388)', () {
    test('preset order wraps full detail to terrain only', () {
      expect(
        MapBaseLayerFlags.terrainOnly.cycled,
        MapBaseLayerFlags.resourcesOnly,
      );
      expect(
        MapBaseLayerFlags.resourcesOnly.cycled,
        MapBaseLayerFlags.resourcesAndImprovements,
      );
      expect(
        MapBaseLayerFlags.resourcesAndImprovements.cycled,
        MapBaseLayerFlags.fullDetail,
      );
      expect(
        MapBaseLayerFlags.fullDetail.cycled,
        MapBaseLayerFlags.terrainOnly,
      );
    });

    test('non-preset combinations cycle to terrain only', () {
      const improvementsOnly = MapBaseLayerFlags(
        showResources: false,
        showImprovements: true,
        showRoads: false,
      );
      const improvementsAndRoads = MapBaseLayerFlags(
        showResources: false,
        showImprovements: true,
        showRoads: true,
      );
      expect(improvementsOnly.isCyclePreset, isFalse);
      expect(improvementsAndRoads.isCyclePreset, isFalse);
      expect(improvementsOnly.cycled, MapBaseLayerFlags.terrainOnly);
      expect(improvementsAndRoads.cycled, MapBaseLayerFlags.terrainOnly);
    });

    test('roads never paint without improvements', () {
      const illegal = MapBaseLayerFlags(
        showResources: true,
        showImprovements: false,
        showRoads: true,
      );
      expect(illegal.paintsRoads, isFalse);
      expect(illegal.combination, MapMarksCombination.resources);
    });
  });

  group('MapViewState information-layer flags (Refs #4388)', () {
    test('missing JSON fields load as all-on', () {
      final loaded = MapViewState.fromJson({
        'zoomMultiplier': 2.0,
        'showProvinceOverlay': false,
      });
      expect(loaded.showMapResources, isTrue);
      expect(loaded.showMapImprovements, isTrue);
      expect(loaded.showMapRoads, isTrue);
      expect(loaded.mapBaseLayerFlags, MapBaseLayerFlags.fullDetail);
    });

    test('round-trips explicit off flags', () {
      const state = MapViewState(
        showMapResources: false,
        showMapImprovements: true,
        showMapRoads: false,
      );
      final restored = MapViewState.fromJson(state.toJson());
      expect(restored.showMapResources, isFalse);
      expect(restored.showMapImprovements, isTrue);
      expect(restored.showMapRoads, isFalse);
      expect(restored, state);
    });
  });

  group('MapViewState capital-link highlight (Refs #4370)', () {
    test('missing JSON field defaults ON', () {
      final loaded = MapViewState.fromJson({
        'zoomMultiplier': 1.0,
        'showProvinceOverlay': true,
      });
      expect(loaded.showCapitalLinkDisconnectedHighlight, isTrue);
    });

    test('round-trips explicit off', () {
      const state = MapViewState(showCapitalLinkDisconnectedHighlight: false);
      final restored = MapViewState.fromJson(state.toJson());
      expect(restored.showCapitalLinkDisconnectedHighlight, isFalse);
      expect(restored, state);
    });
  });
}
