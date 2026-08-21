// Ranking and clamp helpers for MAP30001 / MAP30002. Refs #4440, #4570.
// SPEC: SPEC/ui/components/tile-radial-catalog.md.

import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_catalog.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_layout.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Map<TileRadialCatalogAction, TileRadialActionVisibility> _vis({
  bool exploreShow = false,
  bool exploreEnabled = false,
  bool prospectShow = false,
  bool prospectEnabled = false,
  bool buildImprovementShow = false,
  bool buildImprovementEnabled = false,
  bool buildRoadShow = false,
  bool buildRoadEnabled = false,
  bool purchaseLandShow = false,
  bool purchaseLandEnabled = false,
  bool upgradeTownShow = false,
  bool upgradeTownEnabled = false,
  bool buildPortShow = false,
  bool buildPortEnabled = false,
  bool buildRailShow = false,
  bool buildRailEnabled = false,
  bool buildFortShow = false,
  bool buildFortEnabled = false,
}) {
  return {
    TileRadialCatalogAction.explore: (
      showIcon: exploreShow,
      enabled: exploreEnabled,
    ),
    TileRadialCatalogAction.prospect: (
      showIcon: prospectShow,
      enabled: prospectEnabled,
    ),
    TileRadialCatalogAction.buildImprovement: (
      showIcon: buildImprovementShow,
      enabled: buildImprovementEnabled,
    ),
    TileRadialCatalogAction.buildRoad: (
      showIcon: buildRoadShow,
      enabled: buildRoadEnabled,
    ),
    TileRadialCatalogAction.purchaseLand: (
      showIcon: purchaseLandShow,
      enabled: purchaseLandEnabled,
    ),
    TileRadialCatalogAction.upgradeTown: (
      showIcon: upgradeTownShow,
      enabled: upgradeTownEnabled,
    ),
    TileRadialCatalogAction.buildPort: (
      showIcon: buildPortShow,
      enabled: buildPortEnabled,
    ),
    TileRadialCatalogAction.buildRail: (
      showIcon: buildRailShow,
      enabled: buildRailEnabled,
    ),
    TileRadialCatalogAction.buildFort: (
      showIcon: buildFortShow,
      enabled: buildFortEnabled,
    ),
  };
}

void main() {
  suppressLogsForTests();

  test('ranks only conceivable actions and prefers enabled', () {
    final layout = rankTileRadialCatalog(
      visibility: _vis(
        exploreShow: true,
        exploreEnabled: false,
        prospectShow: true,
        prospectEnabled: true,
      ),
    );
    expect(layout.wedges, hasLength(2));
    expect(layout.moreRemainder, isEmpty);
    expect(layout.wedges[0].action, TileRadialCatalogAction.prospect);
    expect(layout.wedges[0].enabled, isTrue);
    expect(layout.wedges[1].action, TileRadialCatalogAction.explore);
    expect(layout.wedges[1].enabled, isFalse);
  });

  test('enabled Prospect precedes disabled Explore then Build improvement', () {
    final layout = rankTileRadialCatalog(
      visibility: _vis(
        exploreShow: true,
        exploreEnabled: false,
        prospectShow: true,
        prospectEnabled: true,
        buildImprovementShow: true,
        buildImprovementEnabled: true,
      ),
    );
    expect(layout.wedges.map((s) => s.action).toList(), [
      TileRadialCatalogAction.prospect,
      TileRadialCatalogAction.buildImprovement,
      TileRadialCatalogAction.explore,
    ]);
    expect(layout.moreRemainder, isEmpty);
  });

  test('caps wedges and sends the remainder to More', () {
    final layout = rankTileRadialCatalog(
      visibility: _vis(
        exploreShow: true,
        exploreEnabled: true,
        prospectShow: true,
        prospectEnabled: true,
        buildImprovementShow: true,
        buildImprovementEnabled: true,
      ),
      maxWedges: 1,
    );
    expect(layout.wedges, hasLength(1));
    expect(layout.wedges.single.action, TileRadialCatalogAction.explore);
    expect(layout.moreRemainder, hasLength(2));
  });

  test(
    'nine conceivable actions: five wedges then remainder in catalog order',
    () {
      final layout = rankTileRadialCatalog(
        visibility: _vis(
          exploreShow: true,
          exploreEnabled: true,
          prospectShow: true,
          prospectEnabled: true,
          buildImprovementShow: true,
          buildImprovementEnabled: true,
          buildRoadShow: true,
          buildRoadEnabled: true,
          purchaseLandShow: true,
          purchaseLandEnabled: true,
          upgradeTownShow: true,
          upgradeTownEnabled: true,
          buildPortShow: true,
          buildPortEnabled: true,
          buildRailShow: true,
          buildRailEnabled: true,
          buildFortShow: true,
          buildFortEnabled: true,
        ),
      );
      expect(layout.wedges, hasLength(5));
      expect(layout.moreRemainder, hasLength(4));
      expect(layout.wedges.map((s) => s.action).toList(), [
        TileRadialCatalogAction.explore,
        TileRadialCatalogAction.prospect,
        TileRadialCatalogAction.buildImprovement,
        TileRadialCatalogAction.buildRoad,
        TileRadialCatalogAction.purchaseLand,
      ]);
      expect(layout.moreRemainder.map((s) => s.action).toList(), [
        TileRadialCatalogAction.upgradeTown,
        TileRadialCatalogAction.buildPort,
        TileRadialCatalogAction.buildRail,
        TileRadialCatalogAction.buildFort,
      ]);
    },
  );

  test(
    'enabled later catalog actions displace disabled core three from wedges',
    () {
      final layout = rankTileRadialCatalog(
        visibility: _vis(
          exploreShow: true,
          exploreEnabled: false,
          prospectShow: true,
          prospectEnabled: false,
          buildImprovementShow: true,
          buildImprovementEnabled: false,
          buildRoadShow: true,
          buildRoadEnabled: true,
          purchaseLandShow: true,
          purchaseLandEnabled: true,
          upgradeTownShow: true,
          upgradeTownEnabled: true,
          buildPortShow: true,
          buildPortEnabled: true,
          buildRailShow: true,
          buildRailEnabled: true,
        ),
      );
      expect(layout.wedges.map((s) => s.action).toList(), [
        TileRadialCatalogAction.buildRoad,
        TileRadialCatalogAction.purchaseLand,
        TileRadialCatalogAction.upgradeTown,
        TileRadialCatalogAction.buildPort,
        TileRadialCatalogAction.buildRail,
      ]);
      expect(layout.moreRemainder.map((s) => s.action).toList(), [
        TileRadialCatalogAction.explore,
        TileRadialCatalogAction.prospect,
        TileRadialCatalogAction.buildImprovement,
      ]);
    },
  );

  test('catalog enum is the nine civilian work shortcuts', () {
    expect(TileRadialCatalogAction.values, kTileRadialCatalogOrder);
  });

  test('clamp reports fit on a 400 dp square and miss on a tiny box', () {
    expect(
      tileRadialFitsAfterClamp(
        viewport: const Size(400, 400),
        anchor: const Offset(200, 200),
      ),
      isTrue,
    );
    expect(
      tileRadialFitsAfterClamp(
        viewport: const Size(100, 100),
        anchor: const Offset(50, 50),
      ),
      isFalse,
    );
  });
}
