import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// When OW and NW topologies both match locked multisets, assert GitHub #1830
/// AC-1–AC-9 (subset exercised here; procedural maps often miss multisets).
void expectLockedFullInitAcWhenPartitionsMatch(
  InitGameResult r, {
  required int seed,
}) {
  final topoOw = r.topologyByRegion[kRegionOldWorld]!;
  final topoNw = r.topologyByRegion[kRegionNewWorld]!;
  if (!oldWorldPartitionMatchesLockedProfile(topoOw) ||
      !newWorldPartitionMatchesLockedProfile(topoNw)) {
    return;
  }
  expectLockedFullInitAc1To9(r, seed: seed);
}

/// AC-1–AC-9 postconditions for locked full-init after successful [runInitGame] (#1830).
void expectLockedFullInitAc1To9(InitGameResult r, {required int seed}) {
  final rs = 'seed=$seed';
  final topoOw = r.topologyByRegion[kRegionOldWorld]!;
  final topoNw = r.topologyByRegion[kRegionNewWorld]!;
  expect(
    oldWorldPartitionMatchesLockedProfile(topoOw),
    isTrue,
    reason: 'AC-2 $rs',
  );
  expect(
    newWorldPartitionMatchesLockedProfile(topoNw),
    isTrue,
    reason: 'AC-3 $rs',
  );
  expect(ppLandComponentSizesSorted(topoOw), [
    13,
    13,
    17,
    17,
  ], reason: 'AC-2 multiset $rs');
  expect(ppLandComponentSizesSorted(topoNw), [
    6,
    6,
    9,
    9,
  ], reason: 'AC-3 multiset $rs');

  final game = r.game;
  expect(game.worldState.newWorld.provinces.length, 30, reason: 'AC-1 $rs');
  expect(game.tribes.length, 10, reason: 'AC-1 $rs');

  for (var i = 1; i <= 6; i++) {
    final gid = 'gp$i';
    final c =
        game.worldState.oldWorld.provinces.where((p) => p.ownerId == gid).length;
    expect(c, 7, reason: 'AC-4 $gid $rs');
  }
  for (var i = 1; i <= 6; i++) {
    final mid = 'minor$i';
    final c = game.worldState.oldWorld.provinces
        .where((p) => p.ownerId == mid)
        .length;
    expect(c, 3, reason: 'AC-4 $mid $rs');
  }
  final ownedOw = game.worldState.oldWorld.provinces
      .where((p) => p.ownerId != null && p.ownerId!.isNotEmpty)
      .length;
  expect(ownedOw, 60, reason: 'AC-4 $rs');

  final nbrOw = _provincePpNeighboursForInitGameTest(topoOw);
  final ownersOw = <String, String>{
    for (final p in game.worldState.oldWorld.provinces)
      if (p.ownerId != null && p.ownerId!.isNotEmpty)
        ProvinceId.localIdFrom(p.id): p.ownerId!,
  };
  expect(ownersOw.length, 60, reason: 'AC-4 owners map $rs');

  for (final gpId in ['gp1', 'gp2', 'gp3', 'gp4', 'gp5', 'gp6']) {
    expect(
      gpProvincesAreLandConnected(gpId, ownersOw, nbrOw),
      isTrue,
      reason: 'AC-5 $gpId $rs',
    );
    final gpProvinces = game.worldState.oldWorld.provinces
        .where((p) => p.ownerId == gpId)
        .toList();
    expect(gpProvinces, isNotEmpty, reason: 'AC-5 $gpId $rs');
    final anySea = gpProvinces.any(
      (p) => isProvinceSeaBound(topoOw, ProvinceId.localIdFrom(p.id)),
    );
    expect(anySea, isTrue, reason: 'AC-5 sea-bound $gpId $rs');
  }

  final compsBySize = _landComponentsFromPpNeighbours(nbrOw).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  expect(compsBySize.length, 4, reason: 'AC-6 $rs');
  expect(compsBySize[0].length, 17, reason: 'AC-6 $rs');
  expect(compsBySize[1].length, 17, reason: 'AC-6 $rs');
  expect(compsBySize[2].length, 13, reason: 'AC-6 $rs');
  expect(compsBySize[3].length, 13, reason: 'AC-6 $rs');
  for (final land in compsBySize) {
    final gps = <String>{};
    final mins = <String>{};
    for (final pid in land) {
      final o = ownersOw[pid];
      if (o == null) continue;
      if (o.startsWith('gp')) {
        gps.add(o);
      }
      if (o.startsWith('minor')) {
        mins.add(o);
      }
    }
    if (land.length == 17) {
      expect(gps.length, 2, reason: 'AC-6 17-tile continent $rs');
      expect(mins.length, 1, reason: 'AC-6 17-tile continent $rs');
    } else {
      expect(gps.length, 1, reason: 'AC-6 13-tile continent $rs');
      expect(mins.length, 2, reason: 'AC-6 13-tile continent $rs');
    }
  }

  for (var i = 1; i <= 6; i++) {
    final mid = 'minor$i';
    expect(
      gpProvincesAreLandConnected(mid, ownersOw, nbrOw),
      isTrue,
      reason: 'AC-7 $mid $rs',
    );
  }

  final nbrNw = _provincePpNeighboursForInitGameTest(topoNw);
  final ownersNw = <String, String>{
    for (final p in game.worldState.newWorld.provinces)
      if (p.ownerId != null && p.ownerId!.isNotEmpty)
        ProvinceId.localIdFrom(p.id): p.ownerId!,
  };
  expect(ownersNw.length, 30, reason: 'AC-8 $rs');
  for (var i = 1; i <= 10; i++) {
    final tid = 'tribe$i';
    final c =
        game.worldState.newWorld.provinces.where((p) => p.ownerId == tid).length;
    expect(c, 3, reason: 'AC-8 $tid $rs');
    expect(
      gpProvincesAreLandConnected(tid, ownersNw, nbrNw),
      isTrue,
      reason: 'AC-8 $tid connected $rs',
    );
  }

  final nwComps = _landComponentsFromPpNeighbours(nbrNw);
  expect(nwComps.length, 4, reason: 'AC-9 $rs');
  for (final land in nwComps) {
    final tribes = <String>{};
    for (final pid in land) {
      final o = ownersNw[pid];
      if (o == null || !o.startsWith('tribe')) continue;
      tribes.add(o);
    }
    if (land.length == 9) {
      expect(tribes.length, 3, reason: 'AC-9 nine-tile continent $rs');
    } else if (land.length == 6) {
      expect(tribes.length, 2, reason: 'AC-9 six-tile continent $rs');
    } else {
      fail('unexpected NW land size ${land.length} ($rs)');
    }
  }
}

Map<String, Set<String>> _provincePpNeighboursForInitGameTest(
  MapTopology topology,
) {
  final provinces = {
    for (final n in topology.nodes)
      if (n.type == TopologyNodeType.province) n.id,
  };
  final neighbours = <String, Set<String>>{
    for (final id in provinces) id: <String>{},
  };
  for (final edge in topology.edges) {
    final a = edge.id1;
    final b = edge.id2;
    if (!provinces.contains(a) || !provinces.contains(b)) continue;
    neighbours[a]!.add(b);
    neighbours[b]!.add(a);
  }
  return neighbours;
}

List<Set<String>> _landComponentsFromPpNeighbours(
  Map<String, Set<String>> neighbours,
) {
  final visited = <String>{};
  final out = <Set<String>>[];
  for (final start in neighbours.keys.toList()..sort()) {
    if (visited.contains(start)) continue;
    final comp = <String>{};
    final stack = <String>[start];
    while (stack.isNotEmpty) {
      final u = stack.removeLast();
      if (!visited.add(u)) continue;
      comp.add(u);
      for (final v in neighbours[u] ?? const <String>{}) {
        if (visited.contains(v)) continue;
        stack.add(v);
      }
    }
    out.add(comp);
  }
  return out;
}
