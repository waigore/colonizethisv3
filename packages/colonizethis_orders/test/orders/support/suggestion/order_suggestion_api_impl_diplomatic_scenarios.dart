// Table-driven diplomatic GP API impl suggestion scenarios (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'order_suggestion_api_impl_diplomatic_fixtures.dart';

const _api = DefaultOrderSuggestionAPI();
const _emptyOrders = Orders();

List<DiplomaticOrder> _suggestFor(Game game) => _api.suggestDiplomaticOrders(
  diplomaticApiImplViewFor(game),
  game,
  diplomaticApiImplTopology,
  _emptyOrders,
);
// dart format off

void osaidRunReturnsAllianceSingleDiploPerTarget() {final list = _suggestFor(diplomaticApiImplGame(diplomacyRelations: const [DiplomacyRelation(factionId1: 'gp1',factionId2: 'gp2',state: RelationState.atPeace,level: RelationLevel.neutral,),],),); final toGp2 = list.where((o) => o.targetFactionId == 'gp2').toList(); expect(toGp2,hasLength(1)); expect(toGp2.single.type,DiplomaticOrderType.alliance);}

void osaidRunReturnsDeclareWarWhenAllied() {final list = _suggestFor(diplomaticApiImplGame(diplomacyRelations: const [DiplomacyRelation(factionId1: 'gp1',factionId2: 'gp2',state: RelationState.atPeace,level: RelationLevel.allied,),],),); final toGp2 = list.where((o) => o.targetFactionId == 'gp2').toList(); expect(toGp2,hasLength(1)); expect(toGp2.single.type,DiplomaticOrderType.declareWar);}

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

void osaidRunDoesNotReturnAllianceWhenFormalAllianceExists() {final list = _suggestFor(diplomaticApiImplGame(diplomacyRelations: const [DiplomacyRelation(factionId1: 'gp1',factionId2: 'gp2',state: RelationState.atPeace,level: RelationLevel.allied,formalAlliance: true,),],),); expect(list.where((o) => o.type == DiplomaticOrderType.alliance && o.targetFactionId == 'gp2',),isEmpty,);}

void osaidRunDoesNotReturnBreakAllianceWithoutFormalAlliance() {final list = _suggestFor(diplomaticApiImplGame(diplomacyRelations: const [DiplomacyRelation(factionId1: 'gp1',factionId2: 'gp2',state: RelationState.atPeace,level: RelationLevel.allied,),],),); expect(list.where((o) => o.type == DiplomaticOrderType.breakAlliance),isEmpty,);}

void osaidRunReturnsOfferPeaceWhenAtWar() {final list = _suggestFor(diplomaticApiImplGame(diplomacyRelations: const [DiplomacyRelation(factionId1: 'gp1',factionId2: 'gp2',state: RelationState.atWar,level: RelationLevel.hostile,),],),); final offerPeace = list.where((o) => o.type == DiplomaticOrderType.offerPeace).toList(); expect(offerPeace.any((o) => o.targetFactionId == 'gp2'),isTrue);}

void osaidRunReturnsAllianceCandidateWhenAtPeace() {final list = _suggestFor(diplomaticApiImplGame(diplomacyRelations: const [DiplomacyRelation(factionId1: 'gp1',factionId2: 'gp2',state: RelationState.atPeace,level: RelationLevel.friendly,),],),); final alliance = list.where((o) => o.type == DiplomaticOrderType.alliance).toList(); expect(alliance.any((o) => o.targetFactionId == 'gp2'),isTrue);}

List<RunnableScenario> orderSuggestionApiImplDiplomaticScenarios() => [
  rs('returns alliance (single diplo per target) for other GP when at peace and not allied', osaidRunReturnsAllianceSingleDiploPerTarget, '#3949'),
  rs('returns declareWar toward GP when at peace and already allied', osaidRunReturnsDeclareWarWhenAllied, '#3949'),
  rs('returns breakAlliance toward GP when a formal alliance exists at peace', osaidRunReturnsBreakAllianceWhenFormalAllianceExists, '#3949'),
  rs('does not return alliance toward a GP when a formal alliance exists', osaidRunDoesNotReturnAllianceWhenFormalAllianceExists, '#3949'),
  rs('does not return breakAlliance when relation level is allied but no formal alliance', osaidRunDoesNotReturnBreakAllianceWithoutFormalAlliance, '#3949'),
  rs('returns offerPeace when at war with another GP', osaidRunReturnsOfferPeaceWhenAtWar, '#3949'),
  rs('returns alliance candidate when at peace and not allied', osaidRunReturnsAllianceCandidateWhenAtPeace, '#3949'),
];
