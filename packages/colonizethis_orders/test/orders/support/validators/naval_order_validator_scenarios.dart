// Table-driven NavalOrderValidator scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'naval_order_validator_run_rows.dart';

/// One row in [navalMoveValidatorScenarios] / [navalMissionValidatorScenarios].
class NavalOrderValidatorScenario implements RefsScenario {
  const NavalOrderValidatorScenario({
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

void runNavalOrderValidatorScenario(NavalOrderValidatorScenario scenario) =>
    scenario.run();

/// Canonical scenarios for `validateNavalMove` family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] (single-line `label:` for CI).
List<NavalOrderValidatorScenario> navalMoveValidatorScenarios() => [
  NavalOrderValidatorScenario(
    label: 'validateNavalMove rejects when previousRejected',
    run: novRunValidateNavalMoveRejectsWhenPreviousRejected,
  ),
  NavalOrderValidatorScenario(
    label: 'validateNavalMove rejects when fleet not found',
    run: novRunValidateNavalMoveRejectsWhenFleetNotFound,
  ),
  NavalOrderValidatorScenario(
    label: 'validateNavalMove rejects when fleet not owned by player',
    run: novRunValidateNavalMoveRejectsWhenFleetNotOwnedByPlayer,
  ),
  NavalOrderValidatorScenario(
    label: 'validateNavalMove rejects when home fleet',
    run: novRunValidateNavalMoveRejectsWhenHomeFleet,
  ),
  NavalOrderValidatorScenario(
    label: 'validateNavalMove accept move to adjacent sea zone when at sea',
    run: novRunValidateNavalMoveAcceptMoveToAdjacentSeaZoneWhenAtSea,
  ),
  NavalOrderValidatorScenario(
    label: 'validateNavalMove reject move to non-adjacent sea zone',
    run: novRunValidateNavalMoveRejectMoveToNonAdjacentSeaZone,
  ),
  NavalOrderValidatorScenario(
    label:
        'validateNavalMove dock reject when sea zone not adjacent to province',
    run: novRunValidateNavalMoveDockRejectWhenSeaZoneNotAdjacentToProvince,
  ),
  NavalOrderValidatorScenario(
    label: 'validateNavalMove accept undock from port to adjacent sea zone',
    run: novRunValidateNavalMoveAcceptUndockFromPortToAdjacentSeaZone,
  ),
  NavalOrderValidatorScenario(
    label:
        'validateNavalMove at sea rejects province id as destinationSeaZoneId',
    run: novRunValidateNavalMoveAtSeaRejectsProvinceIdAsDestinationSeaZoneId,
  ),
  NavalOrderValidatorScenario(
    label:
        'validateNavalMove in-port accepts any sea with direct P–S edge to port',
    run: novRunValidateNavalMoveInPortAcceptsAnySeaWithDirectPsEdgeToPort,
  ),
  NavalOrderValidatorScenario(
    label:
        'validateNavalMove in-port rejects sea only reachable via S–S from port sea',
    run: novRunValidateNavalMoveInPortRejectsSeaOnlyReachableViaSsFromPortSea,
  ),
  NavalOrderValidatorScenario(
    label: 'validateNavalMove reject when in port but inPortAtProvinceId null',
    run: novRunValidateNavalMoveRejectWhenInPortButInPortAtProvinceIdNull,
  ),
  NavalOrderValidatorScenario(
    label: 'validateNavalMove dock accept when at sea adjacent owned province',
    run: novRunValidateNavalMoveDockAcceptWhenAtSeaAdjacentOwnedProvince,
  ),
  NavalOrderValidatorScenario(
    label:
        'validateNavalMove dock accept when port province id is local (unprefixed)',
    run: novRunValidateNavalMoveDockAcceptWhenPortProvinceIdIsLocalUnprefixed,
  ),
  NavalOrderValidatorScenario(
    label: 'validateNavalMove dock reject when fleet in port',
    run: novRunValidateNavalMoveDockRejectWhenFleetInPort,
  ),
  NavalOrderValidatorScenario(
    label: 'validateNavalMove dock reject when port province not owned',
    run: novRunValidateNavalMoveDockRejectWhenPortProvinceNotOwned,
  ),
  NavalOrderValidatorScenario(
    label: 'validateNavalMove dock reject when port province not found',
    run: novRunValidateNavalMoveDockRejectWhenPortProvinceNotFound,
  ),
];

/// Canonical scenarios for `validateNavalMission` family tests.
List<NavalOrderValidatorScenario> navalMissionValidatorScenarios() => [
  NavalOrderValidatorScenario(
    label: 'validateNavalMission rejects when previousRejected',
    run: novRunValidateNavalMissionRejectsWhenPreviousRejected,
  ),
  NavalOrderValidatorScenario(
    label: 'validateNavalMission blockade requires target province',
    run: novRunValidateNavalMissionBlockadeRequiresTargetProvince,
  ),
  NavalOrderValidatorScenario(
    label: 'validateNavalMission blockade reject when target not prefixed',
    run: novRunValidateNavalMissionBlockadeRejectWhenTargetNotPrefixed,
  ),
  NavalOrderValidatorScenario(
    label: 'validateNavalMission blockade reject when blockading own province',
    run: novRunValidateNavalMissionBlockadeRejectWhenBlockadingOwnProvince,
  ),
  NavalOrderValidatorScenario(
    label:
        'validateNavalMission accept non-blockade mission when fleet at sea',
    run: novRunValidateNavalMissionAcceptNonBlockadeMissionWhenFleetAtSea,
  ),
];
