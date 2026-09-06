// Shortcut callback gating pins for province-detail overlay host support.

import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_detail_overlay_host_support_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('buildProvinceDetailShortcutCallbacks gating', () {
    late AppEventBus bus;

    setUp(() {
      bus = AppEventBus.create();
    });

    tearDown(() {
      bus.dispose();
    });

    test('returns all-null callbacks when no tile is selected', () {
      final callbacks = provinceDetailCallbacks(
        game: provinceDetailMinimalGame(),
        selectedTileKey: null,
        exploreEnabled: true,
        prospectEnabled: true,
        buildImprovementEnabled: true,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: true,
        bus: bus,
      );

      expect(callbacks.onExploreWithExplorerTap, isNull);
      expect(callbacks.onProspectWithExplorerTap, isNull);
      expect(callbacks.onBuildImprovementTap, isNull);
      expect(callbacks.onBuildRoadTap, isNull);
      expect(callbacks.onPurchaseLandTap, isNull);
    });

    test('returns all-null callbacks when every action is disabled', () {
      final callbacks = provinceDetailCallbacks(
        game: provinceDetailMinimalGame(),
        selectedTileKey: provinceDetailSupportTileKey,
        exploreEnabled: false,
        prospectEnabled: false,
        buildImprovementEnabled: false,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: false,
        bus: bus,
      );

      expect(callbacks.onExploreWithExplorerTap, isNull);
      expect(callbacks.onProspectWithExplorerTap, isNull);
      expect(callbacks.onBuildImprovementTap, isNull);
      expect(callbacks.onBuildRoadTap, isNull);
      expect(callbacks.onPurchaseLandTap, isNull);
    });

    test('exposes only the enabled action callback (per-action gating)', () {
      final exploreOnly = provinceDetailCallbacks(
        game: provinceDetailMinimalGame(),
        selectedTileKey: provinceDetailSupportTileKey,
        exploreEnabled: true,
        prospectEnabled: false,
        buildImprovementEnabled: false,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: false,
        bus: bus,
      );
      expect(exploreOnly.onExploreWithExplorerTap, isNotNull);
      expect(exploreOnly.onProspectWithExplorerTap, isNull);
      expect(exploreOnly.onBuildImprovementTap, isNull);
      expect(exploreOnly.onBuildRoadTap, isNull);
      expect(exploreOnly.onPurchaseLandTap, isNull);

      final prospectOnly = provinceDetailCallbacks(
        game: provinceDetailMinimalGame(),
        selectedTileKey: provinceDetailSupportTileKey,
        exploreEnabled: false,
        prospectEnabled: true,
        buildImprovementEnabled: false,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: false,
        bus: bus,
      );
      expect(prospectOnly.onExploreWithExplorerTap, isNull);
      expect(prospectOnly.onProspectWithExplorerTap, isNotNull);
      expect(prospectOnly.onBuildImprovementTap, isNull);
      expect(prospectOnly.onBuildRoadTap, isNull);
      expect(prospectOnly.onPurchaseLandTap, isNull);

      final buildOnly = provinceDetailCallbacks(
        game: provinceDetailMinimalGame(),
        selectedTileKey: provinceDetailSupportTileKey,
        exploreEnabled: false,
        prospectEnabled: false,
        buildImprovementEnabled: true,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: false,
        bus: bus,
      );
      expect(buildOnly.onExploreWithExplorerTap, isNull);
      expect(buildOnly.onProspectWithExplorerTap, isNull);
      expect(buildOnly.onBuildImprovementTap, isNotNull);
      expect(buildOnly.onBuildRoadTap, isNull);
      expect(buildOnly.onPurchaseLandTap, isNull);

      final buildRoadOnly = provinceDetailCallbacks(
        game: provinceDetailMinimalGame(),
        selectedTileKey: provinceDetailSupportTileKey,
        exploreEnabled: false,
        prospectEnabled: false,
        buildImprovementEnabled: false,
        buildRoadEnabled: true,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: false,
        bus: bus,
      );
      expect(buildRoadOnly.onExploreWithExplorerTap, isNull);
      expect(buildRoadOnly.onProspectWithExplorerTap, isNull);
      expect(buildRoadOnly.onBuildImprovementTap, isNull);
      expect(buildRoadOnly.onBuildRoadTap, isNotNull);
      expect(buildRoadOnly.onPurchaseLandTap, isNull);

      final purchaseLandOnly = provinceDetailCallbacks(
        game: provinceDetailMinimalGame(),
        selectedTileKey: provinceDetailSupportTileKey,
        exploreEnabled: false,
        prospectEnabled: false,
        buildImprovementEnabled: false,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: true,
        bus: bus,
      );
      expect(purchaseLandOnly.onExploreWithExplorerTap, isNull);
      expect(purchaseLandOnly.onProspectWithExplorerTap, isNull);
      expect(purchaseLandOnly.onBuildImprovementTap, isNull);
      expect(purchaseLandOnly.onBuildRoadTap, isNull);
      expect(purchaseLandOnly.onPurchaseLandTap, isNotNull);
    });
  });
}
