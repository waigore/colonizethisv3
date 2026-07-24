import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay, demoRegionForOverlay;
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show ProvinceImprovableCommodityCount, buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_test_harness.dart';

String _foreignOwnedProvinceId({
  required Game game,
  required String humanPlayerId,
}) {
  for (final province in game.worldState.oldWorld.provinces) {
    final ownerId = province.ownerId;
    if (ownerId != null && ownerId.isNotEmpty && ownerId != humanPlayerId) {
      return province.id;
    }
  }
  fail(
    'Test setup: demo game has no foreign-owned Old World province for '
    'intel-gate pins.',
  );
}

ProvinceExtractionSnapshot _sampleExtractionSnapshot(
  String ownerId, {
  int capitalGrainBonus = 0,
}) {
  return ProvinceExtractionSnapshot(
    ownerId: ownerId,
    capitalGrainBonus: capitalGrainBonus,
    byCommodity: {
      'grain': const ProvinceExtractionCommodityTotals(
        effective: 1,
        full: 5,
        tileKeys: ['oldWorld|p1|0|0', 'oldWorld|p1|0|1'],
      ),
      'iron': const ProvinceExtractionCommodityTotals(
        effective: 5,
        full: 5,
        tileKeys: ['oldWorld|p1|1|0'],
      ),
    },
  );
}

const Map<String, ProvinceImprovableCommodityCount> _sampleAvailable = {
  'grain': ProvinceImprovableCommodityCount(
    count: 3,
    tileKeys: ['oldWorld|p1|0|0', 'oldWorld|p1|2|0'],
  ),
  'timber': ProvinceImprovableCommodityCount(
    count: 2,
    tileKeys: ['oldWorld|p1|0|1'],
  ),
};

