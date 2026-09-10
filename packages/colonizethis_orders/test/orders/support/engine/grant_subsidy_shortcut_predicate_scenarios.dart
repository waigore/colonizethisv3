// Table-driven Grant Aid / Set Subsidy overlay-shortcut predicates (Refs #4761).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'explorer_consulate_gate_predicate_fixtures.dart';
// dart format off

bool _applies({required Game game, String? ownerId}) =>
    grantSubsidyShortcutAppliesToMinorTribeProvince(
      game: game,
      playerId: ecgPlayerId,
      provinceOwnerId: ownerId,
    );

void gssRunAppliesWhenEmbassyHeld() {expect(_applies(game: ecgGameWith(overtures: const [OvertureState(gpId: ecgPlayerId,targetId: 'tribe1',stage: OvertureStage.embassy,),],),ownerId: 'tribe1',),isTrue,);}

void gssRunAppliesWhenNapOrJoinEmpire() {expect(_applies(game: ecgGameWith(overtures: const [OvertureState(gpId: ecgPlayerId,targetId: 'tribe1',stage: OvertureStage.nap,),],),ownerId: 'tribe1',),isTrue,); expect(_applies(game: ecgGameWith(overtures: const [OvertureState(gpId: ecgPlayerId,targetId: 'tribe1',stage: OvertureStage.joinEmpire,),],),ownerId: 'tribe1',),isTrue,);}

void gssRunHidesWhenNoEmbassy() {expect(_applies(game: ecgGameWith(),ownerId: 'tribe1',),isFalse,); expect(_applies(game: ecgGameWith(overtures: const [OvertureState(gpId: ecgPlayerId,targetId: 'tribe1',stage: OvertureStage.tradeConsulate,),],),ownerId: 'tribe1',),isFalse,);}

void gssRunHidesWhenAtWar() {expect(_applies(game: ecgGameWith(overtures: const [OvertureState(gpId: ecgPlayerId,targetId: 'tribe1',stage: OvertureStage.embassy,),],diplomacyRelations: const [DiplomacyRelation(factionId1: ecgPlayerId,factionId2: 'tribe1',state: RelationState.atWar,),],),ownerId: 'tribe1',),isFalse,);}

void gssRunHidesGpOwnedAndOwnAndNull() {final game = ecgGameWith(overtures: const [OvertureState(gpId: ecgPlayerId,targetId: 'gp2',stage: OvertureStage.embassy,),],); expect(_applies(game: game,ownerId: 'gp2',),isFalse,); expect(_applies(game: game,ownerId: ecgPlayerId,),isFalse,); expect(_applies(game: game,ownerId: null,),isFalse,);}

List<RunnableScenario> grantSubsidyShortcutPredicateScenarios() => [
  rs('applies when Embassy is held', gssRunAppliesWhenEmbassyHeld, '#4761'),
  rs('applies when NAP or Join Empire supersedes Embassy', gssRunAppliesWhenNapOrJoinEmpire, '#4761'),
  rs('hides when Embassy is missing', gssRunHidesWhenNoEmbassy, '#4761'),
  rs('hides when the pair is at war', gssRunHidesWhenAtWar, '#4761'),
  rs('hides GP-owned, own, and null-owner provinces', gssRunHidesGpOwnedAndOwnAndNull, '#4761'),
];
