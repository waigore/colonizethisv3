// Ranking and clamp helpers for MAP30001 / MAP30002. Refs #4440.
// SPEC: SPEC/ui/components/tile-radial-catalog.md.

import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_catalog.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_layout.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  test('ranks only conceivable actions and prefers enabled', () {
    final layout = rankTileRadialCatalog(
      exploreShowIcon: true,
      exploreEnabled: false,
      prospectShowIcon: true,
      prospectEnabled: true,
      buildImprovementShowIcon: false,
      buildImprovementEnabled: false,
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
      exploreShowIcon: true,
      exploreEnabled: false,
      prospectShowIcon: true,
      prospectEnabled: true,
      buildImprovementShowIcon: true,
      buildImprovementEnabled: true,
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
      exploreShowIcon: true,
      exploreEnabled: true,
      prospectShowIcon: true,
      prospectEnabled: true,
      buildImprovementShowIcon: true,
      buildImprovementEnabled: true,
      maxWedges: 1,
    );
    expect(layout.wedges, hasLength(1));
    expect(layout.wedges.single.action, TileRadialCatalogAction.explore);
    expect(layout.moreRemainder, hasLength(2));
  });

  test('catalog enum is only Explore, Prospect, and Build improvement', () {
    expect(TileRadialCatalogAction.values, [
      TileRadialCatalogAction.explore,
      TileRadialCatalogAction.prospect,
      TileRadialCatalogAction.buildImprovement,
    ]);
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
