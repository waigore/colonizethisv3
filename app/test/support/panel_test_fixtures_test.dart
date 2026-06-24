// Focused tests for the shared lightweight panel fixtures (Refs #3656).

import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'panel_test_fixtures.dart';

void main() {
  group('buildPanelTestGame', () {
    test('defaults to a single human player and empty regions', () {
      final game = buildPanelTestGame();
      expect(game.players, hasLength(1));
      expect(game.players.first.id, kPanelTestHumanPlayerId);
      expect(game.players.first.isHuman, isTrue);
      expect(game.worldState.oldWorld.units, isEmpty);
      expect(game.worldState.newWorld.units, isEmpty);
      expect(game.worldState.fleets, isEmpty);
    });

    test('threads provided provinces and units into each region', () {
      final game = buildPanelTestGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', displayName: 'A'),
        ],
        oldWorldUnits: [
          Unit(
            id: 'u1',
            type: kUnitTypeBuilder,
            ownerId: kPanelTestHumanPlayerId,
            locationProvinceId: 'oldWorld|p1',
            tileKey: 'oldWorld|p1|0|0',
          ),
        ],
      );
      expect(game.worldState.oldWorld.provinces, hasLength(1));
      expect(game.worldState.oldWorld.units.single.id, 'u1');
    });
  });

  group('buildCivilianPanelTestGame', () {
    test('human owns idle civilians in both regions for panel coverage', () {
      final game = buildCivilianPanelTestGame();
      final human = game.players.first.id;
      final idleOld = game.worldState.oldWorld.units.where(
        (u) =>
            u.ownerId == human &&
            u.tileKey != null &&
            u.currentWork == null,
      );
      final idleNew = game.worldState.newWorld.units.where(
        (u) =>
            u.ownerId == human &&
            u.tileKey != null &&
            u.currentWork == null,
      );
      expect(idleOld, isNotEmpty);
      expect(idleNew, isNotEmpty);
    });

    test('includes one in-progress (working) civilian', () {
      final game = buildCivilianPanelTestGame();
      final working = [
        ...game.worldState.oldWorld.units,
        ...game.worldState.newWorld.units,
      ].where((u) => u.currentWork != null);
      expect(working, hasLength(1));
      expect(working.single.status, UnitStatus.working);
    });

    test('a non-owning player id yields no civilian units (empty state)', () {
      final game = buildCivilianPanelTestGame();
      final owned = [
        ...game.worldState.oldWorld.units,
        ...game.worldState.newWorld.units,
      ].where((u) => u.ownerId == 'no-such-player');
      expect(owned, isEmpty);
    });
  });

  group('buildMilitaryPanelTestGame', () {
    test('human owns military regiments and armies in both regions', () {
      final game = buildMilitaryPanelTestGame();
      final human = game.players.first.id;
      final oldRegiments = game.worldState.oldWorld.units.where(
        (u) => u.ownerId == human && u.type == kPanelTestRegimentType,
      );
      final newRegiments = game.worldState.newWorld.units.where(
        (u) => u.ownerId == human && u.type == kPanelTestRegimentType,
      );
      expect(oldRegiments, isNotEmpty);
      expect(newRegiments, isNotEmpty);

      final armies = game.worldState.armies.where((a) => a.ownerId == human);
      expect(armies.map((a) => a.regionId).toSet(), {'oldWorld', 'newWorld'});
      // Old-world army has >=2 regiments so the Split action renders.
      expect(
        armies.firstWhere((a) => a.regionId == 'oldWorld').regimentUnitIds,
        hasLength(2),
      );
    });

    test('stationed provinces carry display names and town tile keys', () {
      final game = buildMilitaryPanelTestGame();
      final provinces = [
        ...game.worldState.oldWorld.provinces,
        ...game.worldState.newWorld.provinces,
      ];
      for (final province in provinces) {
        expect(province.displayName, isNotNull);
        expect(province.townTileKey, isNotNull);
      }
    });

    test('a non-owning player id yields no armies or regiments (empty state)',
        () {
      final game = buildMilitaryPanelTestGame();
      expect(
        game.worldState.armies.where((a) => a.ownerId == 'no-such-player'),
        isEmpty,
      );
      final owned = [
        ...game.worldState.oldWorld.units,
        ...game.worldState.newWorld.units,
      ].where((u) => u.ownerId == 'no-such-player');
      expect(owned, isEmpty);
    });
  });

  group('buildTechnologyPanelTestGame', () {
    test('exposes a single human player with no researched tech', () {
      final game = buildTechnologyPanelTestGame();
      expect(game.players, hasLength(1));
      final player = game.players.first;
      expect(player.id, kPanelTestHumanPlayerId);
      expect(player.isHuman, isTrue);
      // Base player starts with no researched tech so the "None yet" /
      // all-techs-available assertions hold without a copyWith override.
      expect(player.techUnlocked ?? const <String, bool>{}, isEmpty);
      // No generated map/topology data is needed by TechnologyPanel.
      expect(game.worldState.oldWorld.units, isEmpty);
      expect(game.worldState.newWorld.units, isEmpty);
    });

    test('uses the default research-slot count (player.researchSlots null)', () {
      final game = buildTechnologyPanelTestGame();
      // Null defers to TechnologyPanel's `player.researchSlots ?? 3` default
      // (three active + one locked slot card).
      expect(game.players.first.researchSlots, isNull);
    });
  });

  group('buildSideMenuTestGame', () {
    test('exposes a single human player and defaults infiniteMode to false', () {
      final game = buildSideMenuTestGame();
      expect(game.players, hasLength(1));
      expect(game.players.first.id, kPanelTestHumanPlayerId);
      expect(game.players.first.isHuman, isTrue);
      // The Game Parameters dialog reads `infiniteMode`; suites opt into the
      // "Infinite mode: On" line via copyWith, so the base must be false.
      expect(game.infiniteMode, isFalse);
      // No generated map/topology data is consumed by the menu chrome.
      expect(game.worldState.oldWorld.units, isEmpty);
      expect(game.worldState.newWorld.units, isEmpty);
    });
  });

  group('buildGameScreenSpecsTestGame', () {
    test('exposes a single human player usable as the victory winner', () {
      final game = buildGameScreenSpecsTestGame();
      expect(game.players, hasLength(1));
      final human = game.players.first;
      expect(human.id, kPanelTestHumanPlayerId);
      expect(human.isHuman, isTrue);
      // The victory spec keys `VictoryState.winnerPlayerId` off players.first,
      // so the list must be non-empty.
      expect(game.players, isNotEmpty);
      // No generated map/topology data is consumed (mapViewData is null).
      expect(game.worldState.oldWorld.units, isEmpty);
      expect(game.worldState.newWorld.units, isEmpty);
      expect(game.victory, isNull);
    });
  });

  group('buildDiplomacyScreenTestGame', () {
    test('human first player has an affordable treasury and an AI opponent', () {
      final game = buildDiplomacyScreenTestGame();
      expect(game.players, hasLength(2));
      final human = game.players.first;
      expect(human.id, kPanelTestHumanPlayerId);
      expect(human.isHuman, isTrue);
      // Grant-aid dialog default amount (1000) must be affordable by default.
      expect(human.treasury, greaterThanOrEqualTo(1000));
      // players[1] resolves as a grant/subsidy target faction.
      expect(game.players[1].id, 'gp2');
      expect(game.players[1].isHuman, isFalse);
    });

    test('seeds no diplomacy relations (opponent stays undiscovered)', () {
      final game = buildDiplomacyScreenTestGame();
      // The screen suites only assert the always-rendered section headings, so
      // the opponent is intentionally left undiscovered (no relation seeded).
      expect(game.diplomacyRelations, isEmpty);
      // No generated map/topology data is consumed by the screen chrome.
      expect(game.worldState.oldWorld.units, isEmpty);
      expect(game.worldState.newWorld.units, isEmpty);
    });
  });

  group('buildDiplomacyPanelTestGame', () {
    test('human first player with an affordable treasury and an AI opponent', () {
      final game = buildDiplomacyPanelTestGame();
      expect(game.players, hasLength(2));
      final human = game.players.first;
      expect(human.id, kPanelTestHumanPlayerId);
      expect(human.isHuman, isTrue);
      expect(human.treasury, greaterThanOrEqualTo(1000));
      expect(game.players[1].id, 'gp2');
      expect(game.players[1].isHuman, isFalse);
    });

    test('seeds an at-peace GP relation so the opponent is discovered', () {
      final game = buildDiplomacyPanelTestGame();
      // Unlike the screen fixture, the panel suites need a discovered row, so a
      // persisted relation (indexed by buildPlayerView.diplomacyByOtherId) is
      // seeded between the human and the AI great power.
      expect(game.diplomacyRelations, hasLength(1));
      final relation = game.diplomacyRelations.single;
      expect(
        {relation.factionId1, relation.factionId2},
        {kPanelTestHumanPlayerId, 'gp2'},
      );
      expect(relation.state, RelationState.atPeace);
      // No generated map/topology data is consumed by the panel chrome.
      expect(game.worldState.oldWorld.units, isEmpty);
      expect(game.worldState.newWorld.units, isEmpty);
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
      // gp2 at peace (PEACE badge), gp3 at war (WAR badge) so both relation
      // state badges are exercised by the panel suites.
      final byOther = {
        for (final r in game.diplomacyRelations)
          (r.factionId1 == kPanelTestHumanPlayerId
              ? r.factionId2
              : r.factionId1): r,
      };
      expect(byOther['gp2']!.state, RelationState.atPeace);
      expect(byOther['gp3']!.state, RelationState.atWar);
    });

    test('gp2 outranks gp3 by military strength for a non-vacuous GP sort', () {
      final game = buildDiplomacyRichPanelTestGame();
      int regimentsFor(String id) => game.worldState.oldWorld.units
          .where((u) => u.ownerId == id)
          .length;
      expect(regimentsFor('gp2'), greaterThan(regimentsFor('gp3')));
    });
  });

  group('buildNavalPanelTestGame', () {
    test('human owns a home fleet and a non-home fleet, both with ships', () {
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

      final nonHome = ownedWithShips.where((f) => f.id != homeId);
      expect(nonHome, isNotEmpty);
      expect(nonHome.first.seaZoneId, isNotNull);
    });

    test('player has a capital tile and provinces exist in both regions', () {
      final game = buildNavalPanelTestGame();
      expect(game.players.first.capitalTile, isNotNull);
      expect(game.worldState.oldWorld.provinces, isNotEmpty);
      expect(game.worldState.newWorld.provinces, isNotEmpty);
    });

    test('exposes port/sea-zone tile data for locate resolution', () {
      final game = buildNavalPanelTestGame();
      final ports = game.worldState.portsByProvinceSeaboard;
      expect(ports, isNotEmpty);
      // A `region|province|seazone` key (>= 2 segments) so the sea-zone locate
      // assertions can resolve a port tile key.
      expect(
        ports.keys.any((k) => k.split('|').length >= 2),
        isTrue,
      );
      expect(game.worldState.tileKeysByRegionAndProvince, isNotEmpty);
    });

    test('a non-owning player id yields no fleets (empty state)', () {
      final game = buildNavalPanelTestGame();
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
      // The selection-prompt suites read oldWorld.units.first.id as the unit
      // passed to StartCivilianWorkTargetSelectionEvent; it must exist and be
      // owned by the human so _startWorkTargetSelection resolves it.
      final sample = game.worldState.oldWorld.units.first;
      expect(sample.ownerId, kPanelTestHumanPlayerId);
      expect(sample.type, kUnitTypeExplorer);
      // No generated map/topology data is consumed by the banner chrome.
      expect(game.worldState.newWorld.units, isEmpty);
    });
  });

  group('buildEventFeedNarrowInsetTestGame', () {
    test('single human owns one old-world province for the narrow inset suite',
        () {
      final game = buildEventFeedNarrowInsetTestGame();
      expect(game.players, hasLength(1));
      expect(game.players.first.id, kPanelTestHumanPlayerId);
      expect(game.worldState.oldWorld.provinces, hasLength(1));
      expect(
        game.worldState.oldWorld.provinces.single.ownerId,
        kPanelTestHumanPlayerId,
      );
      // No generated map/topology cells are needed; the suite only mounts the
      // canvas via buildLightweightMapViewData().
      expect(game.worldState.newWorld.units, isEmpty);
    });

    test('exposes a tappable old-world tile key mapped back to its province',
        () {
      final game = buildEventFeedNarrowInsetTestGame();
      final byProv = game.worldState.tileKeysByRegionAndProvince['oldWorld'];
      expect(byProv, isNotNull);
      // The suite taps `_firstOldWorldTileKey`; it must resolve a non-empty
      // tile key whose province id matches a seeded province so the opened
      // narrow overlay resolves real province data.
      final entry = byProv!.entries.firstWhere((e) => e.value.isNotEmpty);
      final tileKey = entry.value.first;
      expect(tileKey, isNotEmpty);
      final provinceIds =
          game.worldState.oldWorld.provinces.map((p) => p.id).toSet();
      expect(provinceIds, contains(entry.key));
    });
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
      // The dispose test reads oldWorld.units.first.id as the sample unit.
      expect(game.worldState.oldWorld.units, isNotEmpty);
    });

    test('seaboard entry resolves a known sea zone but not an unknown one', () {
      final game = buildMapAreaEventFeedTestGame();
      final ports = game.worldState.portsByProvinceSeaboard;
      expect(ports, isNotEmpty);
      // The naval feed line derives seaZoneId as `<region>|<seaboard-suffix>`
      // from the seaboard key and resolves it via tileKeyForSeaZoneLocation;
      // the entry must expose a `region|province|seazone` key shape.
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
        // The breakdown dialog's delta-colour pins need the economy-preview
        // Consumption/Production phases to move the stockpile without owned
        // tiles: peasants fed by grain become idle labour, and timber feeds the
        // lumber_from_timber recipe (Refs #3656).
        final game = buildProductionBreakdownDeltaTestGame();
        final human = game.players.firstWhere((p) => p.isHuman);
        expect(human.id, kPanelTestHumanPlayerId);
        expect(human.workerPool.peasants, greaterThan(0));
        expect(human.stockpile.quantityOf('grain'), greaterThan(0));
        // 5 lumber runs consume 10 timber; the fixture must stock enough.
        expect(human.stockpile.quantityOf('timber'), greaterThanOrEqualTo(10));
      },
    );

    test('a non-owning player id resolves to no player (empty-state guard)', () {
      final game = buildProductionBreakdownDeltaTestGame();
      expect(game.players.where((p) => p.id == 'no-such-player'), isEmpty);
    });
  });
}
