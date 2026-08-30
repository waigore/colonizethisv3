// MAP20001 Civilian Station spy hide/disable/enable predicates (Refs #4439).
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md

import 'package:colonizethis_app/features/game/flame/map_state/province_station_spy_action_state.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'civilian_units_panel_test_support.dart';
import 'panel_fixtures/core.dart';

const _human = 'h1';
const _homeTile = 'oldWorld|p1|0|0';
const _rivalTile = 'oldWorld|p2|0|0';

void main() {
  suppressLogsForTests();

  ProvinceStationSpyActionState state({
    required Game game,
    Orders orders = const Orders(),
    String? selectedTileKey = _rivalTile,
    bool canMutateViaUi = true,
    bool isSeaZone = false,
    bool tileObfuscated = false,
    bool civilianSectionObfuscated = false,
  }) {
    return computeProvinceStationSpyActionState(
      game: game,
      orders: orders,
      humanPlayerId: _human,
      selectedTileKey: selectedTileKey,
      canMutateViaUi: canMutateViaUi,
      isSeaZone: isSeaZone,
      tileObfuscated: tileObfuscated,
      civilianSectionObfuscated: civilianSectionObfuscated,
    );
  }

  test('enables when an idle Spy can occupy a different tile', () {
    final game = buildCivilianSpyFixtureGame(id: 'g_spy_enable');
    final resolved = state(game: game);
    expect(resolved.showControl, isTrue);
    expect(resolved.enabled, isTrue);
    expect(resolved.disabledReason, isNull);
  });

  test('hides in sea-zone, observe, and obfuscated contexts', () {
    final game = buildCivilianSpyFixtureGame(id: 'g_spy_hide');
    expect(state(game: game, isSeaZone: true).showControl, isFalse);
    expect(state(game: game, canMutateViaUi: false).showControl, isFalse);
    expect(state(game: game, tileObfuscated: true).showControl, isFalse);
    expect(
      state(game: game, civilianSectionObfuscated: true).showControl,
      isFalse,
    );
    expect(state(game: game, selectedTileKey: null).showControl, isFalse);
  });

  test(
    'hides when own Spy already occupies the tile and no other relocator',
    () {
      final game = buildCivilianSpyFixtureGame(id: 'g_spy_on_tile');
      final resolved = state(game: game, selectedTileKey: _homeTile);
      expect(resolved.showControl, isFalse);
    },
  );

  test('enables when another Spy can join a tile that already has one', () {
    final base = buildCivilianSpyFixtureGame(id: 'g_spy_second');
    final game = buildPanelTestGame(
      id: 'g_spy_second',
      players: base.players,
      oldWorldProvinces: base.worldState.oldWorld.provinces,
      oldWorldUnits: [
        ...base.worldState.oldWorld.units,
        Unit(
          id: 'spy2',
          type: kUnitTypeSpy,
          ownerId: _human,
          locationProvinceId: 'oldWorld|p2',
          tileKey: _rivalTile,
        ),
      ],
    );
    final resolved = state(game: game, selectedTileKey: _rivalTile);
    expect(resolved.showControl, isTrue);
    expect(resolved.enabled, isTrue);
  });

  test('disables with noIdleSpy when the tile is occupiable', () {
    final game = buildCivilianSingleUnitOwGame(
      id: 'g_no_spy',
      unitId: 'e1',
      unitType: kUnitTypeExplorer,
    );
    final resolved = state(game: game, selectedTileKey: _homeTile);
    expect(resolved.showControl, isTrue);
    expect(resolved.enabled, isFalse);
    expect(resolved.disabledReason, ProvinceStationSpyDisabledReason.noIdleSpy);
  });

  test('disables with tileNotOccupiable when the destination is not land', () {
    final game = buildCivilianSpyFixtureGame(id: 'g_not_land');
    final resolved = state(game: game, selectedTileKey: 'oldWorld|missing|0|0');
    expect(resolved.showControl, isTrue);
    expect(resolved.enabled, isFalse);
    expect(
      resolved.disabledReason,
      ProvinceStationSpyDisabledReason.tileNotOccupiable,
    );
  });

  test('pending MoveOrder does not count as an eligible relocator', () {
    final game = buildCivilianSpyFixtureGame(id: 'g_pending_move');
    final orders = civilianSpyPendingMoveOrder(
      humanId: _human,
      spyId: 'spy1',
      destinationTileKey: _rivalTile,
    );
    final resolved = state(game: game, orders: orders);
    expect(resolved.showControl, isTrue);
    expect(resolved.enabled, isFalse);
    expect(resolved.disabledReason, ProvinceStationSpyDisabledReason.noIdleSpy);
  });
}
