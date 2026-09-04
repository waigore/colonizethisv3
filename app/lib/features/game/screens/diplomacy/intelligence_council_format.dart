// Display-name formatters for GAME30003. SPEC/ui/intelligence-council.md.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../diplomacy/diplomacy_detail_screen_format.dart';

String intelligenceFactionLabel(Game game, String id) =>
    game.factionDisplayNameById(id) ?? id;

String intelligenceProvinceLabel(Game game, String fullProvinceId) =>
    game.worldState.tryGetProvince(fullProvinceId)?.displayName ??
    fullProvinceId;

String intelligenceSeaZoneLabel(Game game, String seaZoneId) =>
    game.worldState.seaZoneDisplayNameById[seaZoneId] ?? seaZoneId;

String formatIntelligenceWorldLine(
  AppLocalizations l10n,
  Game game,
  IntelligenceWorldLine line,
) {
  return switch (line.kind) {
    IntelligenceWorldKind.provinceCaptured => l10n.turnNews_capture(
      intelligenceProvinceLabel(game, line.provinceId ?? ''),
      intelligenceFactionLabel(game, line.factionIdA ?? ''),
      intelligenceFactionLabel(game, line.factionIdB ?? ''),
    ),
    IntelligenceWorldKind.war => l10n.turnNews_war(
      intelligenceFactionLabel(game, line.factionIdA ?? ''),
      intelligenceFactionLabel(game, line.factionIdB ?? ''),
    ),
    IntelligenceWorldKind.peace => l10n.turnNews_peace(
      intelligenceFactionLabel(game, line.factionIdA ?? ''),
      intelligenceFactionLabel(game, line.factionIdB ?? ''),
    ),
    IntelligenceWorldKind.allianceFormed => l10n.intelligence_allianceFormed(
      intelligenceFactionLabel(game, line.factionIdA ?? ''),
      intelligenceFactionLabel(game, line.factionIdB ?? ''),
    ),
    IntelligenceWorldKind.allianceBroken => l10n.intelligence_allianceBroken(
      intelligenceFactionLabel(game, line.factionIdA ?? ''),
      intelligenceFactionLabel(game, line.factionIdB ?? ''),
    ),
    IntelligenceWorldKind.overtureAdvanced => l10n.turnNews_overture(
      intelligenceFactionLabel(game, line.factionIdA ?? ''),
      intelligenceFactionLabel(game, line.factionIdB ?? ''),
      _overtureStageLabel(l10n, line.overtureStage ?? OvertureStage.none),
    ),
    IntelligenceWorldKind.provinceDiscovered =>
      l10n.turnNews_provinceDiscovered(
        intelligenceProvinceLabel(game, line.provinceId ?? ''),
      ),
    IntelligenceWorldKind.seaZoneFleet => l10n.turnNews_seaDiscovered(
      intelligenceSeaZoneLabel(game, line.seaZoneId ?? ''),
    ),
  };
}

String formatIntelligenceSpyFact(
  AppLocalizations l10n,
  Game game,
  String courtId,
  IntelligenceSpyLine line,
) {
  final court = intelligenceFactionLabel(game, courtId);
  return switch (line.kind) {
    IntelligenceSpyKind.diplomatic => _diplomaticFact(game, line),
    IntelligenceSpyKind.captureMade => l10n.intelligence_spyCaptureMade(
      court,
      intelligenceProvinceLabel(game, line.provinceId ?? ''),
      intelligenceFactionLabel(game, line.fromFactionId ?? ''),
    ),
    IntelligenceSpyKind.captureLost => l10n.intelligence_spyCaptureLost(
      court,
      intelligenceProvinceLabel(game, line.provinceId ?? ''),
      intelligenceFactionLabel(game, line.toFactionId ?? ''),
    ),
    IntelligenceSpyKind.researchComplete => l10n.intelligence_spyResearch(
      court,
      techDisplayName(line.techId ?? ''),
    ),
    IntelligenceSpyKind.combat => l10n.intelligence_spyCombat(
      court,
      intelligenceProvinceLabel(game, line.provinceId ?? ''),
    ),
    IntelligenceSpyKind.navalCombat => l10n.intelligence_spyNaval(
      court,
      intelligenceSeaZoneLabel(game, line.seaZoneId ?? ''),
    ),
  };
}

String formatIntelligenceSpyLine(
  AppLocalizations l10n,
  Game game,
  String _,
  String courtId,
  IntelligenceSpyLine line,
) {
  return l10n.intelligence_spyPrefix(
    intelligenceFactionLabel(game, courtId),
    formatIntelligenceSpyFact(l10n, game, courtId, line),
  );
}

String _diplomaticFact(Game game, IntelligenceSpyLine line) {
  final from = intelligenceFactionLabel(game, line.fromFactionId ?? '');
  final to = intelligenceFactionLabel(game, line.toFactionId ?? '');
  final stage = line.overtureStage != null
      ? overtureLabel(line.overtureStage!)
      : 'overture';
  return switch (line.diplomaticType ?? DiplomaticEventType.declareWar) {
    DiplomaticEventType.declareWar => '$from declared war on $to.',
    DiplomaticEventType.peace => '$from made peace with $to.',
    DiplomaticEventType.allianceFormed => '$from formed an alliance with $to.',
    DiplomaticEventType.allianceBroken =>
      'Alliance between $from and $to ended.',
    DiplomaticEventType.overtureAccepted =>
      '$from established $stage with $to.',
    DiplomaticEventType.overtureRejected => '$to rejected $stage from $from.',
    DiplomaticEventType.joinEmpireResolved => formatJoinEmpireResolvedSentence(
      game: game,
      fromLabel: from,
      toLabel: to,
      toFactionId: line.toFactionId,
    ),
    DiplomaticEventType.grantAidApplied =>
      '$from granted £${line.amount ?? 0} aid to $to.',
    DiplomaticEventType.subsidySet =>
      '$from set subsidy of ${line.amount ?? 0}% to $to.',
    DiplomaticEventType.subsidyUpdated =>
      '$from updated subsidy to ${line.amount ?? 0}% to $to.',
    DiplomaticEventType.subsidyCancelled => 'Subsidy $from → $to ended.',
    DiplomaticEventType.boycottSet => '$from began a boycott against $to.',
    DiplomaticEventType.boycottRevoked => 'Boycott by $from against $to ended.',
    DiplomaticEventType.interventionIntervene =>
      '$from intervened in war (against $to).',
    DiplomaticEventType.interventionDoNothing =>
      '$from did not intervene (against $to).',
    DiplomaticEventType.interventionProtest => '$from protested (against $to).',
    DiplomaticEventType.agreementsClearedOnWar =>
      'Overtures between $from and $to ended due to war.',
    DiplomaticEventType.callToArmsAccepted =>
      '$from joined the war against $to (call to arms).',
    DiplomaticEventType.callToArmsRefused =>
      '$from refused call to arms; alliance with $to ended.',
    DiplomaticEventType.ftpFormed =>
      '$from established a free trade partnership with $to.',
    DiplomaticEventType.ftpBroken =>
      'Free trade partnership between $from and $to ended.',
  };
}

String _overtureStageLabel(AppLocalizations l10n, OvertureStage s) {
  return switch (s) {
    OvertureStage.tradeConsulate => l10n.turnNews_stage_tradeConsulate,
    OvertureStage.embassy => l10n.turnNews_stage_embassy,
    OvertureStage.nap => l10n.turnNews_stage_nap,
    OvertureStage.joinEmpire => l10n.turnNews_stage_joinEmpire,
    OvertureStage.none => s.name,
  };
}
