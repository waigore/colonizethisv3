import 'package:colonizethis_app/features/game/widgets/shell/game_map_players_bar.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'game_map_players_bar_support.dart';

void main() {
  suppressLogsForTests();

  test(
    'greatPowerRoster sorts by Old World count desc then displayName asc',
    () {
      final game = playersBarGameWithOwnership();
      final roster = GameMapPlayersBar.greatPowerRoster(game);
      for (var i = 0; i < roster.length - 1; i++) {
        final leftCount = GameMapPlayersBar.oldWorldCountFor(
          game,
          roster[i].id,
        );
        final rightCount = GameMapPlayersBar.oldWorldCountFor(
          game,
          roster[i + 1].id,
        );
        expect(leftCount >= rightCount, isTrue);
        if (leftCount == rightCount) {
          expect(
            roster[i].displayName.compareTo(roster[i + 1].displayName),
            lessThan(0),
          );
        }
      }
    },
  );
}
