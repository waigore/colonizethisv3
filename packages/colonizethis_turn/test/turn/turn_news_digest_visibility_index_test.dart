import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
// In-package import: emitPlayerDiscoveryEvents is not re-exported via the
// package barrel, so the turn package's own tests reach it through src/.
import 'package:colonizethis_turn/src/turn/turn_event_sink.dart';
import 'package:colonizethis_turn/src/turn/turn_resolution_events.dart';

import 'turn_news_digest_test_support.dart';

// Memoized visibility index plumbing (Refs #3416 AC4): the turn-resolution
// pipeline builds each per-state ProvinceVisibilityIndex once and forwards it
// to both buildTurnNewsDigestForComplete and emitPlayerDiscoveryEvents.
void main() {
  group('buildTurnNewsDigestForComplete visibility index reuse', () {
    const regionId = 'oldWorld';
    const localPid = 'P1';
    final fullPid = ProvinceId.full(regionId, localPid);

    Game unknownStart() => turnNewsGameWithProvinceVis(
      turn: 0,
      fullProvinceId: fullPid,
      regionId: regionId,
      localProvinceId: localPid,
      visibility: 'unknown',
    );
    Game foggedEnd() => turnNewsGameWithProvinceVis(
      turn: 1,
      fullProvinceId: fullPid,
      regionId: regionId,
      localProvinceId: localPid,
      visibility: 'fogged',
    );

    test(
      'Given supplied start/end indices When build Then identical to internal',
      () {
        final start = unknownStart();
        final end = foggedEnd();
        final internal = buildTurnNewsDigestForComplete(start: start, end: end);
        final supplied = buildTurnNewsDigestForComplete(
          start: start,
          end: end,
          startIndex: buildProvinceVisibilityIndex(start),
          endIndex: buildProvinceVisibilityIndex(end),
        );
        expect(internal.digest, isNotNull);
        expect(supplied.digest, isNotNull);
        expectDigestLinesEqual(internal.digest!, supplied.digest!);
      },
    );

    test(
      'Given supplied endIndex marking province already known When build Then no discovery line',
      () {
        final start = unknownStart();
        final end = foggedEnd();
        // Sanity: internal computation reports the reveal as a discovery line.
        final internal = buildTurnNewsDigestForComplete(start: start, end: end);
        expect(
          internal.digest!.lines.whereType<TurnNewsProvinceDiscoveredLine>(),
          hasLength(1),
        );
        // A supplied endIndex built from `start` (province still unknown)
        // proves the passed index is used instead of being recomputed from
        // `end`: the reveal collapses and no discovery line is emitted.
        final supplied = buildTurnNewsDigestForComplete(
          start: start,
          end: end,
          startIndex: buildProvinceVisibilityIndex(start),
          endIndex: buildProvinceVisibilityIndex(start),
        );
        expect(
          supplied.digest!.lines.whereType<TurnNewsProvinceDiscoveredLine>(),
          isEmpty,
        );
      },
    );
  });

  group('emitPlayerDiscoveryEvents visibility index reuse', () {
    const regionId = 'oldWorld';
    const localPid = 'P1';
    final fullPid = ProvinceId.full(regionId, localPid);

    Game unknownStart() => turnNewsGameWithProvinceVis(
      turn: 0,
      fullProvinceId: fullPid,
      regionId: regionId,
      localProvinceId: localPid,
      visibility: 'unknown',
    );
    Game foggedEnd() => turnNewsGameWithProvinceVis(
      turn: 1,
      fullProvinceId: fullPid,
      regionId: regionId,
      localProvinceId: localPid,
      visibility: 'fogged',
    );

    List<String> discoveredProvinceIds(
      Game before,
      Game after, {
      ProvinceVisibilityIndex? beforeIndex,
      ProvinceVisibilityIndex? afterIndex,
    }) {
      final events = <GameEvent>[];
      emitPlayerDiscoveryEvents(
        before,
        after,
        after.worldState.turnState.turnNumber,
        TurnEventSink(onGameEvent: events.add),
        beforeIndex: beforeIndex,
        afterIndex: afterIndex,
      );
      return events
          .whereType<PlayerProvinceDiscoveredEvent>()
          .map((e) => e.provinceId)
          .toList();
    }

    test(
      'Given supplied indices When emit Then same discovery events as internal',
      () {
        final before = unknownStart();
        final after = foggedEnd();
        final internal = discoveredProvinceIds(before, after);
        final supplied = discoveredProvinceIds(
          before,
          after,
          beforeIndex: buildProvinceVisibilityIndex(before),
          afterIndex: buildProvinceVisibilityIndex(after),
        );
        expect(internal, contains(fullPid));
        expect(supplied, equals(internal));
      },
    );

    test(
      'Given supplied afterIndex marking province unknown When emit Then no discovery event',
      () {
        final before = unknownStart();
        final after = foggedEnd();
        final supplied = discoveredProvinceIds(
          before,
          after,
          beforeIndex: buildProvinceVisibilityIndex(before),
          afterIndex: buildProvinceVisibilityIndex(before),
        );
        expect(supplied, isEmpty);
      },
    );
  });
}
