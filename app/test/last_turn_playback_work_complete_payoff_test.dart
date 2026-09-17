import 'package:colonizethis_app/features/game/flame/map_state/last_turn_playback.dart';
import 'package:colonizethis_app_ui_chrome/event_feed/ct_event_feed_text.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  test('Explore completion caption matches feed payoff line (Refs #4778)', () {
    const event = AppWorkOrderCompletedEvent(
      playerId: 'gp1',
      unitId: 'u1',
      workTarget: CtEventFeedText.exploreWorkTarget,
      targetTileKey: 'oldWorld|c|3|3',
      provinceId: 'oldWorld|p2',
      turnNumber: 2,
      payoffKind: WorkOrderPayoffKind.fullyVisible,
    );
    final beats = buildLastTurnPlaybackBeats(
      events: const [event],
      resolveAnchor: (e) {
        if (e is AppWorkOrderCompletedEvent) {
          return (tileKey: e.targetTileKey, regionId: 'oldWorld');
        }
        return null;
      },
      captionFor: (e) {
        final ev = e as AppWorkOrderCompletedEvent;
        return CtEventFeedText.workOrderCompletedLine(
          provinceLabel: 'Lisbon',
          workTargetLabel: 'Explore',
          workTarget: ev.workTarget,
          payoffKind: ev.payoffKind,
        );
      },
    );
    expect(beats, hasLength(1));
    expect(
      beats.single.caption,
      'Lisbon work completed! This province is now fully visible.',
    );
    expect(beats.single.caption, isNot(contains('Explore finished!')));
  });
}
