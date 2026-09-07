// Table-driven Embassy overlay-shortcut predicate scenarios (Refs #4739).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'explorer_consulate_gate_predicate_fixtures.dart';
// dart format off

void espRunAppliesWhenConsulateHeldNotEmbassy() {expect(embassyShortcutAppliesToMinorTribeProvince(game: ecgGameWith(overtures: const [OvertureState(gpId: ecgPlayerId,targetId: 'tribe1',stage: OvertureStage.tradeConsulate,),],),playerId: ecgPlayerId,provinceOwnerId: 'tribe1',),isTrue,);}

void espRunHidesWhenNoConsulate() {expect(embassyShortcutAppliesToMinorTribeProvince(game: ecgGameWith(),playerId: ecgPlayerId,provinceOwnerId: 'tribe1',),isFalse,);}

void espRunHidesWhenEmbassyHeld() {expect(embassyShortcutAppliesToMinorTribeProvince(game: ecgGameWith(overtures: const [OvertureState(gpId: ecgPlayerId,targetId: 'tribe1',stage: OvertureStage.embassy,),],),playerId: ecgPlayerId,provinceOwnerId: 'tribe1',),isFalse,);}

void espRunHidesWhenAtWar() {expect(embassyShortcutAppliesToMinorTribeProvince(game: ecgGameWith(overtures: const [OvertureState(gpId: ecgPlayerId,targetId: 'tribe1',stage: OvertureStage.tradeConsulate,),],diplomacyRelations: const [DiplomacyRelation(factionId1: ecgPlayerId,factionId2: 'tribe1',state: RelationState.atWar,),],),playerId: ecgPlayerId,provinceOwnerId: 'tribe1',),isFalse,);}

void espRunHidesGpOwnedAndOwnAndNull() {final game = ecgGameWith(overtures: const [OvertureState(gpId: ecgPlayerId,targetId: 'gp2',stage: OvertureStage.tradeConsulate,),],); expect(embassyShortcutAppliesToMinorTribeProvince(game: game,playerId: ecgPlayerId,provinceOwnerId: 'gp2',),isFalse,); expect(embassyShortcutAppliesToMinorTribeProvince(game: game,playerId: ecgPlayerId,provinceOwnerId: ecgPlayerId,),isFalse,); expect(embassyShortcutAppliesToMinorTribeProvince(game: game,playerId: ecgPlayerId,provinceOwnerId: null,),isFalse,);}

List<RunnableScenario> embassyShortcutPredicateScenarios() => [
  rs('applies when Consulate is held and Embassy is not', espRunAppliesWhenConsulateHeldNotEmbassy, '#4739'),
  rs('hides when Consulate is missing', espRunHidesWhenNoConsulate, '#4739'),
  rs('hides when Embassy or higher is already held', espRunHidesWhenEmbassyHeld, '#4739'),
  rs('hides when the pair is at war', espRunHidesWhenAtWar, '#4739'),
  rs('hides GP-owned, own, and null-owner provinces', espRunHidesGpOwnedAndOwnAndNull, '#4739'),
];
