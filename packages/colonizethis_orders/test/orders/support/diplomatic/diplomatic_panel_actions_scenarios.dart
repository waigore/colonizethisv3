// Table-driven diplomatic panel action scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'diplomatic_panel_actions_fixtures.dart';
// dart format off

void dpacRunGpRowIncludesAllianceFtpOvertureStages() {final candidates = diplomaticPanelActionCandidates(game: diplomaticPanelActionsBaseGame(),playerId: 'gp1',targetId: 'gp2',); expect(candidates.map((o) => o.type).toSet(),containsAll(<DiplomaticOrderType>{DiplomaticOrderType.declareWar,DiplomaticOrderType.offerPeace,DiplomaticOrderType.alliance,DiplomaticOrderType.establishOverture,DiplomaticOrderType.establishFtp,DiplomaticOrderType.grantAid,DiplomaticOrderType.setSubsidy,}),); expect(candidates.where((o) => o.type == DiplomaticOrderType.establishOverture).map((o) => o.overtureStage).toSet(),equals(kDiplomaticPanelOvertureStages.toSet()),);}

void dpacRunFormalAllianceSwapsAllianceForBreakAllianceOnly() {final candidates = diplomaticPanelActionCandidates(game: diplomaticPanelActionsAlliedGame(),playerId: 'gp1',targetId: 'gp2',); expect(candidates.map((o) => o.type),contains(DiplomaticOrderType.breakAlliance),); expect(candidates.map((o) => o.type),isNot(contains(DiplomaticOrderType.alliance)),);}

void dpacRunMinorRowOmitsAllianceFtp() {final candidates = diplomaticPanelActionCandidates(game: diplomaticPanelActionsBaseGame(),playerId: 'gp1',targetId: 'minor1',); expect(candidates.map((o) => o.type),isNot(contains(DiplomaticOrderType.alliance)),); expect(candidates.map((o) => o.type),isNot(contains(DiplomaticOrderType.establishFtp)),);}

void dpacRunGpRowIncludesBoycottRevokeBoycott() {final candidates = diplomaticPanelActionCandidates(game: diplomaticPanelActionsBaseGame(),playerId: 'gp1',targetId: 'gp2',); expect(candidates.map((o) => o.type).toSet(),containsAll(<DiplomaticOrderType>{DiplomaticOrderType.boycott,DiplomaticOrderType.revokeBoycott,}),);}

void dpacRunMinorTribeRowOmitsBoycottRevokeBoycott() {final candidates = diplomaticPanelActionCandidates(game: diplomaticPanelActionsBaseGame(),playerId: 'gp1',targetId: 'minor1',); expect(candidates.map((o) => o.type),isNot(contains(DiplomaticOrderType.boycott)),); expect(candidates.map((o) => o.type),isNot(contains(DiplomaticOrderType.revokeBoycott)),);}

void dpeRunMinorAtNoneShowsOvertureStagesConsulateEnabled() {final actions = enumerateDiplomaticPanelActionsForTarget(game: diplomaticPanelActionsBaseGame(),topology: diplomaticPanelActionsTopology,playerId: 'gp1',targetId: 'minor1',currentOrders: const Orders(),); final overture = actions.where((a) => a.order.type == DiplomaticOrderType.establishOverture).toList(); expect(overture,hasLength(4)); expect(overture.map((a) => diplomacyOvertureStageShortLabel(a.order.overtureStage!),),containsAll(<String>['Consulate','Embassy','NAP','Join Empire']),); final consulate = overture.firstWhere((a) => a.order.overtureStage == OvertureStage.tradeConsulate,); final embassy = overture.firstWhere((a) => a.order.overtureStage == OvertureStage.embassy,); expect(consulate.enabled,isTrue,reason: consulate.rejectionReason); expect(embassy.enabled,isFalse); expect(embassy.rejectionReason,isNotEmpty);}

void dpeRunBoycottDisabledWhenNoColony() {final boycott = diplomaticPanelActionOfType(diplomaticPanelActionsBaseGame(),'gp2',DiplomaticOrderType.boycott,); expect(boycott.enabled,isFalse); expect(boycott.rejectionReason,isNotEmpty);}

