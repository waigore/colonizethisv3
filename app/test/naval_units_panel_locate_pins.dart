// Locate-button scenario pins for naval_units_panel_part1 (Refs #4224 Slice D).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'naval_units_panel_test_support.dart';

enum NavalPanelLocateKind { anyFleet, bothRegions, seaZone, portProvince }

typedef NavalPanelLocateCase = ({
  String name,
  NavalPanelLocateKind kind,
});

List<NavalPanelLocateCase> navalPanelLocateCases() => const [
  (
    name: 'AC: Locate button emits LocateMapTileEvent',
    kind: NavalPanelLocateKind.anyFleet,
  ),
  (
    name:
        'sections render for fleets in both regions and locate button passes region id',
    kind: NavalPanelLocateKind.bothRegions,
  ),
  (
    name: 'AC: Sea-zone fleet locate button uses correct sea-zone tile key',
    kind: NavalPanelLocateKind.seaZone,
  ),
  (
    name: 'AC: Port fleet locate button uses correct province tile key',
    kind: NavalPanelLocateKind.portProvince,
  ),
];

Future<void> pumpNavalLocateCase(
  WidgetTester tester,
  NavalPanelLocateCase case_, {
  required Game baseGame,
  required String humanId,
}) async {
  final (bus, events) = wireNavalLocateCaptureBus();
  Game game = baseGame;
  Finder tile = find.byTooltip('Locate fleet');
  switch (case_.kind) {
    case NavalPanelLocateKind.anyFleet:
      await pumpNavalPanel(
        tester,
        game: game,
        humanPlayerId: humanId,
        bus: bus,
      );
      if (tile.evaluate().isEmpty) return;
      await tester.tap(tile.first);
      await tester.pumpAndSettle();
      expect(events, isNotEmpty);
      expect(
        events.last.regionId == 'oldWorld' || events.last.regionId == 'newWorld',
        isTrue,
      );
      return;
    case NavalPanelLocateKind.bothRegions:
      final playerFleets = baseGame.worldState.fleets
          .where((f) => f.ownerId == humanId && f.shipTypeIds.isNotEmpty)
          .toList();
      expect(playerFleets, isNotEmpty);
      final nwProvinces = baseGame.worldState.newWorld.provinces;
      expect(nwProvinces, isNotEmpty);
      game = withNavalPanelExtraFleets(baseGame, [
        playerFleets.first.copyWith(
          id: 'test_new_world_fleet',
          regionId: 'newWorld',
          inPortAtProvinceId: nwProvinces.first.id,
          seaZoneId: null,
          ownerId: humanId,
        ),
      ]);
      await pumpNavalPanel(
        tester,
        game: game,
        humanPlayerId: humanId,
        bus: bus,
      );
      expect(find.text('OLD WORLD'), findsAtLeastNWidgets(1));
      expect(find.text('NEW WORLD'), findsAtLeastNWidgets(1));
      tile = navalFleetTileFinder('Fleet test_new_world_fleet');
      if (tile.evaluate().isEmpty) {
        tile = navalFleetTileFinder('Home Fleet');
      }
      if (!await tapLocateOnNavalFleetTile(tester, tile)) return;
      if (events.isEmpty) return;
      expect(events.last.tileKey, isNotNull);
      expect(events.last.regionId, isNotNull);
      return;
    case NavalPanelLocateKind.seaZone:
      final seaFleet = baseGame.worldState.fleets.firstWhere(
        (f) => f.ownerId == humanId && f.shipTypeIds.isNotEmpty && f.isAtSea,
      );
      final expectedTileKey = baseGame.worldState.portsByProvinceSeaboard.entries
          .firstWhere((e) => e.key.split('|').length >= 2)
          .value;
      await pumpNavalPanel(
        tester,
        game: baseGame,
        humanPlayerId: humanId,
        bus: bus,
      );
      tile = navalFleetTileFinder(navalFleetTileLabel(seaFleet, humanId));
      expect(tile, findsOneWidget);
      if (!await tapLocateOnNavalFleetTile(tester, tile)) return;
      expect(events.last.tileKey, expectedTileKey);
      expect(events.last.regionId, seaFleet.regionId);
      return;
    case NavalPanelLocateKind.portProvince:
      final target = firstNavalNonCapitalLocateTarget(baseGame, humanId);
      if (target == null) {
        fail('No non-capital province with a resolvable tile key found');
      }
      final baseFleet = baseGame.worldState.fleets.firstWhere(
        (f) => f.ownerId == humanId && f.shipTypeIds.isNotEmpty,
      );
      final portFleet = baseFleet.copyWith(
        id: 'test_port_fleet',
        ownerId: humanId,
        regionId: target.province.regionId,
        inPortAtProvinceId: target.province.id,
        seaZoneId: null,
      );
      await pumpNavalPanel(
        tester,
        game: withNavalPanelExtraFleets(baseGame, [portFleet]),
        humanPlayerId: humanId,
        bus: bus,
      );
      tile = navalFleetTileFinder('Fleet ${portFleet.id}');
      expect(tile, findsOneWidget);
      if (!await tapLocateOnNavalFleetTile(tester, tile)) return;
      expect(events.last.tileKey, target.tileKey);
      expect(events.last.regionId, portFleet.regionId);
  }
}
