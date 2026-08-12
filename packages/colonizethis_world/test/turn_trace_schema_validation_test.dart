import 'package:colonizethis_test/test.dart';

import 'world_test_support/turn_trace_schema_test_support.dart';

void main() {
  test(
    'ai schema validates expected payload and rejects missing required keys',
    () async {
      final schema = await createTurnTraceSchema('ai-trace.v1.schema.json');
      final valid = minimalAiTracePayload();
      final invalid = Map<String, Object?>.from(valid)..remove('thresholds');
      expect(schema.validate(valid).isValid, isTrue);
      expect(schema.validate(invalid).isValid, isFalse);
    },
  );

  test(
    'ai schema rejects unknown top-level fields and missing outcome payload keys',
    () async {
      final schema = await createTurnTraceSchema('ai-trace.v1.schema.json');
      final valid = sparseAiTracePayload();
      final invalidUnknownField = Map<String, Object?>.from(valid)
        ..['unexpected'] = <String, Object?>{};
      final invalidOutcome = Map<String, Object?>.from(valid)
        ..['outcome'] = <String, Object?>{'domainOutputs': <String, Object?>{}};
      expect(schema.validate(valid).isValid, isTrue);
      expect(schema.validate(invalidUnknownField).isValid, isFalse);
      expect(schema.validate(invalidOutcome).isValid, isFalse);
    },
  );

  test(
    'resolution schema validates ordered phase payload and rejects malformed events',
    () async {
      final schema = await createTurnTraceSchema(
        'turn-resolution-trace.v1.schema.json',
      );
      expect(schema.validate(resolutionPhasePayload()).isValid, isTrue);
      expect(
        schema.validate(resolutionPhasePayload(sequence: -1)).isValid,
        isFalse,
      );
    },
  );

  test(
    'resolution schema rejects unknown phase fields and missing order event keys',
    () async {
      final schema = await createTurnTraceSchema(
        'turn-resolution-trace.v1.schema.json',
      );
      final valid = resolutionPhasePayload(
        phaseId: 'support',
        sequence: 1,
        orderId: 'order-100',
        beforeState: const {},
        afterState: const {},
      );
      final invalidUnknownPhaseField = <String, Object?>{
        'phases': <Object?>[
          <String, Object?>{
            ...((valid['phases'] as List).first as Map<String, Object?>),
            'unexpectedField': true,
          },
        ],
      };
      final invalidMissingOrderEventType = <String, Object?>{
        'phases': <Object?>[
          <String, Object?>{
            'phaseId': 'support',
            'beforeState': <String, Object?>{},
            'afterState': <String, Object?>{},
            'orderEvents': <Object?>[
              <String, Object?>{'sequence': 1, 'orderId': 'order-100'},
            ],
          },
        ],
      };
      expect(schema.validate(valid).isValid, isTrue);
      expect(schema.validate(invalidUnknownPhaseField).isValid, isFalse);
      expect(schema.validate(invalidMissingOrderEventType).isValid, isFalse);
    },
  );

  test(
    'merged schema validates composed document and rejects missing sections',
    () async {
      final schema = await createTurnTraceSchema('merged-trace.v1.schema.json');
      final merged = mergedTraceJsonPayload();
      final invalid = Map<String, Object?>.from(merged)
        ..remove('turnResolution');
      expect(schema.validate(merged).isValid, isTrue);
      expect(schema.validate(invalid).isValid, isFalse);
    },
  );

  test(
    'merged schema rejects invalid schemaVersion and unknown top-level fields',
    () async {
      final schema = await createTurnTraceSchema('merged-trace.v1.schema.json');
      final valid = <String, Object?>{
        'schemaVersion': 'v1.1',
        'meta': <String, Object?>{
          'gameId': 'game-123',
          'turnNumber': 22,
          'traceEnabled': true,
          'exportedAt': '2026-05-08T06:00:00Z',
        },
        'ai': <Object?>[sparseAiTracePayload(factionId: 'gp-france')],
        'turnResolution': resolutionPhasePayload(
          phaseId: 'combat',
          beforeState: const {},
          afterState: const {},
          orderId: 'order-1',
        ),
      };
      final invalidVersion = Map<String, Object?>.from(valid)
        ..['schemaVersion'] = '1.1';
      final invalidUnknownTopLevel = Map<String, Object?>.from(valid)
        ..['unexpectedField'] = true;
      expect(schema.validate(valid).isValid, isTrue);
      expect(schema.validate(invalidVersion).isValid, isFalse);
      expect(schema.validate(invalidUnknownTopLevel).isValid, isFalse);
    },
  );
}
