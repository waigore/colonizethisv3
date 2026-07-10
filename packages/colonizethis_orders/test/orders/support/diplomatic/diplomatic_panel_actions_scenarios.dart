// Table-driven diplomatic panel action scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'diplomatic_panel_actions_run_rows.dart';

class DiplomaticPanelActionCandidatesScenario implements RefsScenario {
  const DiplomaticPanelActionCandidatesScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

class DiplomaticPanelEnumerateScenario implements RefsScenario {
  const DiplomaticPanelEnumerateScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runDiplomaticPanelActionCandidatesScenario(
  DiplomaticPanelActionCandidatesScenario scenario,
) {
  scenario.run();
}

void runDiplomaticPanelEnumerateScenario(
  DiplomaticPanelEnumerateScenario scenario,
) {
  scenario.run();
}

List<DiplomaticPanelActionCandidatesScenario>
    diplomaticPanelActionCandidatesScenarios() => const [
          DiplomaticPanelActionCandidatesScenario(
            label: 'GP row includes alliance, FTP, and four overture stages',
            run: dpacRunGpRowIncludesAllianceFtpOvertureStages,
          ),
          DiplomaticPanelActionCandidatesScenario(
            label: 'AC11/AC1: formal alliance (e.g. debug /set_diplomacy alliance) swaps alliance for breakAlliance only',
            run: dpacRunFormalAllianceSwapsAllianceForBreakAllianceOnly,
          ),
          DiplomaticPanelActionCandidatesScenario(
            label: 'Minor row omits alliance and FTP',
            run: dpacRunMinorRowOmitsAllianceFtp,
          ),
          DiplomaticPanelActionCandidatesScenario(
            label: 'GP row includes boycott + revoke boycott (Refs #3753 S14)',
            run: dpacRunGpRowIncludesBoycottRevokeBoycott,
            refs: '#3753 S14',
          ),
          DiplomaticPanelActionCandidatesScenario(
            label: 'Minor/Tribe row omits boycott + revoke boycott (Refs #3753 S14)',
            run: dpacRunMinorTribeRowOmitsBoycottRevokeBoycott,
            refs: '#3753 S14',
          ),
        ];

List<DiplomaticPanelEnumerateScenario> diplomaticPanelEnumerateScenarios() =>
    const [
      DiplomaticPanelEnumerateScenario(
        label: 'AC-6: minor at none shows all overture stages; only consulate enabled',
        run: dpeRunMinorAtNoneShowsOvertureStagesConsulateEnabled,
      ),
      DiplomaticPanelEnumerateScenario(
        label: 'S14: boycott disabled when human holds no colony',
        run: dpeRunBoycottDisabledWhenNoColony,
        refs: '#3753 S14',
      ),
      DiplomaticPanelEnumerateScenario(
        label: 'S14: boycott enabled when human holds a colony at peace',
        run: dpeRunBoycottEnabledWhenColonyAtPeace,
        refs: '#3753 S14',
      ),
      DiplomaticPanelEnumerateScenario(
        label: 'S14: revoke enabled (and boycott disabled) with active boycott',
        run: dpeRunRevokeEnabledWithActiveBoycott,
        refs: '#3753 S14',
      ),
      DiplomaticPanelEnumerateScenario(
        label: 'S14: revoke disabled when no active boycott exists',
        run: dpeRunRevokeDisabledWhenNoActiveBoycott,
        refs: '#3753 S14',
      ),
      DiplomaticPanelEnumerateScenario(
        label: 'post-break cooldown disables alliance with deterministic reason (#3811)',
        run: dpeRunPostBreakCooldownDisablesAlliance,
        refs: '#3811',
      ),
      DiplomaticPanelEnumerateScenario(
        label: 'AC-10: invalid declare war / offer peace still enumerated',
        run: dpeRunInvalidDeclareWarOfferPeaceStillEnumerated,
      ),
    ];
