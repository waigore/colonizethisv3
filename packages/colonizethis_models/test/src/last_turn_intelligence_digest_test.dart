import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/minimal_game.dart';

void main() {
  group('LastTurnIntelligenceDigest', () {
    const digest = LastTurnIntelligenceDigest(
      resolvedTurnNumber: 4,
      worldLines: [
        IntelligenceWorldLine(
          kind: IntelligenceWorldKind.war,
          factionIdA: 'a',
          factionIdB: 'b',
        ),
      ],
      spyReportsByObserverId: {
        'h': [
          IntelligenceSpyCourtBlock(
            courtFactionId: 'f',
            lines: [
              IntelligenceSpyLine(
                kind: IntelligenceSpyKind.researchComplete,
                techId: 'crop_rotation',
                fromFactionId: 'f',
              ),
            ],
          ),
        ],
      },
    );

    test('toJson/fromJson round-trips', () {
      expect(LastTurnIntelligenceDigest.fromJson(digest.toJson()), digest);
    });

    test('lineCountForObserver sums world and spy lines', () {
      expect(digest.lineCountForObserver('h'), 2);
      expect(digest.spyLineCountFor('h'), 1);
      expect(digest.lineCountForObserver('other'), 1);
    });

    test('Game JSON omits digest when null and restores when present', () {
      final bare = minimalGame();
      expect(bare.toJson().containsKey('lastTurnIntelligenceDigest'), isFalse);
      expect(Game.fromJson(bare.toJson()).lastTurnIntelligenceDigest, isNull);

      final withDigest = bare.copyWith(lastTurnIntelligenceDigest: digest);
      final round = Game.fromJson(withDigest.toJson());
      expect(round.lastTurnIntelligenceDigest, digest);
    });
  });
}
