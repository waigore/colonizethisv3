// formatDiplomaticEvent — joinEmpireResolved absorb vs colony (Refs #4729).
import 'package:colonizethis_app/features/game/screens/diplomacy/diplomacy_detail_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'support/diplomacy_format_diplomatic_event_fixtures.dart';

void main() {
  suppressLogsForTests();

  test('joinEmpireResolved absorbs GP or Minor', () {
    final g = diplomacyFormatMinimalGame();
    final s = formatDiplomaticEvent(
      diplomacyFormatEvent(DiplomaticEventType.joinEmpireResolved),
      g,
      diplomacyFormatHumanId,
    );
    expect(s, contains('absorbed'));
    expect(s.toLowerCase(), contains('land'));
    expect(s.toLowerCase(), contains('armies'));
    expect(s.toLowerCase(), contains('fleets'));
  });

  test('joinEmpireResolved tribe colony does not say absorbed', () {
    const tribeId = 'tribe_aztec';
    final g = Game(
      id: 'fmt-colony',
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      turnTimeMapping: TurnTimeMapping.gdd01,
      players: const [
        Player(
          id: diplomacyFormatHumanId,
          displayName: 'England',
          isHuman: true,
          treasury: 0,
        ),
      ],
      tribes: const [Tribe(id: tribeId, displayName: 'Aztec')],
      colonyStates: const [
        ColonyState(tribeId: tribeId, colonyOfGpId: diplomacyFormatHumanId, sinceTurn: 1),
      ],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: diplomacyFormatHumanId,
          factionId2: tribeId,
          score: 80,
          state: RelationState.atPeace,
        ),
      ],
    );
    final s = formatDiplomaticEvent(
      diplomacyFormatEvent(
        DiplomaticEventType.joinEmpireResolved,
        toId: tribeId,
      ),
      g,
      diplomacyFormatHumanId,
    );
    expect(s.toLowerCase(), contains('colony'));
    expect(s.toLowerCase(), contains('land stayed theirs'));
    expect(s.toLowerCase(), isNot(contains('absorbed')));
  });
}
