import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_world/src/trace/turn_trace_contracts.dart';
import 'package:json_schema/json_schema.dart';

/// Shared payload / schema loaders for turn-trace validation densify (Refs #4330).
final Directory turnTraceSchemaDir = Directory(
  '../../SPEC/program/schemas/turn-trace',
);

Future<Map<String, dynamic>> loadTurnTraceSchema(String fileName) async {
  final content = await File(
    '${turnTraceSchemaDir.path}/$fileName',
  ).readAsString();
  return jsonDecode(content) as Map<String, dynamic>;
}

Future<JsonSchema> createTurnTraceSchema(String fileName) async {
  final schemaMap = await loadTurnTraceSchema(fileName);
  return JsonSchema.createAsync(
    schemaMap,
    fetchedFromUri: Uri.parse(
      'https://colonizethis.dev/spec/program/schemas/turn-trace/$fileName',
    ),
    refProvider: RefProvider.async((String ref) async {
      final refName = Uri.parse(ref).pathSegments.isEmpty
          ? ''
          : Uri.parse(ref).pathSegments.last;
      if (refName.isEmpty) return null;
      return loadTurnTraceSchema(refName);
    }),
  );
}

Map<String, Object?> minimalAiTracePayload({
  String factionId = 'gp-england',
  Map<String, Object?>? aggregates,
}) => <String, Object?>{
  'factionId': factionId,
  'state': <String, Object?>{
    'winningCandidate': <String, Object?>{'id': 'candidate-1'},
    'topAlternates': <Object?>[
      <String, Object?>{'id': 'candidate-2'},
    ],
    'aggregates': aggregates ?? <String, Object?>{'threat': 22},
  },
  'thresholds': <String, Object?>{
    'constants': <String, Object?>{'warRisk': 10},
    'derived': <String, Object?>{'warRiskEffective': 12},
    'effective': <String, Object?>{'warRiskGate': 14},
    'gates': <Object?>[
      <String, Object?>{'name': 'can_attack', 'passed': true},
    ],
  },
  'outcome': <String, Object?>{
    'finalAggregatedOrders': <Object?>[
      <String, Object?>{'type': 'move', 'province': 'eu|001'},
    ],
    'domainOutputs': <String, Object?>{
      'diplomacy': <String, Object?>{'action': 'none'},
    },
  },
};

Map<String, Object?> sparseAiTracePayload({String factionId = 'gp-spain'}) =>
    <String, Object?>{
      'factionId': factionId,
      'state': <String, Object?>{
        'winningCandidate': <String, Object?>{'id': 'candidate-1'},
        'topAlternates': <Object?>[],
        'aggregates': <String, Object?>{'pressure': 7},
      },
      'thresholds': <String, Object?>{
        'constants': <String, Object?>{},
        'derived': <String, Object?>{},
        'effective': <String, Object?>{},
        'gates': <Object?>[],
      },
      'outcome': <String, Object?>{
        'domainOutputs': <String, Object?>{},
        'finalAggregatedOrders': <Object?>[],
      },
    };

Map<String, Object?> resolutionPhasePayload({
  String phaseId = 'movement',
  int sequence = 0,
  String orderId = 'order-001',
  Map<String, Object?>? beforeState,
  Map<String, Object?>? afterState,
}) => <String, Object?>{
  'phases': <Object?>[
    <String, Object?>{
      'phaseId': phaseId,
      'beforeState': beforeState ?? <String, Object?>{'units': 12},
      'afterState': afterState ?? <String, Object?>{'units': 10},
      'orderEvents': <Object?>[
        <String, Object?>{
          'sequence': sequence,
          'orderId': orderId,
          'eventType': 'order_applied',
        },
      ],
    },
  ],
};

Map<String, Object?> mergedTraceJsonPayload() => TurnTraceMergedDocument(
  schemaVersion: kTurnTraceSchemaVersionV1,
  meta: const TurnTraceMeta(
    gameId: 'game-123',
    turnNumber: 12,
    traceEnabled: true,
    source: 'ctdev',
    exportedAt: '2026-05-08T03:10:00Z',
  ),
  ai: const <TurnTraceAiSection>[
    TurnTraceAiSection(
      factionId: 'gp-france',
      state: <String, Object?>{
        'winningCandidate': <String, Object?>{'id': 'candidate-1'},
        'topAlternates': <Object?>[],
        'aggregates': <String, Object?>{'threat': 14},
      },
      thresholds: <String, Object?>{
        'constants': <String, Object?>{},
        'derived': <String, Object?>{},
        'effective': <String, Object?>{},
        'gates': <Object?>[],
      },
      outcome: <String, Object?>{
        'finalAggregatedOrders': <Object?>[],
        'domainOutputs': <String, Object?>{},
      },
    ),
  ],
  turnResolution: const TurnTraceResolutionSection(
    phases: <TurnTracePhaseTrace>[
      TurnTracePhaseTrace(
        phaseId: 'combat',
        beforeState: <String, Object?>{'battles': 2},
        afterState: <String, Object?>{'battles': 0},
        orderEvents: <TurnTraceOrderEvent>[
          TurnTraceOrderEvent(
            sequence: 0,
            orderId: 'order-combat-0',
            eventType: 'battle_resolved',
          ),
        ],
      ),
    ],
  ),
).toJson();
