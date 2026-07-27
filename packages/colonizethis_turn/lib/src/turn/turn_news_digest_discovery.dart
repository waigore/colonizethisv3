import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'turn_resolution_helpers.dart';

List<TurnNewsProvinceDiscoveredLine> turnNewsProvinceDiscoveryLines({
  required Game start,
  required Game end,
  required Set<String> readDone,
  required Set<String> writeDone,
  required ProvinceVisibilityIndex startIndex,
  required ProvinceVisibilityIndex endIndex,
}) {
  final out = <TurnNewsProvinceDiscoveredLine>[];
  final seen = <String>{};
  for (final p in allProvinces(end.worldState)) {
    final pid = prefixedProvinceId(p);
    if (seen.contains(pid)) continue;
    seen.add(pid);
    if (readDone.contains(pid)) continue;
    final was = startIndex.isKnownToAnyPlayer(pid);
    final now = endIndex.isKnownToAnyPlayer(pid);
    if (!was && now) {
      out.add(TurnNewsProvinceDiscoveredLine(provinceId: pid));
      writeDone.add(pid);
    }
  }
  out.sort((a, b) => a.provinceId.compareTo(b.provinceId));
  return out;
}

String _fullSeaZoneId(Fleet f) {
  final z = f.seaZoneId!;
  return z.contains('|') ? z : ProvinceId.full(f.regionId, z);
}

Set<String> _seaZonesWithFleets(Game g) {
  final s = <String>{};
  for (final f in g.worldState.fleets) {
    if (f.isAtSea) {
      s.add(_fullSeaZoneId(f));
    }
  }
  return s;
}

List<TurnNewsSeaZoneFleetLine> turnNewsSeaZoneFleetLines({
  required Game end,
  required Set<String> readDone,
  required Set<String> writeDone,
}) {
  final zones = _seaZonesWithFleets(end).toList()..sort();
  final out = <TurnNewsSeaZoneFleetLine>[];
  for (final z in zones) {
    if (readDone.contains(z)) continue;
    out.add(TurnNewsSeaZoneFleetLine(seaZoneId: z));
    writeDone.add(z);
  }
  return out;
}
