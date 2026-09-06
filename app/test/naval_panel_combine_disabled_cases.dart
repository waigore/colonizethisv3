// Naval combine disabled scenario table (Refs #4352 Slice D, #4734 densify).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'naval_panel_combine_outcome_helpers.dart';
import 'naval_panel_combine_support.dart';
import 'naval_units_panel_sea_mission_scenarios.dart'
    show kNavalPanelCapProvince, kNavalPanelMergePort;
import 'units_panel_test_shared.dart' show unitsPanelOwProvince;

List<NavalPanelCombineDisabledCase> navalPanelCombineDisabledCases() {
  const capTiles = {
    kNavalPanelCapProvince: ['oldWorld|cap1|0|0'],
  };
  return [
    navalPanelCombineDisabledCase(
      name:
          'AC: Fleets at different locations keep Combine disabled when both checked',
      humanId: 'gp_diff_loc',
      provinces: [
        unitsPanelOwProvince('cap1', 'gp_diff_loc', displayName: 'Capital'),
        unitsPanelOwProvince('port_a', 'gp_diff_loc', displayName: 'Port A'),
        unitsPanelOwProvince('port_b', 'gp_diff_loc', displayName: 'Port B'),
      ],
      fleets: [
        navalPanelPortShipFleet(
          id: 'fa',
          humanId: 'gp_diff_loc',
          port: 'oldWorld|port_a',
          shipId: 'ship_1',
        ),
        navalPanelPortShipFleet(
          id: 'fb',
          humanId: 'gp_diff_loc',
          port: 'oldWorld|port_b',
          shipId: 'ship_2',
          typeId: 'fluyte',
        ),
      ],
      labels: const ['Fleet fa', 'Fleet fb'],
      tileKeysByProvince: capTiles,
    ),
    navalPanelCombineDisabledCase(
      name:
          'AC: Fleets in different sea zones keep Combine disabled when both checked',
      humanId: 'gp_two_seas',
      provinces: [
        unitsPanelOwProvince('coast', 'gp_two_seas', displayName: 'Coast'),
        unitsPanelOwProvince('cap1', 'gp_two_seas', displayName: 'Capital'),
      ],
      fleets: [
        navalPanelSeaShipFleet(
          id: 'sea_a',
          humanId: 'gp_two_seas',
          seaZoneId: 'zone_alpha',
          shipId: 'a1',
        ),
        navalPanelSeaShipFleet(
          id: 'sea_b',
          humanId: 'gp_two_seas',
          seaZoneId: 'zone_beta',
          shipId: 'b1',
          typeId: 'fluyte',
        ),
      ],
      labels: const ['Fleet sea_a', 'Fleet sea_b'],
      portsByProvinceSeaboard: {
        'oldWorld|coast|zone_alpha': 'oldWorld|coast|0|0',
        'oldWorld|coast|zone_beta': 'oldWorld|coast|1|0',
      },
      tileKeysByProvince: {
        ...capTiles,
        'oldWorld|coast': ['oldWorld|coast|0|0'],
      },
      nextShipInstanceSeq: 2,
    ),
    navalPanelCombineDisabledCase(
      name:
          'AC: Fleet at sea and fleet in port keep Combine disabled when both checked',
      humanId: 'gp_sea_port',
      provinces: [
        unitsPanelOwProvince('cap1', 'gp_sea_port', displayName: 'Capital'),
        unitsPanelOwProvince(
          'mergeport',
          'gp_sea_port',
          displayName: 'Merge Port',
        ),
        unitsPanelOwProvince('coast', 'gp_sea_port', displayName: 'Coast'),
      ],
      fleets: [
        navalPanelSeaShipFleet(
          id: 'at_sea',
          humanId: 'gp_sea_port',
          seaZoneId: 'zone_alpha',
          shipId: 's_sea',
        ),
        navalPanelPortShipFleet(
          id: 'in_port',
          humanId: 'gp_sea_port',
          port: kNavalPanelMergePort,
          shipId: 's_port',
          typeId: 'fluyte',
        ),
      ],
      labels: const ['Fleet at_sea', 'Fleet in_port'],
      portsByProvinceSeaboard: {
        'oldWorld|coast|zone_alpha': 'oldWorld|coast|0|0',
      },
      tileKeysByProvince: {
        ...capTiles,
        'oldWorld|coast': ['oldWorld|coast|0|0'],
      },
    ),
  ];
}
