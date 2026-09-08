import 'package:colonizethis_app/features/game/flame/map_state/last_turn_playback.dart';
import 'package:colonizethis_app_ui_chrome/event_feed/ct_event_feed_text.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetProspect;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  test('Prospect completion is a spatial beat with survey caption', () {
    const event = AppWorkOrderCompletedEvent(
      playerId: 'gp1',
      unitId: 'u1',
      workTarget: kWorkTargetProspect,
      targetTileKey: 'oldWorld|c|3|3',
      provinceId: 'oldWorld|p2',
      turnNumber: 2,
      revealedResourceId: 'iron',
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
          workTargetLabel: 'Prospect',
          workTarget: ev.workTarget,
          prospectFoundDisplayName: 'Iron',
        );
      },
    );
    expect(beats, hasLength(1));
    expect(beats.single.tileKey, 'oldWorld|c|3|3');
    expect(beats.single.caption, 'Lisbon work completed! Prospect found Iron');
  });
}
