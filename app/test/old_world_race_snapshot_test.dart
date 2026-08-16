import 'package:colonizethis_app/features/game/widgets/shell/old_world_race_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show kMilitaryVictoryOldWorldProvinceThreshold;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'panel_test_fixtures.dart';

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
    final mutated = <ct_models.Province>[];
    var assignedHuman = 0;
    var assignedRival = 0;
    var assignedThird = 0;
    for (final province in ow.provinces) {
      if (assignedHuman < humanOw) {
        mutated.add(province.copyWith(ownerId: kPanelTestHumanPlayerId));
        assignedHuman++;
      } else if (assignedRival < rivalOw) {
        mutated.add(province.copyWith(ownerId: 'gp2'));
        assignedRival++;
      } else if (assignedThird < thirdOw) {
        mutated.add(province.copyWith(ownerId: 'gp3'));
        assignedThird++;
      } else {
        mutated.add(province);
      }
    }
    expect(assignedHuman, humanOw);
    expect(assignedRival, rivalOw);
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