void dpeRunBoycottEnabledWhenColonyAtPeace() {final boycott = diplomaticPanelActionOfType(diplomaticPanelActionsColonyAtPeaceGame(),'gp2',DiplomaticOrderType.boycott,); expect(boycott.enabled,isTrue,reason: boycott.rejectionReason);}

void dpeRunRevokeEnabledWithActiveBoycott() {final game = diplomaticPanelActionsActiveBoycottGame(); final revoke = diplomaticPanelActionOfType(game,'gp2',DiplomaticOrderType.revokeBoycott,); final boycott = diplomaticPanelActionOfType(game,'gp2',DiplomaticOrderType.boycott,); expect(revoke.enabled,isTrue,reason: revoke.rejectionReason); expect(boycott.enabled,isFalse);}

void dpeRunRevokeDisabledWhenNoActiveBoycott() {final revoke = diplomaticPanelActionOfType(diplomaticPanelActionsBaseGame(),'gp2',DiplomaticOrderType.revokeBoycott,); expect(revoke.enabled,isFalse); expect(revoke.rejectionReason,isNotEmpty);}

void dpeRunPostBreakCooldownDisablesAlliance() {final alliance = diplomaticPanelActionOfType(diplomaticPanelActionsAllianceBreakCooldownGame(),'gp2',DiplomaticOrderType.alliance,); expect(alliance.enabled,isFalse); expect(alliance.rejectionReason,kAllianceBreakCooldownRejectionReason);}

void dpeRunInvalidDeclareWarOfferPeaceStillEnumerated() {final actions = enumerateDiplomaticPanelActionsForTarget(game: diplomaticPanelActionsBaseGame(),topology: diplomaticPanelActionsTopology,playerId: 'gp1',targetId: 'gp2',currentOrders: const Orders(),); final offerPeace = actions.firstWhere((a) => a.order.type == DiplomaticOrderType.offerPeace,); final declareWar = actions.firstWhere((a) => a.order.type == DiplomaticOrderType.declareWar,); expect(offerPeace.enabled,isFalse); expect(offerPeace.rejectionReason,isNotEmpty); expect(declareWar.enabled,isTrue,reason: declareWar.rejectionReason);}

List<RunnableScenario> diplomaticPanelActionCandidatesScenarios() => [
  rs('GP row includes alliance, FTP, and four overture stages', dpacRunGpRowIncludesAllianceFtpOvertureStages),
  rs('AC11/AC1: formal alliance (e.g. debug /set_diplomacy alliance) swaps alliance for breakAlliance only', dpacRunFormalAllianceSwapsAllianceForBreakAllianceOnly),
  rs('Minor row omits alliance and FTP', dpacRunMinorRowOmitsAllianceFtp),
  rs('GP row includes boycott + revoke boycott (Refs #3753 S14)', dpacRunGpRowIncludesBoycottRevokeBoycott, '#3753 S14'),
  rs('Minor/Tribe row omits boycott + revoke boycott (Refs #3753 S14)', dpacRunMinorTribeRowOmitsBoycottRevokeBoycott, '#3753 S14'),
];

List<RunnableScenario> diplomaticPanelEnumerateScenarios() => [
  rs('AC-6: minor at none shows all overture stages; only consulate enabled', dpeRunMinorAtNoneShowsOvertureStagesConsulateEnabled),
  rs('S14: boycott disabled when human holds no colony', dpeRunBoycottDisabledWhenNoColony, '#3753 S14'),
  rs('S14: boycott enabled when human holds a colony at peace', dpeRunBoycottEnabledWhenColonyAtPeace, '#3753 S14'),
  rs('S14: revoke enabled (and boycott disabled) with active boycott', dpeRunRevokeEnabledWithActiveBoycott, '#3753 S14'),
  rs('S14: revoke disabled when no active boycott exists', dpeRunRevokeDisabledWhenNoActiveBoycott, '#3753 S14'),
  rs('post-break cooldown disables alliance with deterministic reason (#3811)', dpeRunPostBreakCooldownDisablesAlliance, '#3811'),
  rs('AC-10: invalid declare war / offer peace still enumerated', dpeRunInvalidDeclareWarOfferPeaceStillEnumerated),
];
