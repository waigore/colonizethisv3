library;

const String kTurnTraceSchemaVersionV1 = '1.0.0';

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
    required this.capturedAtUtc,
  });

  final String gameId;
  final int turnNumber;
  final String capturedAtUtc;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'gameId': gameId,
      'turnNumber': turnNumber,
      'capturedAtUtc': capturedAtUtc,
    };
  }
}

class TurnTraceAiSection {
  const TurnTraceAiSection({
    required this.schemaVersion,
    required this.factionId,
    required this.state,
    required this.thresholds,
    required this.outcome,
  });

  final String schemaVersion;
  final String factionId;
  final Map<String, Object?> state;
  final Map<String, Object?> thresholds;
  final Map<String, Object?> outcome;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'factionId': factionId,
      'state': state,
      'thresholds': thresholds,
      'outcome': outcome,
    };
  }
}

class TurnTraceResolutionSection {
  const TurnTraceResolutionSection({
    required this.schemaVersion,
    required this.turnNumber,
    required this.phases,
  });

  final String schemaVersion;
  final int turnNumber;
  final List<TurnTracePhaseTrace> phases;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'turnNumber': turnNumber,
      'phases': phases.map((phase) => phase.toJson()).toList(growable: false),
    };
  }
}

class TurnTracePhaseTrace {
  const TurnTracePhaseTrace({
    required this.phase,
    required this.beforeState,
    required this.afterState,
    required this.orderEvents,
  });

  final String phase;
  final Map<String, Object?> beforeState;
  final Map<String, Object?> afterState;
  final List<TurnTraceOrderEvent> orderEvents;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'phase': phase,
      'beforeState': beforeState,
      'afterState': afterState,
      'orderEvents': orderEvents
          .map((event) => event.toJson())
          .toList(growable: false),
    };
  }
}

class TurnTraceOrderEvent {
  const TurnTraceOrderEvent({
    required this.sequence,
    required this.phase,
    required this.eventType,
    this.orderType,
    this.actorFactionId,
  });

  final int sequence;
  final String phase;
  final String eventType;
  final String? orderType;
  final String? actorFactionId;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sequence': sequence,
      'phase': phase,
      'eventType': eventType,
      if (orderType != null) 'orderType': orderType,
      if (actorFactionId != null) 'actorFactionId': actorFactionId,
    };
  }
}
