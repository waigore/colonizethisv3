// Table-driven diplomatic panel action scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'diplomatic_panel_actions_expectations.dart';

class DiplomaticPanelActionCandidatesScenario implements RefsScenario {
  const DiplomaticPanelActionCandidatesScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final DiplomaticPanelActionCandidatesTarget target;
  @override
  final String? refs;
}

class DiplomaticPanelEnumerateScenario implements RefsScenario {
  const DiplomaticPanelEnumerateScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final DiplomaticPanelEnumerateTarget target;
  @override
  final String? refs;
}

void runDiplomaticPanelActionCandidatesScenario(
  DiplomaticPanelActionCandidatesScenario scenario,
) {
  runDiplomaticPanelActionCandidatesExpectation(scenario.target);
}

void runDiplomaticPanelEnumerateScenario(
  DiplomaticPanelEnumerateScenario scenario,
) {
  runDiplomaticPanelEnumerateExpectation(scenario.target);
}

List<DiplomaticPanelActionCandidatesScenario>
    diplomaticPanelActionCandidatesScenarios() => const [
          DiplomaticPanelActionCandidatesScenario(
            label: 'GP row includes alliance, FTP, and four overture stages',
            target: DiplomaticPanelActionCandidatesTarget
                .gpRowIncludesAllianceFtpOvertureStages,
          ),
          DiplomaticPanelActionCandidatesScenario(
            label: 'AC11/AC1: formal alliance (e.g. debug /set_diplomacy alliance) swaps alliance for breakAlliance only',
            target: DiplomaticPanelActionCandidatesTarget
                .formalAllianceSwapsAllianceForBreakAllianceOnly,
          ),
          DiplomaticPanelActionCandidatesScenario(
            label: 'Minor row omits alliance and FTP',
            target: DiplomaticPanelActionCandidatesTarget.minorRowOmitsAllianceFtp,
          ),
          DiplomaticPanelActionCandidatesScenario(
            label: 'GP row includes boycott + revoke boycott (Refs #3753 S14)',
            target: DiplomaticPanelActionCandidatesTarget
                .gpRowIncludesBoycottRevokeBoycott,
            refs: '#3753 S14',
          ),
          DiplomaticPanelActionCandidatesScenario(
            label: 'Minor/Tribe row omits boycott + revoke boycott (Refs #3753 S14)',
            target: DiplomaticPanelActionCandidatesTarget
                .minorTribeRowOmitsBoycottRevokeBoycott,
            refs: '#3753 S14',
          ),
        ];

List<DiplomaticPanelEnumerateScenario> diplomaticPanelEnumerateScenarios() =>
    const [
      DiplomaticPanelEnumerateScenario(
        label: 'AC-6: minor at none shows all overture stages; only consulate enabled',
        target: DiplomaticPanelEnumerateTarget
            .minorAtNoneShowsOvertureStagesConsulateEnabled,
      ),
      DiplomaticPanelEnumerateScenario(
        label: 'S14: boycott disabled when human holds no colony',
        target: DiplomaticPanelEnumerateTarget.boycottDisabledWhenNoColony,
        refs: '#3753 S14',
      ),
      DiplomaticPanelEnumerateScenario(
        label: 'S14: boycott enabled when human holds a colony at peace',
        target: DiplomaticPanelEnumerateTarget.boycottEnabledWhenColonyAtPeace,
        refs: '#3753 S14',
      ),
      DiplomaticPanelEnumerateScenario(
        label: 'S14: revoke enabled (and boycott disabled) with active boycott',
        target: DiplomaticPanelEnumerateTarget.revokeEnabledWithActiveBoycott,
        refs: '#3753 S14',
      ),
      DiplomaticPanelEnumerateScenario(
        label: 'S14: revoke disabled when no active boycott exists',
        target: DiplomaticPanelEnumerateTarget.revokeDisabledWhenNoActiveBoycott,
        refs: '#3753 S14',
      ),
      DiplomaticPanelEnumerateScenario(
        label: 'post-break cooldown disables alliance with deterministic reason (#3811)',
        target: DiplomaticPanelEnumerateTarget.postBreakCooldownDisablesAlliance,
        refs: '#3811',
      ),
      DiplomaticPanelEnumerateScenario(
        label: 'AC-10: invalid declare war / offer peace still enumerated',
        target: DiplomaticPanelEnumerateTarget
            .invalidDeclareWarOfferPeaceStillEnumerated,
      ),
    ];
