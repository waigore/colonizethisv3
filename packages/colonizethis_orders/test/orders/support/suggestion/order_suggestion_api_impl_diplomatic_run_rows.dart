// Scenario run tear-offs for order_suggestion_api_impl_diplomatic (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';
import 'order_suggestion_api_impl_diplomatic_fixtures.dart';

const _api = DefaultOrderSuggestionAPI();
const _emptyOrders = Orders();

List<DiplomaticOrder> _suggestFor(Game game) => _api.suggestDiplomaticOrders(
  diplomaticApiImplViewFor(game),
  game,
  diplomaticApiImplTopology,
  _emptyOrders,
);

void osaidRunReturnsAllianceSingleDiploPerTarget() {
  final list = _suggestFor(
    diplomaticApiImplGame(
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          state: RelationState.atPeace,
          level: RelationLevel.neutral,
        ),
      ],
    ),
  );
  final toGp2 = list.where((o) => o.targetFactionId == 'gp2').toList();
  expect(toGp2, hasLength(1));
  expect(toGp2.single.type, DiplomaticOrderType.alliance);
}

void osaidRunReturnsDeclareWarWhenAllied() {
  final list = _suggestFor(
    diplomaticApiImplGame(
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          state: RelationState.atPeace,
          level: RelationLevel.allied,
        ),
      ],
    ),
  );
  final toGp2 = list.where((o) => o.targetFactionId == 'gp2').toList();
  expect(toGp2, hasLength(1));
  expect(toGp2.single.type, DiplomaticOrderType.declareWar);
}

void osaidRunReturnsBreakAllianceWhenFormalAllianceExists() {
  final list = _suggestFor(
    diplomaticApiImplGame(
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          state: RelationState.atPeace,
          level: RelationLevel.allied,
          formalAlliance: true,
        ),
      ],
    ),
  );
  final toGp2 = list.where((o) => o.targetFactionId == 'gp2').toList();
  expect(toGp2, hasLength(1));
  expect(toGp2.single.type, DiplomaticOrderType.breakAlliance);
  final eng = OrderEngine();
  expect(
    eng
        .addDiplomaticOrderWithContext(
          diplomaticApiImplGame(
            diplomacyRelations: const [
              DiplomacyRelation(
                factionId1: 'gp1',
                factionId2: 'gp2',
                state: RelationState.atPeace,
                level: RelationLevel.allied,
                formalAlliance: true,
              ),
            ],
          ),
          diplomaticApiImplTopology,
          'gp1',
          toGp2.single,
        )
        .isAccepted,
    isTrue,
  );
}

void osaidRunDoesNotReturnAllianceWhenFormalAllianceExists() {
  final list = _suggestFor(
    diplomaticApiImplGame(
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          state: RelationState.atPeace,
          level: RelationLevel.allied,
          formalAlliance: true,
        ),
      ],
    ),
  );
  expect(
    list.where(
      (o) =>
          o.type == DiplomaticOrderType.alliance && o.targetFactionId == 'gp2',
    ),
    isEmpty,
  );
}

void osaidRunDoesNotReturnBreakAllianceWithoutFormalAlliance() {
  final list = _suggestFor(
    diplomaticApiImplGame(
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          state: RelationState.atPeace,
          level: RelationLevel.allied,
        ),
      ],
    ),
  );
  expect(
    list.where((o) => o.type == DiplomaticOrderType.breakAlliance),
    isEmpty,
  );
}

void osaidRunReturnsOfferPeaceWhenAtWar() {
  final list = _suggestFor(
    diplomaticApiImplGame(
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          state: RelationState.atWar,
          level: RelationLevel.hostile,
        ),
      ],
    ),
  );
  final offerPeace = list
      .where((o) => o.type == DiplomaticOrderType.offerPeace)
      .toList();
  expect(offerPeace.any((o) => o.targetFactionId == 'gp2'), isTrue);
}

void osaidRunReturnsAllianceCandidateWhenAtPeace() {
  final list = _suggestFor(
    diplomaticApiImplGame(
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          state: RelationState.atPeace,
          level: RelationLevel.friendly,
        ),
      ],
    ),
  );
  final alliance = list
      .where((o) => o.type == DiplomaticOrderType.alliance)
      .toList();
  expect(alliance.any((o) => o.targetFactionId == 'gp2'), isTrue);
}
