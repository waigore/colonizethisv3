import 'package:colonizethis_app/features/game/widgets/shell/old_world_race_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show kMilitaryVictoryOldWorldProvinceThreshold;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'panel_test_fixtures.dart';

ct_models.Province _provinceWithAssignedOwner({
  required ct_models.Province province,
  required int index,
  required int humanOw,
  required int rivalOw,
  required int thirdOw,
}) {
  if (index < humanOw) {
    return province.copyWith(ownerId: kPanelTestHumanPlayerId);
  }
  if (index < humanOw + rivalOw) {
    return province.copyWith(ownerId: 'gp2');
  }
  if (index < humanOw + rivalOw + thirdOw) {
    return province.copyWith(ownerId: 'gp3');
  }
  return province;
}

/// Snapshot math for the MAP10001 Old World race chip (Refs #4451).
void main() {
  suppressLogsForTests();

  ct_models.Game gameWithOwCounts({
    required int humanOw,
    required int rivalOw,
    int thirdOw = 0,
  }) {
    final base = buildPlayersBarTestGame();
    final ow = base.worldState.oldWorld;
    expect(
      ow.provinces.length,
      greaterThanOrEqualTo(humanOw + rivalOw + thirdOw),
    );
    final mutated = [
      for (var i = 0; i < ow.provinces.length; i++)
        _provinceWithAssignedOwner(
          province: ow.provinces[i],
          index: i,
          humanOw: humanOw,
          rivalOw: rivalOw,
          thirdOw: thirdOw,
        ),
    ];
    return base.copyWith(
      worldState: base.worldState.copyWith(
        oldWorld: ct_models.RegionData(provinces: mutated, units: ow.units),
      ),
    );
  }

  test('human ahead omits rival cue', () {
    final game = gameWithOwCounts(humanOw: 4, rivalOw: 1);
    final snapshot = OldWorldRaceSnapshot.fromGame(
      game: game,
      focusPlayerId: kPanelTestHumanPlayerId,
    );
    expect(snapshot.focusCount, 4);
    expect(snapshot.threshold, kMilitaryVictoryOldWorldProvinceThreshold);
    expect(snapshot.rivalIsAhead, isFalse);
    expect(snapshot.rivalLeaderName, isNull);
  });

  test('human ties omits rival cue', () {
    final game = gameWithOwCounts(humanOw: 2, rivalOw: 2);
    final snapshot = OldWorldRaceSnapshot.fromGame(
      game: game,
      focusPlayerId: kPanelTestHumanPlayerId,
    );
    expect(snapshot.focusCount, 2);
    expect(snapshot.rivalIsAhead, isFalse);
  });

  test('rival ahead names the leading court', () {
    final game = gameWithOwCounts(humanOw: 1, rivalOw: 4);
    final snapshot = OldWorldRaceSnapshot.fromGame(
      game: game,
      focusPlayerId: kPanelTestHumanPlayerId,
    );
    expect(snapshot.focusCount, 1);
    expect(snapshot.rivalIsAhead, isTrue);
    expect(snapshot.rivalLeaderName, 'Rival Power');
    expect(snapshot.rivalLeaderCount, 4);
  });

  test('leadingPlayerId is the OW leader by count then displayName', () {
    final game = gameWithOwCounts(humanOw: 1, rivalOw: 4);
    expect(OldWorldRaceSnapshot.leadingPlayerId(game), 'gp2');
  });
}
