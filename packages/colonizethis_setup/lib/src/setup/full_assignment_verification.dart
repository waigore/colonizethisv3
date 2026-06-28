import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'setup_exceptions.dart';

/// Stable [SetupTopologyDataException] code raised when a materialized game does
/// not assign every topology province to a non-empty owner.
/// SPEC/program/ga-setup-profile.md § Full-assignment verification.
const String kGaUnassignedProvincesCode = 'unassigned_provinces';

/// Verifies the full non-empty ownership invariant: every province node in
/// [topologyByRegion] must appear in [worldState] (per region) with a non-empty
/// `ownerId` (Great Power, minor, or tribe), and the per-region province counts
/// must match the topology exactly.
///
/// This is the shared invariant the player app guarantees. The GA observer init
/// path calls this for every game so evolved profiles are scored against
/// realistic worlds; the default app init path does not, leaving its behavior
/// unchanged. SPEC/program/ga-setup-profile.md § Full-assignment verification.
///
/// Throws [SetupTopologyDataException] with code [kGaUnassignedProvincesCode]
/// when any province is dropped, the counts mismatch, or an owner is empty.
void verifyFullProvinceAssignment({
  required WorldState worldState,
  required Map<String, MapTopology> topologyByRegion,
}) {
  final problems = <String>[];
  for (final entry in topologyByRegion.entries) {
    final regionId = entry.key;
    final expectedIds = <String>{
      for (final node in entry.value.nodes)
        if (node.type == TopologyNodeType.province)
          ProvinceId.full(regionId, node.id),
    };
    final provinces = worldState.provincesForRegion(regionId).toList();
    final presentIds = <String>{for (final p in provinces) p.id};

    final missing = expectedIds.difference(presentIds).toList()..sort();
    if (missing.isNotEmpty) {
      problems.add(
        'region $regionId: ${missing.length} topology province(s) absent from '
        'WorldState (first: ${missing.take(5).join(", ")})',
      );
    }
    if (provinces.length != expectedIds.length) {
      problems.add(
        'region $regionId: WorldState province count ${provinces.length} != '
        'topology province count ${expectedIds.length}',
      );
    }
    final unowned = <String>[
      for (final p in provinces)
        if (p.ownerId == null || p.ownerId!.isEmpty) p.id,
    ]..sort();
    if (unowned.isNotEmpty) {
      problems.add(
        'region $regionId: ${unowned.length} province(s) with empty ownerId '
        '(first: ${unowned.take(5).join(", ")})',
      );
    }
  }

  if (problems.isNotEmpty) {
    throw SetupTopologyDataException(
      code: kGaUnassignedProvincesCode,
      details: 'Full province assignment violated: ${problems.join("; ")}',
    );
  }
}
