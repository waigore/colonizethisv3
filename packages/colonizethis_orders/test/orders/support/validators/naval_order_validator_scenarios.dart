// Table-driven NavalOrderValidator scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'naval_order_validator_expectations.dart';

/// One row in [navalMoveValidatorScenarios] / [navalMissionValidatorScenarios].
class NavalOrderValidatorScenario implements RefsScenario {
  const NavalOrderValidatorScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final NavalOrderValidatorTarget target;
  @override
  final String? refs;
}

void runNavalOrderValidatorScenario(NavalOrderValidatorScenario scenario) {
  runNavalOrderValidatorExpectation(scenario.target);
}

/// Canonical scenarios for `validateNavalMove` family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] (single-line `label:` for CI).
List<NavalOrderValidatorScenario> navalMoveValidatorScenarios() => const [
      NavalOrderValidatorScenario(
        label: 'validateNavalMove rejects when previousRejected',
        target: NavalOrderValidatorTarget.moveRejectsWhenPreviousRejected,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMove rejects when fleet not found',
        target: NavalOrderValidatorTarget.moveRejectsWhenFleetNotFound,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMove rejects when fleet not owned by player',
        target: NavalOrderValidatorTarget.moveRejectsWhenFleetNotOwnedByPlayer,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMove rejects when home fleet',
        target: NavalOrderValidatorTarget.moveRejectsWhenHomeFleet,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMove accept move to adjacent sea zone when at sea',
        target: NavalOrderValidatorTarget.moveAcceptAdjacentSeaZoneWhenAtSea,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMove reject move to non-adjacent sea zone',
        target: NavalOrderValidatorTarget.moveRejectNonAdjacentSeaZone,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMove dock reject when sea zone not adjacent to province',
        target: NavalOrderValidatorTarget.moveDockRejectWhenSeaZoneNotAdjacentToProvince,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMove accept undock from port to adjacent sea zone',
        target: NavalOrderValidatorTarget.moveAcceptUndockFromPortToAdjacentSeaZone,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMove at sea rejects province id as destinationSeaZoneId',
        target: NavalOrderValidatorTarget.moveAtSeaRejectsProvinceIdAsDestinationSeaZoneId,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMove in-port accepts any sea with direct P–S edge to port',
        target: NavalOrderValidatorTarget.moveInPortAcceptsAnySeaWithDirectPsEdgeToPort,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMove in-port rejects sea only reachable via S–S from port sea',
        target: NavalOrderValidatorTarget.moveInPortRejectsSeaOnlyReachableViaSsFromPortSea,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMove reject when in port but inPortAtProvinceId null',
        target: NavalOrderValidatorTarget.moveRejectWhenInPortButInPortAtProvinceIdNull,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMove dock accept when at sea adjacent owned province',
        target: NavalOrderValidatorTarget.moveDockAcceptWhenAtSeaAdjacentOwnedProvince,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMove dock accept when port province id is local (unprefixed)',
        target: NavalOrderValidatorTarget.moveDockAcceptWhenPortProvinceIdIsLocalUnprefixed,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMove dock reject when fleet in port',
        target: NavalOrderValidatorTarget.moveDockRejectWhenFleetInPort,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMove dock reject when port province not owned',
        target: NavalOrderValidatorTarget.moveDockRejectWhenPortProvinceNotOwned,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMove dock reject when port province not found',
        target: NavalOrderValidatorTarget.moveDockRejectWhenPortProvinceNotFound,
      ),
    ];

/// Canonical scenarios for `validateNavalMission` family tests.
List<NavalOrderValidatorScenario> navalMissionValidatorScenarios() => const [
      NavalOrderValidatorScenario(
        label: 'validateNavalMission rejects when previousRejected',
        target: NavalOrderValidatorTarget.missionRejectsWhenPreviousRejected,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMission blockade requires target province',
        target: NavalOrderValidatorTarget.missionBlockadeRequiresTargetProvince,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMission blockade reject when target not prefixed',
        target: NavalOrderValidatorTarget.missionBlockadeRejectWhenTargetNotPrefixed,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMission blockade reject when blockading own province',
        target: NavalOrderValidatorTarget.missionBlockadeRejectWhenBlockadingOwnProvince,
      ),
      NavalOrderValidatorScenario(
        label: 'validateNavalMission accept non-blockade mission when fleet at sea',
        target: NavalOrderValidatorTarget.missionAcceptNonBlockadeMissionWhenFleetAtSea,
      ),
    ];
