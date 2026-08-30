// Development Counsel apply helper. SPEC/ui/counsel-panel.md (Refs #4332).

import 'package:colonizethis_app/features/game/screens/counsel/counsel_development_apply.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  test('returns null when no matching build_port suggestion', () {
    final game = Game(
      id: 'g',
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: const [
        Player(id: 'gp1', displayName: 'GP', isHuman: true),
      ],
    );
    const rec = DevelopmentCounselRecommendation(
      recommendationId: 'build_port:oldWorld|P1|0|0',
      kind: DevelopmentCounselRecommendationKind.buildPort,
      rankScore: 110,
      briefReasonKey: DevelopmentCounselReasonKey.coastalPort,
      detailReasonKeys: [DevelopmentCounselReasonKey.coastalPort],
      isHighlight: true,
      targetTileKey: 'oldWorld|P1|0|0',
      provinceId: 'oldWorld|P1',
    );
    final order = developmentCounselPortWorkOrderAfterAgree(
      game: game,
      playerId: 'gp1',
      currentOrders: const Orders(),
      topology: const MapTopology(),
      recommendation: rec,
    );
    expect(order, isNull);
  });
}
