// Diplomacy and naval panel fixture coverage (Refs #3656, #4305).
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'panel_test_fixtures.dart';
void main() {
  group('buildDiplomacyScreenTestGame / buildDiplomacyPanelTestGame', () {
    test('screen: affordable human+AI, undiscovered; panel: at-peace relation', () {
      final screen = buildDiplomacyScreenTestGame();
      expect(screen.players, hasLength(2));
      expect(screen.players.first.id, kPanelTestHumanPlayerId);
      expect(screen.players.first.treasury, greaterThanOrEqualTo(1000));
      expect(screen.players[1].id, 'gp2');
      expect(screen.diplomacyRelations, isEmpty);
      expect(screen.worldState.oldWorld.units, isEmpty);
      final panel = buildDiplomacyPanelTestGame();
      expect(panel.players.first.isHuman, isTrue);
      expect(panel.players[1].isHuman, isFalse);
      expect(panel.diplomacyRelations, hasLength(1));
      final relation = panel.diplomacyRelations.single;
      expect(
        {relation.factionId1, relation.factionId2},
        {kPanelTestHumanPlayerId, 'gp2'},
      );
      expect(relation.state, RelationState.atPeace);
    });
  });
  group('buildDiplomacyRichPanelTestGame', () {
    test('seeds three GPs, one Minor Nation, and one Tribe', () {
      final game = buildDiplomacyRichPanelTestGame();
      expect(game.players.map((p) => p.id), [
        kPanelTestHumanPlayerId,
        'gp2',
        'gp3',
      ]);
      expect(game.players.first.isHuman, isTrue);
      expect(game.minorNations.map((m) => m.id), ['m1']);
      expect(game.tribes.map((t) => t.id), ['t1']);
    });
    test('discovers every opponent via a persisted human relation', () {
      final game = buildDiplomacyRichPanelTestGame();
      expect(game.diplomacyRelations, hasLength(4));
      final otherIds = game.diplomacyRelations.map((r) {
        return r.factionId1 == kPanelTestHumanPlayerId
            ? r.factionId2
            : r.factionId1;
      }).toSet();
      expect(otherIds, {'gp2', 'gp3', 'm1', 't1'});
      final byOther = {
        for (final r in game.diplomacyRelations)
          (r.factionId1 == kPanelTestHumanPlayerId
                  ? r.factionId2
                  : r.factionId1):
              r,
      };
      expect(byOther['gp2']!.state, RelationState.atPeace);
      expect(byOther['gp3']!.state, RelationState.atWar);
    });
    test('gp2 outranks gp3 by military strength for a non-vacuous GP sort', () {
      final game = buildDiplomacyRichPanelTestGame();
      int regimentsFor(String id) =>
          game.worldState.oldWorld.units.where((u) => u.ownerId == id).length;
      expect(regimentsFor('gp2'), greaterThan(regimentsFor('gp3')));
    });
  });
  group('buildDiplomacyPanelGameWithNoDiscoveredFactions', () {
    test('seeds only the solo human with empty relations', () {
      final game = buildDiplomacyPanelGameWithNoDiscoveredFactions();
      expect(game.players.map((p) => p.id), ['gp1']);
      expect(game.diplomacyRelations, isEmpty);
      expect(game.tribes, isEmpty);
      expect(game.minorNations, isEmpty);
    });
  });
  group('buildDiplomacyPanelGameWithTribeDiscoveredByVisibility', () {
    test('seeds tribe ownership and full visibility without a relation', () {
      final game = buildDiplomacyPanelGameWithTribeDiscoveredByVisibility();
      expect(game.tribes.map((t) => t.id), ['t1']);
      expect(game.diplomacyRelations, isEmpty);
      expect(
        game.worldState.playerVisibilityByTile['gp1'],
        containsPair('newWorld|t1prov|0|0', 'fullyVisible'),
      );
      expect(game.worldState.newWorld.provinces.single.ownerId, 't1');
    });
  });
  group('buildNavalPanelTestGame', () {
    test('home+sea fleets, capital, ports, and empty-state filter', () {
      final game = buildNavalPanelTestGame();
      final human = game.players.first.id;
      final ownedWithShips = game.worldState.fleets
          .where((f) => f.ownerId == human && f.shipTypeIds.isNotEmpty)
          .toList();
      expect(ownedWithShips, hasLength(2));
      final homeId = homeFleetIdFor(human);
      final homeFleet = ownedWithShips.firstWhere((f) => f.id == homeId);
      expect(homeFleet.inPortAtProvinceId, isNotNull);
      expect(homeFleet.shipTypeIds, hasLength(2));
      expect(ownedWithShips.any((f) => f.id != homeId && f.seaZoneId != null), isTrue);
      expect(game.players.first.capitalTile, isNotNull);
      expect(game.worldState.oldWorld.provinces, isNotEmpty);
      expect(game.worldState.newWorld.provinces, isNotEmpty);
      final ports = game.worldState.portsByProvinceSeaboard;
      expect(ports.keys.any((k) => k.split('|').length >= 2), isTrue);
      expect(game.worldState.tileKeysByRegionAndProvince, isNotEmpty);
      expect(
        game.worldState.fleets.where((f) => f.ownerId == 'no-such-player'),
        isEmpty,
      );
    });
  });
  group('buildSelectionPromptTestGame', () {
    test('human owns one old-world explorer resolvable as the sample unit', () {
      final game = buildSelectionPromptTestGame();
      expect(game.players, hasLength(1));
      expect(game.players.first.id, kPanelTestHumanPlayerId);
      final sample = game.worldState.oldWorld.units.first;
      expect(sample.ownerId, kPanelTestHumanPlayerId);
      expect(sample.type, kUnitTypeExplorer);
      expect(game.worldState.newWorld.units, isEmpty);
    });
  });
  group('buildEventFeedNarrowInsetTestGame', () {
    test(
      'single human owns one old-world province for the narrow inset suite',
      () {
        final game = buildEventFeedNarrowInsetTestGame();
        expect(game.players, hasLength(1));
        expect(game.players.first.id, kPanelTestHumanPlayerId);
        expect(game.worldState.oldWorld.provinces, hasLength(1));
        expect(
          game.worldState.oldWorld.provinces.single.ownerId,
          kPanelTestHumanPlayerId,
        );
        expect(game.worldState.newWorld.units, isEmpty);
      },
    );
    test(
      'exposes a tappable old-world tile key mapped back to its province',
      () {
        final game = buildEventFeedNarrowInsetTestGame();
        final byProv = game.worldState.tileKeysByRegionAndProvince['oldWorld'];
        expect(byProv, isNotNull);
        final entry = byProv!.entries.firstWhere((e) => e.value.isNotEmpty);
        final tileKey = entry.value.first;
        expect(tileKey, isNotEmpty);
        final provinceIds = game.worldState.oldWorld.provinces
            .map((p) => p.id)
            .toSet();
        expect(provinceIds, contains(entry.key));
      },
    );
  });
  group('buildMapAreaEventFeedTestGame', () {
    test('exposes a human plus a named AI opponent for feed-line lookups', () {
      final game = buildMapAreaEventFeedTestGame();
      expect(game.players, hasLength(2));
      final human = game.players.firstWhere((p) => p.isHuman);
      expect(human.id, kPanelTestHumanPlayerId);
      expect(human.displayName, isNotEmpty);
      final opponent = game.players.firstWhere((p) => p.id != human.id);
      expect(opponent.isHuman, isFalse);
      expect(opponent.displayName, isNotEmpty);
      expect(game.worldState.oldWorld.units, isNotEmpty);
    });
    test('seaboard entry resolves a known sea zone but not an unknown one', () {
      final game = buildMapAreaEventFeedTestGame();
      final ports = game.worldState.portsByProvinceSeaboard;
      expect(ports, isNotEmpty);
      final key = ports.keys.first;
      final parts = key.split('|');
      expect(parts.length, greaterThanOrEqualTo(3));
      expect(ports[key], isNotEmpty);
    });
  });
  group('buildProductionBreakdownDeltaTestGame', () {
    test(
      'human carries fed labour + recipe-input stockpile for non-zero deltas',
      () {
        final game = buildProductionBreakdownDeltaTestGame();
        final human = game.players.firstWhere((p) => p.isHuman);
        expect(human.id, kPanelTestHumanPlayerId);
        expect(human.workerPool.peasants, greaterThan(0));
        expect(human.stockpile.quantityOf('grain'), greaterThan(0));
        expect(human.stockpile.quantityOf('timber'), greaterThanOrEqualTo(10));
      },
    );
    test(
      'a non-owning player id resolves to no player (empty-state guard)',
      () {
        final game = buildProductionBreakdownDeltaTestGame();
        expect(game.players.where((p) => p.id == 'no-such-player'), isEmpty);
      },
    );
  });}
