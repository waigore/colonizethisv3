// Last-turn intelligence digest. SPEC/program/intelligence-digest.md.

import 'last_turn_intelligence_digest_spy.dart';
import 'last_turn_intelligence_digest_world.dart';
import 'model_collection_equality.dart';

export 'last_turn_intelligence_digest_spy.dart';
export 'last_turn_intelligence_digest_world.dart';

/// Persisted last-turn briefing. Replaced each completed turn.
class LastTurnIntelligenceDigest {
  const LastTurnIntelligenceDigest({
    required this.resolvedTurnNumber,
    this.worldLines = const [],
    this.spyReportsByObserverId = const {},
  });

  final int resolvedTurnNumber;
  final List<IntelligenceWorldLine> worldLines;
  final Map<String, List<IntelligenceSpyCourtBlock>> spyReportsByObserverId;

  List<IntelligenceSpyCourtBlock> spyReportsFor(String observerId) =>
      spyReportsByObserverId[observerId] ?? const [];

  int spyLineCountFor(String observerId) {
    var n = 0;
    for (final block in spyReportsFor(observerId)) {
      n += block.lines.length;
    }
    return n;
  }

  int lineCountForObserver(String observerId) =>
      worldLines.length + spyLineCountFor(observerId);

  Map<String, dynamic> toJson() {
    final spyJson = <String, dynamic>{};
    final observerIds = spyReportsByObserverId.keys.toList()..sort();
    for (final id in observerIds) {
      spyJson[id] = spyReportsByObserverId[id]!.map((e) => e.toJson()).toList();
    }
    return {
      'resolvedTurnNumber': resolvedTurnNumber,
      'worldLines': worldLines.map((e) => e.toJson()).toList(),
      'spyReportsByObserverId': spyJson,
    };
  }

  static LastTurnIntelligenceDigest fromJson(Map<String, dynamic> json) {
    final worldRaw = json['worldLines'] as List<dynamic>? ?? [];
    final spyRaw =
        json['spyReportsByObserverId'] as Map<dynamic, dynamic>? ?? {};
    final spy = <String, List<IntelligenceSpyCourtBlock>>{};
    for (final entry in spyRaw.entries) {
      final list = entry.value as List<dynamic>? ?? [];
      spy[entry.key.toString()] = list
          .map(
            (e) => IntelligenceSpyCourtBlock.fromJson(
              Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
            ),
          )
          .toList();
    }
    return LastTurnIntelligenceDigest(
      resolvedTurnNumber: (json['resolvedTurnNumber'] as num).toInt(),
      worldLines: worldRaw
          .map(
            (e) => IntelligenceWorldLine.fromJson(
              Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
            ),
          )
          .toList(),
      spyReportsByObserverId: spy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LastTurnIntelligenceDigest &&
          resolvedTurnNumber == other.resolvedTurnNumber &&
          modelListEquals(worldLines, other.worldLines) &&
          modelMapOfListEquals(
            spyReportsByObserverId,
            other.spyReportsByObserverId,
          );

  @override
  int get hashCode => Object.hash(
    resolvedTurnNumber,
    Object.hashAll(worldLines),
    Object.hashAll(spyReportsByObserverId.entries),
  );
}
