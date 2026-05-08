library;

const String kTurnTraceSchemaVersionV1 = 'v1';

class TurnTraceMergedDocument {
  const TurnTraceMergedDocument({
    required this.schemaVersion,
    required this.meta,
    required this.ai,
    required this.turnResolution,
  });

  final String schemaVersion;
  final TurnTraceMeta meta;
  final List<TurnTraceAiSection> ai;
  final TurnTraceResolutionSection turnResolution;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'meta': meta.toJson(),
      'ai': ai.map((section) => section.toJson()).toList(growable: false),
      'turnResolution': turnResolution.toJson(),
    };
  }
}

class TurnTraceMeta {
  const TurnTraceMeta({
    required this.gameId,
    required this.turnNumber,
    required this.traceEnabled,
    required this.exportedAt,
    this.resolutionSessionId,
    this.seed,
    this.buildMode,
    this.source,
    this.turnStartAt,
    this.turnEndAt,
  });

  final String gameId;
  final int turnNumber;
  final bool traceEnabled;
  final String exportedAt;
  final String? resolutionSessionId;
  final Object? seed;
  final String? buildMode;
  final String? source;
  final String? turnStartAt;
  final String? turnEndAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'gameId': gameId,
      'turnNumber': turnNumber,
      'traceEnabled': traceEnabled,
      'exportedAt': exportedAt,
      if (resolutionSessionId != null) 'resolutionSessionId': resolutionSessionId,
      if (seed != null) 'seed': seed,
      if (buildMode != null) 'buildMode': buildMode,
      if (source != null) 'source': source,
      if (turnStartAt != null) 'turnStartAt': turnStartAt,
      if (turnEndAt != null) 'turnEndAt': turnEndAt,
    };
  }
}

class TurnTraceAiSection {
  const TurnTraceAiSection({
    required this.factionId,
    required this.state,
    required this.thresholds,
    required this.outcome,
  });

  final String factionId;
  final Map<String, Object?> state;
  final Map<String, Object?> thresholds;
  final Map<String, Object?> outcome;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'factionId': factionId,
      'state': state,
      'thresholds': thresholds,
      'outcome': outcome,
    };
  }
}

class TurnTraceResolutionSection {
  const TurnTraceResolutionSection({
    required this.phases,
  });

  final List<TurnTracePhaseTrace> phases;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'phases': phases.map((phase) => phase.toJson()).toList(growable: false),
    };
  }
}

class TurnTracePhaseTrace {
  const TurnTracePhaseTrace({
    required this.phaseId,
    required this.beforeState,
    required this.afterState,
    required this.orderEvents,
    this.effects,
  });

  final String phaseId;
  final Map<String, Object?> beforeState;
  final Map<String, Object?> afterState;
  final List<TurnTraceOrderEvent> orderEvents;
  final Map<String, Object?>? effects;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'phaseId': phaseId,
      'beforeState': beforeState,
      'afterState': afterState,
      'orderEvents': orderEvents
          .map((event) => event.toJson())
          .toList(growable: false),
      if (effects != null) 'effects': effects,
    };
  }
}

class TurnTraceOrderEvent {
  const TurnTraceOrderEvent({
    required this.sequence,
    required this.orderId,
    required this.eventType,
    this.timestamp,
    this.payload,
  });

  final int sequence;
  final String orderId;
  final String eventType;
  final String? timestamp;
  final Map<String, Object?>? payload;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sequence': sequence,
      'orderId': orderId,
      'eventType': eventType,
      if (timestamp != null) 'timestamp': timestamp,
      if (payload != null) 'payload': payload,
    };
  }
}
