// Deterministic prior-turn news digest. SPEC/program/turn-news-digest.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'turn_news_digest_discovery.dart';
import 'turn_news_digest_terrestrial.dart';
import 'turn_resolution_helpers.dart';

/// Builds digest lines and world-state tracking updates for the completed turn.
/// [start] is game at resolution entry (after military ensure); [end] is final
/// state including turn increment. Returns null digest when [end.victory] is set.
///
/// [startIndex]/[endIndex] may be supplied by callers that already built the
/// per-state [ProvinceVisibilityIndex] (e.g. the turn-resolution pipeline reuses
/// the same indices for `emitPlayerDiscoveryEvents`) so the O(provinces*players)
/// index is computed once per turn rather than once here and again during
/// discovery-event emission (`SPEC/program/turn-resolution.md` and the
/// turn-resolution budget rule). When omitted, each index is built from the
/// matching state, preserving prior behaviour for standalone callers.
({TurnNewsDigest? digest, Game game}) buildTurnNewsDigestForComplete({
  required Game start,
  required Game end,
  ProvinceVisibilityIndex? startIndex,
  ProvinceVisibilityIndex? endIndex,
}) {
  if (end.victory != null) {
    return (digest: null, game: end);
  }

  final resolvedTurn = start.worldState.turnState.turnNumber;
  final captures = turnNewsProvinceCaptureLines(start, end);
  final diplomacy = turnNewsDiplomacyLines(start, end);
  final overtures = turnNewsOvertureLines(start, end);

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

  final discoveries = turnNewsProvinceDiscoveryLines(
    start: start,
    end: end,
    readDone: provReadDone,
    writeDone: provWriteDone,
    startIndex: startIndex ?? buildProvinceVisibilityIndex(start),
    endIndex: endIndex ?? buildProvinceVisibilityIndex(end),
  );
  final seaLines = turnNewsSeaZoneFleetLines(
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
