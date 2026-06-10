// Deterministic prior-turn news digest. SPEC/program/turn-news-digest.md.

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';

/// Builds digest lines and world-state tracking updates for the completed turn.
/// [start] is game at resolution entry (after military ensure); [end] is final
/// state including turn increment. Returns null digest when [end.victory] is set.
({TurnNewsDigest? digest, Game game}) buildTurnNewsDigestForComplete({
  required Game start,
  required Game end,
}) {
  if (end.victory != null) {
    return (digest: null, game: end);
  }

  final resolvedTurn = start.worldState.turnState.turnNumber;
  final captures = _provinceCaptureLines(start, end);
  final diplomacy = _diplomacyLines(start, end);
  final overtures = _overtureLines(start, end);

  final provReadDone = Set<String>.from(
    start.worldState.newsDigestProvinceRevealDoneIds,
  );
  final provWriteDone = Set<String>.from(
    start.worldState.newsDigestProvinceRevealDoneIds,
  );
  final seaReadDone = Set<String>.from(
    start.worldState.newsDigestSeaZoneFleetDoneIds,
  );
  final seaWriteDone = Set<String>.from(
    start.worldState.newsDigestSeaZoneFleetDoneIds,
  );

  final discoveries = _provinceDiscoveryLines(
    start: start,
    end: end,
    readDone: provReadDone,
    writeDone: provWriteDone,
    startIndex: buildProvinceVisibilityIndex(start),
    endIndex: buildProvinceVisibilityIndex(end),
  );
  final seaLines = _seaZoneFleetLines(
    end: end,
    readDone: seaReadDone,
    writeDone: seaWriteDone,
  );

  final lines = <TurnNewsLine>[
    ...captures,
    ...diplomacy,
    ...overtures,
    ...discoveries,
    ...seaLines,
  ];

  final sortedProv = provWriteDone.toList()..sort();
  final sortedSea = seaWriteDone.toList()..sort();

  final patched = end.updateWorldState(
    (ws) => ws.copyWith(
      newsDigestProvinceRevealDoneIds: sortedProv,
      newsDigestSeaZoneFleetDoneIds: sortedSea,
    ),
  );

  return (
    digest: TurnNewsDigest(resolvedTurnNumber: resolvedTurn, lines: lines),
    game: patched,
  );
}

List<TurnNewsProvinceCapturedLine> _provinceCaptureLines(Game start, Game end) {
  final out = <TurnNewsProvinceCapturedLine>[];
  for (final prov in allProvinces(end.worldState)) {
    final pid = _fullProvinceId(prov);
    final before = _ownerForProvince(start, pid);
    final after = _ownerForProvince(end, pid);
    // Same predicate as emitProvinceCapturedEvents: both owners non-empty faction
    // ids and owner changed (no null/empty "new owner" capture). See SPEC/game/world-model.md.
    if (before != null &&
        before.isNotEmpty &&
        after != null &&
        after.isNotEmpty &&
        before != after) {
      out.add(
        TurnNewsProvinceCapturedLine(
          provinceId: pid,
          previousOwnerId: before,
          newOwnerId: after,
        ),
      );
    }
  }
  out.sort((a, b) => a.provinceId.compareTo(b.provinceId));
  return out;
}

String? _ownerForProvince(Game g, String fullProvinceId) {
  return g.worldState.tryGetProvince(fullProvinceId)?.ownerId;
}

String _fullProvinceId(Province p) =>
    p.id.contains('|') ? p.id : ProvinceId.full(p.regionId, p.id);

Map<String, RelationState> _pairToState(Game g) {
  final m = <String, RelationState>{};
  for (final r in g.diplomacyRelations) {
    m[_pairKey(r.factionId1, r.factionId2)] = r.state;
  }
  return m;
}

String _pairKey(String a, String b) => a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';

List<TurnNewsDiplomacyLine> _diplomacyLines(Game start, Game end) {
  final startMap = _pairToState(start);
  final endMap = _pairToState(end);
  final keys = {...startMap.keys, ...endMap.keys}.toList()..sort();
  final out = <TurnNewsDiplomacyLine>[];
  for (final k in keys) {
    final before = startMap[k];
    final after = endMap[k];
    if (before == after) continue;
    final parts = k.split('|');
    if (parts.length != 2) continue;
    final fa = parts[0];
    final fb = parts[1];
    if (after == RelationState.atWar && before != RelationState.atWar) {
      out.add(
        TurnNewsDiplomacyLine(
          factionIdA: fa,
          factionIdB: fb,
          kind: TurnNewsDiplomacyKind.war,
        ),
      );
    }
    if (after == RelationState.atPeace && before == RelationState.atWar) {
      out.add(
        TurnNewsDiplomacyLine(
          factionIdA: fa,
          factionIdB: fb,
          kind: TurnNewsDiplomacyKind.peace,
        ),
      );
    }
  }
  return out;
}

List<TurnNewsOvertureAdvancedLine> _overtureLines(Game start, Game end) {
  OvertureStage stageFor(String gp, String target, Game g) {
    for (final o in g.overtureStates) {
      if (o.gpId == gp && o.targetId == target) {
        return o.stage;
      }
    }
    return OvertureStage.none;
  }

  final out = <TurnNewsOvertureAdvancedLine>[];
  for (final o in end.overtureStates) {
    final prev = stageFor(o.gpId, o.targetId, start);
    if (o.stage.index > prev.index) {
      out.add(
        TurnNewsOvertureAdvancedLine(
          offererGpId: o.gpId,
          targetFactionId: o.targetId,
          newStage: o.stage,
        ),
      );
    }
  }
  out.sort((a, b) {
    final c = a.offererGpId.compareTo(b.offererGpId);
    if (c != 0) return c;
    final d = a.targetFactionId.compareTo(b.targetFactionId);
    if (d != 0) return d;
    return a.newStage.name.compareTo(b.newStage.name);
  });
  return out;
}

List<TurnNewsProvinceDiscoveredLine> _provinceDiscoveryLines({
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
    final pid = _fullProvinceId(p);
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

List<TurnNewsSeaZoneFleetLine> _seaZoneFleetLines({
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
