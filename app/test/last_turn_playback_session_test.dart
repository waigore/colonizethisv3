import 'package:colonizethis_app/features/game/flame/map_state/last_turn_playback.dart';
import 'package:colonizethis_app/features/game/flame/map_state/last_turn_playback_session.dart';
import 'package:colonizethis_test/test.dart';

LastTurnPlaybackBeat _beat({
  required String tileKey,
  required String regionId,
  String caption = 'beat',
}) {
  return LastTurnPlaybackBeat(
    tileKey: tileKey,
    regionId: regionId,
    caption: caption,
  );
}

void main() {
  final sample = [
    _beat(tileKey: 'oldWorld|p1|0|0', regionId: 'oldWorld', caption: 'fight'),
    _beat(tileKey: 'newWorld|sz|1|1', regionId: 'newWorld', caption: 'naval'),
  ];

  group('lastTurnPlaybackStartGate', () {
    test('victory set waits for View final state even if news would show', () {
      expect(
        lastTurnPlaybackStartGate(newsDialogWillShow: true, victorySet: true),
        LastTurnPlaybackStartGate.victoryDismiss,
      );
    });

    test('news without victory waits for DLG50001 close', () {
      expect(
        lastTurnPlaybackStartGate(newsDialogWillShow: true, victorySet: false),
        LastTurnPlaybackStartGate.newsClose,
      );
    });

    test('neither modal starts immediately', () {
      expect(
        lastTurnPlaybackStartGate(newsDialogWillShow: false, victorySet: false),
        LastTurnPlaybackStartGate.immediate,
      );
    });
  });

  group('LastTurnPlaybackSession', () {
    test('news close starts playback; victory dismiss does not', () {
      final session = LastTurnPlaybackSession()
        ..arm(newsDialogWillShow: true, victorySet: false);
      expect(session.blockedByStartGate, isTrue);
      expect(session.tryBegin(sample), isFalse);
      expect(session.onVictoryDismissed(), isFalse);
      expect(session.onNewsClosed(), isTrue);
      expect(session.tryBegin(sample), isTrue);
      expect(session.currentBeat?.tileKey, 'oldWorld|p1|0|0');
    });

    test('victory dismiss starts playback; news close does not', () {
      final session = LastTurnPlaybackSession()
        ..arm(newsDialogWillShow: true, victorySet: true);
      expect(session.gate, LastTurnPlaybackStartGate.victoryDismiss);
      expect(session.tryBegin(sample), isFalse);
      expect(session.onNewsClosed(), isFalse);
      expect(session.onVictoryDismissed(), isTrue);
      expect(session.tryBegin(sample), isTrue);
      expect(session.active, isTrue);
    });

    test('empty spatial batch does not pan or pulse', () {
      final session = LastTurnPlaybackSession()
        ..arm(newsDialogWillShow: false, victorySet: false);
      expect(session.tryBegin(const []), isFalse);
      expect(session.active, isFalse);
      expect(session.pending, isFalse);
      expect(session.currentBeat, isNull);
    });

    test('advancing switches regionId then skip ends immediately', () {
      final session = LastTurnPlaybackSession()
        ..arm(newsDialogWillShow: false, victorySet: false);
      expect(session.tryBegin(sample), isTrue);
      expect(session.currentBeat?.regionId, 'oldWorld');
      expect(session.advanceAfterDwell(), isTrue);
      expect(session.currentBeat?.regionId, 'newWorld');
      session.skip();
      expect(session.active, isFalse);
      expect(session.pending, isFalse);
      expect(session.currentBeat, isNull);
    });

    test('dwell after last beat stops the sequence', () {
      final session = LastTurnPlaybackSession()
        ..arm(newsDialogWillShow: false, victorySet: false);
      expect(session.tryBegin([sample.first]), isTrue);
      expect(session.advanceAfterDwell(), isFalse);
      expect(session.active, isFalse);
    });

    test('news closed when not pending is ignored', () {
      final session = LastTurnPlaybackSession();
      expect(session.onNewsClosed(), isFalse);
      expect(session.onVictoryDismissed(), isFalse);
    });
  });
}