void main() {
  suppressLogsForTests();

  testWidgets(
    'Extraction and Available appear above Town production (Refs #4002)',
    (tester) async {
      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final provinceId = ownedProvinceIdInOldWorld(
        game: game,
        ownerId: humanId,
      );
      final playerView = buildPlayerView(game, const MapTopology(), humanId);

      await pumpProvinceOverlayAtDarkTheme(
        tester,
        game: game,
        displayId: provinceId,
        region: demoRegionForOverlay,
        humanPlayerId: humanId,
        playerView: playerView,
        omniscientDetail: true,
        extractionSnapshot: _sampleExtractionSnapshot(humanId),
        availableByCommodity: _sampleAvailable,
      );

      expect(find.text('Extraction'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Town production'), findsOneWidget);
      expect(find.textContaining('1 (5)'), findsOneWidget);
      expect(find.textContaining('5 Iron'), findsOneWidget);
      expect(find.textContaining('3 Grain'), findsOneWidget);
      expect(find.textContaining('2 Timber'), findsOneWidget);

      final extractionY = tester.getTopLeft(find.text('Extraction')).dy;
      final availableY = tester.getTopLeft(find.text('Available')).dy;
      final townY = tester.getTopLeft(find.text('Town production')).dy;
      expect(extractionY, lessThan(availableY));
      expect(availableY, lessThan(townY));
    },
  );

  testWidgets(
    'empty Extraction/Available show dash placeholders (Refs #4002)',
    (tester) async {
      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final provinceId = ownedProvinceIdInOldWorld(
        game: game,
        ownerId: humanId,
      );
      final playerView = buildPlayerView(game, const MapTopology(), humanId);

      await pumpProvinceOverlayAtDarkTheme(
        tester,
        game: game,
        displayId: provinceId,
        region: demoRegionForOverlay,
        humanPlayerId: humanId,
        playerView: playerView,
        omniscientDetail: true,
      );

      expect(find.text('Extraction'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('—'), findsWidgets);
    },
  );

  testWidgets(
    'intel gate hides Extraction/Available quantities behind ??? (Refs #4002)',
    (tester) async {
      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final foreignProvinceId = _foreignOwnedProvinceId(
        game: game,
        humanPlayerId: humanId,
      );
      final playerView = buildPlayerView(game, const MapTopology(), humanId);

      await pumpProvinceOverlayAtDarkTheme(
        tester,
        game: game,
        displayId: foreignProvinceId,
        region: demoRegionForOverlay,
        humanPlayerId: humanId,
        playerView: playerView,
        omniscientDetail: false,
        extractionSnapshot: _sampleExtractionSnapshot(humanId),
        availableByCommodity: _sampleAvailable,
      );

      expect(find.text('Extraction'), findsNothing);
      expect(find.text('Available'), findsNothing);
      expect(find.textContaining('1 (5)'), findsNothing);
      expect(find.textContaining('3 Grain'), findsNothing);
      expect(find.text('???'), findsWidgets);
    },
  );

  testWidgets(
    'hovering Extraction commodity highlights related tile keys (Refs #4002)',
    (tester) async {
      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final provinceId = ownedProvinceIdInOldWorld(
        game: game,
        ownerId: humanId,
      );
      final playerView = buildPlayerView(game, const MapTopology(), humanId);
      Iterable<String>? highlighted;

      await pumpProvinceOverlayAtDarkTheme(
        tester,
        game: game,
        displayId: provinceId,
        region: demoRegionForOverlay,
        humanPlayerId: humanId,
        playerView: playerView,
        omniscientDetail: true,
        extractionSnapshot: _sampleExtractionSnapshot(humanId),
        availableByCommodity: _sampleAvailable,
        onHighlightTiles: (keys) {
          highlighted = keys;
        },
      );

      final grainSegment = find.textContaining('1 (5)');
      expect(grainSegment, findsOneWidget);
      final mouseRegions = find.ancestor(
        of: grainSegment,
        matching: find.byType(MouseRegion),
      );
      expect(mouseRegions, findsWidgets);
      final region = tester.widget<MouseRegion>(mouseRegions.first);
      region.onEnter!(const PointerEnterEvent());
      expect(
        highlighted,
        ['oldWorld|p1|0|0', 'oldWorld|p1|0|1'],
      );
      region.onExit!(const PointerExitEvent());
      expect(highlighted, isNull);
    },
  );

  testWidgets(
    'narrow shell wraps Extraction segments without ellipsis (Refs #4002)',
    (tester) async {
      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final provinceId = ownedProvinceIdInOldWorld(
        game: game,
        ownerId: humanId,
      );
      final playerView = buildPlayerView(game, const MapTopology(), humanId);

      await pumpProvinceOverlayAtDarkTheme(
        tester,
        game: game,
        displayId: provinceId,
        region: demoRegionForOverlay,
        humanPlayerId: humanId,
        playerView: playerView,
        omniscientDetail: true,
        shellWidth: 160,
        extractionSnapshot: ProvinceExtractionSnapshot(
          ownerId: humanId,
          byCommodity: {
            for (final id in const [
              'grain',
              'meat',
              'wool',
              'timber',
              'iron',
              'copper',
            ])
              id: ProvinceExtractionCommodityTotals(
                effective: 2,
                full: 2,
                tileKeys: ['oldWorld|p1|0|0'],
              ),
          },
        ),
      );

      expect(find.textContaining('2 Grain'), findsOneWidget);
      expect(find.textContaining('2 Meat'), findsOneWidget);
      expect(find.textContaining('2 Wool'), findsOneWidget);
      expect(find.textContaining('2 Timber'), findsOneWidget);
      expect(find.textContaining('2 Iron'), findsOneWidget);
      expect(find.textContaining('2 Copper'), findsOneWidget);
      expect(find.byType(Wrap), findsWidgets);
      final ellipsized = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.overflow == TextOverflow.ellipsis);
      expect(ellipsized, isEmpty);
    },
  );

  testWidgets(
    'capital grain bonus annotation is muted and distinct (Refs #4064)',
    (tester) async {
      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final provinceId = ownedProvinceIdInOldWorld(
        game: game,
        ownerId: humanId,
      );
      final playerView = buildPlayerView(game, const MapTopology(), humanId);

      await pumpProvinceOverlayAtDarkTheme(
        tester,
        game: game,
        displayId: provinceId,
        region: demoRegionForOverlay,
        humanPlayerId: humanId,
        playerView: playerView,
        omniscientDetail: true,
        extractionSnapshot: _sampleExtractionSnapshot(
          humanId,
          capitalGrainBonus: 2,
        ),
        availableByCommodity: _sampleAvailable,
      );

      expect(
        find.textContaining('incl. +2 capital grain bonus'),
        findsOneWidget,
      );
      final annotation = tester.widget<Text>(
        find.textContaining('incl. +2 capital grain bonus'),
      );
      expect(annotation.style?.color, EditorialMonoclePalette.muted);
    },
  );

  testWidgets(
    'capital grain bonus annotation is not a hover-highlight target '
    '(Refs #4064)',
    (tester) async {
      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final provinceId = ownedProvinceIdInOldWorld(
        game: game,
        ownerId: humanId,
      );
      final playerView = buildPlayerView(game, const MapTopology(), humanId);
      Iterable<String>? highlighted;

      await pumpProvinceOverlayAtDarkTheme(
        tester,
        game: game,
        displayId: provinceId,
        region: demoRegionForOverlay,
        humanPlayerId: humanId,
        playerView: playerView,
        omniscientDetail: true,
        extractionSnapshot: _sampleExtractionSnapshot(
          humanId,
          capitalGrainBonus: 2,
        ),
        availableByCommodity: _sampleAvailable,
        onHighlightTiles: (keys) {
          highlighted = keys;
        },
      );

      final bonus = find.textContaining('incl. +2 capital grain bonus');
      expect(bonus, findsOneWidget);
      expect(
        find.ancestor(of: bonus, matching: find.byType(MouseRegion)),
        findsNothing,
      );

      final grainSegment = find.textContaining('1 (5)');
      expect(grainSegment, findsOneWidget);
      final grainRegions = find.ancestor(
        of: grainSegment,
        matching: find.byType(MouseRegion),
      );
      expect(grainRegions, findsWidgets);
      tester.widget<MouseRegion>(grainRegions.first).onEnter!(
        const PointerEnterEvent(),
      );
      expect(highlighted, ['oldWorld|p1|0|0', 'oldWorld|p1|0|1']);
    },
  );

  test(
    'setSecondaryHighlights stores multi keys and clears single (Refs #4002)',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = container.read(mapProvincePanelProvider.notifier);
      n.reportMapTileTapped('r1|p1|0|0');
      n.setSecondaryHighlights(['r1|p1|1|0', 'r1|p1|2|0']);
      var state = container.read(mapProvincePanelProvider);
      expect(state.secondaryHighlightTileKey, isNull);
      expect(state.secondaryHighlightTileKeys, {'r1|p1|1|0', 'r1|p1|2|0'});

      n.setSecondaryHighlight('r1|p1|3|0');
      state = container.read(mapProvincePanelProvider);
      expect(state.secondaryHighlightTileKey, 'r1|p1|3|0');
      expect(state.secondaryHighlightTileKeys, isNull);
    },
  );
}
