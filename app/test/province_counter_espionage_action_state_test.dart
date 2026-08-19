// MAP20001 Civilian Counter-espionage hide/disable/enable predicates (Refs #4528).
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md

import 'package:colonizethis_app/features/game/flame/map_state/province_counter_espionage_action_state.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kUnitTypeExplorer, kUnitTypeSpy, kWorkTargetCounterSpy;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'civilian_units_panel_test_support.dart';
import 'panel_fixtures/core.dart';

const _human = 'h1';
const _owned = 'oldWorld|p1';
const _foreign = 'oldWorld|p2';

void main() {
  suppressLogsForTests();

  ProvinceCounterEspionageActionState state({
    required Game game,
    Orders orders = const Orders(),
    String displayId = _owned,
    bool canMutateViaUi = true,
    bool isSeaZone = false,
    bool civilianSectionObfuscated = false,
  }) {
    return computeProvinceCounterEspionageActionState(
      game: game,
      orders: orders,
      humanPlayerId: _human,
      displayId: displayId,
      canMutateViaUi: canMutateViaUi,
      isSeaZone: isSeaZone,
      civilianSectionObfuscated: civilianSectionObfuscated,
    );
  }

  test('enables when an idle Spy can post on owned land', () {
    final game = buildCivilianSpyFixtureGame(id: 'g_ce_enable');
    final resolved = state(game: game);
    expect(resolved.showControl, isTrue);
    expect(resolved.enabled, isTrue);
    expect(resolved.disabledReason, isNull);
    expect(provinceLevelCounterSpyTileKey(_owned), 'oldWorld|p1|0|0');
  });

  test('hides in sea-zone, observe, obfuscated, and foreign provinces', () {
    final game = buildCivilianSpyFixtureGame(id: 'g_ce_hide');
    expect(state(game: game, isSeaZone: true).showControl, isFalse);
    expect(state(game: game, canMutateViaUi: false).showControl, isFalse);
    expect(
      state(game: game, civilianSectionObfuscated: true).showControl,
      isFalse,
    );
    expect(state(game: game, displayId: _foreign).showControl, isFalse);
  });

  test('disables with alreadyPosted when a Spy is on counter_spy', () {
    final game = buildPanelTestGame(
      id: 'g_ce_posted',
      players: [const Player(id: _human, displayName: 'Human', isHuman: true)],
      oldWorldProvinces: [
        const Province(
          id: _owned,
          regionId: 'oldWorld',
          displayName: 'Home',
          ownerId: _human,
        ),
      ],
      oldWorldUnits: [
        Unit(
          id: 'spy1',
          type: kUnitTypeSpy,
          ownerId: _human,
          locationProvinceId: _owned,
          tileKey: 'oldWorld|p1|0|0',
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: kWorkTargetCounterSpy,
            tileKey: 'oldWorld|p1|0|0',
            totalTurns: 1,
            remainingTurns: 1,
          ),
        ),
      ],
    );
    final resolved = state(game: game);
    expect(resolved.showControl, isTrue);
    expect(resolved.enabled, isFalse);
    expect(
      resolved.disabledReason,
      ProvinceCounterEspionageDisabledReason.alreadyPosted,
    );
  });

  test('disables with alreadyPosted when a pending WorkOrder posts it', () {
    final game = buildCivilianSpyFixtureGame(id: 'g_ce_pending');
    final orders = civilianSinglePendingWorkOrder(
      humanId: _human,
      unitId: 'spy1',
      target: kWorkTargetCounterSpy,
      targetTileKey: 'oldWorld|p1|0|0',
    );
    final resolved = state(game: game, orders: orders);
    expect(resolved.showControl, isTrue);
    expect(resolved.enabled, isFalse);
    expect(
      resolved.disabledReason,
      ProvinceCounterEspionageDisabledReason.alreadyPosted,
    );
  });

  test('disables with noIdleSpy when the province is owned', () {
    final game = buildPanelTestGame(
      id: 'g_ce_no_spy',
      players: [const Player(id: _human, displayName: 'Human', isHuman: true)],
      oldWorldProvinces: [
        const Province(
          id: _owned,
          regionId: 'oldWorld',
          displayName: 'Home',
          ownerId: _human,
        ),
      ],
      oldWorldUnits: [
        Unit(
          id: 'e1',
          type: kUnitTypeExplorer,
          ownerId: _human,
          locationProvinceId: _owned,
          tileKey: 'oldWorld|p1|0|0',
        ),
      ],
    );
    final resolved = state(game: game);
    expect(resolved.showControl, isTrue);
    expect(resolved.enabled, isFalse);
    expect(
      resolved.disabledReason,
      ProvinceCounterEspionageDisabledReason.noIdleSpy,
    );
  });
}
