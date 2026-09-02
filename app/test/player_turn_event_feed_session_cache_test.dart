import 'package:colonizethis_app/features/game/flame/map_state/player_turn_event_feed_session_cache.dart';
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();
  tearDown(PlayerTurnEventFeedSessionCache.clear);

  test('invalidateForTurnCommit clears formatted rows but keeps badge count', () {
    PlayerTurnEventFeedSessionCache.storeFormatted(
      gameId: 'g1',
      committedTurnNumber: 3,
      entries: const [
        PlayerTurnEventFeedEntry(text: 'Research complete.'),
      ],
      badgeCount: 1,
    );

    PlayerTurnEventFeedSessionCache.invalidateForTurnCommit(
      gameId: 'g1',
      committedTurnNumber: 4,
      badgeCount: 2,
    );

    expect(
      PlayerTurnEventFeedSessionCache.readFormatted(
        gameId: 'g1',
        committedTurnNumber: 4,
      ),
      isNull,
    );
    expect(
      PlayerTurnEventFeedSessionCache.readBadgeCount(
        gameId: 'g1',
        committedTurnNumber: 4,
        fallbackCount: 0,
      ),
      2,
    );
  });

  test('storeFormatted reuses entries until next invalidate', () {
    const entries = [
      PlayerTurnEventFeedEntry(text: 'Market: bought £10.'),
    ];
    PlayerTurnEventFeedSessionCache.storeFormatted(
      gameId: 'g1',
      committedTurnNumber: 5,
      entries: entries,
      badgeCount: 1,
    );

    expect(
      PlayerTurnEventFeedSessionCache.readFormatted(
        gameId: 'g1',
        committedTurnNumber: 5,
      ),
      entries,
    );
    expect(
      PlayerTurnEventFeedSessionCache.readFormatted(
        gameId: 'g2',
        committedTurnNumber: 5,
      ),
      isNull,
    );
  });
}
