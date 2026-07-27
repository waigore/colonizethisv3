import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'turn_resolution_helpers.dart';

List<TurnNewsProvinceCapturedLine> turnNewsProvinceCaptureLines(
  Game start,
  Game end,
) {
  final out = <TurnNewsProvinceCapturedLine>[];
  for (final prov in allProvinces(end.worldState)) {
    final pid = prefixedProvinceId(prov);
    final before = _ownerForProvince(start, pid);
    final after = _ownerForProvince(end, pid);
    if (isProvinceOwnershipCaptured(before, after)) {
      out.add(
        TurnNewsProvinceCapturedLine(
          provinceId: pid,
          previousOwnerId: before!,
          newOwnerId: after!,
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

Map<String, RelationState> _pairToState(Game g) {
  final m = <String, RelationState>{};
  for (final r in g.diplomacyRelations) {
    m[_pairKey(r.factionId1, r.factionId2)] = r.state;
  }
  return m;
}

String _pairKey(String a, String b) => a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';

List<TurnNewsDiplomacyLine> turnNewsDiplomacyLines(Game start, Game end) {
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

List<TurnNewsOvertureAdvancedLine> turnNewsOvertureLines(Game start, Game end) {
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
