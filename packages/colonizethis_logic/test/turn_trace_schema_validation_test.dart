import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_logic/src/trace/turn_trace_contracts.dart';
import 'package:json_schema/json_schema.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  final schemaDir = Directory('../../SPEC/program/schemas/turn-trace');

  Future<Map<String, dynamic>> loadSchema(String fileName) async {
    final file = File('${schemaDir.path}/$fileName');
    final content = await file.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  Future<JsonSchema> createSchema(String fileName) async {
    final schemaMap = await loadSchema(fileName);
    final fetchedFromUri = Uri.parse(
      'https://colonizethis.dev/spec/program/schemas/turn-trace/$fileName',
    );
    return JsonSchema.createAsync(
      schemaMap,
      fetchedFromUri: fetchedFromUri,
      refProvider: RefProvider.async((String ref) async {
        final uri = Uri.parse(ref);
        final refName = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
        if (refName.isEmpty) {
          return null;
        }
        return loadSchema(refName);
      }),
    );
  }

  test(
    'ai schema validates expected payload and rejects missing required keys',
    () async {
      final schema = await createSchema('ai-trace.v1.schema.json');
      final valid = <String, Object?>{
        'factionId': 'gp-england',
        'state': <String, Object?>{
          'winningCandidate': <String, Object?>{'id': 'candidate-1'},
          'topAlternates': <Object?>[
            <String, Object?>{'id': 'candidate-2'},
          ],
          'aggregates': <String, Object?>{'threat': 22},
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
      final invalid = Map<String, Object?>.from(valid)..remove('thresholds');

      expect(schema.validate(valid).isValid, isTrue);
      expect(schema.validate(invalid).isValid, isFalse);
    },
  );

  test(
    'ai schema rejects unknown top-level fields and missing outcome payload keys',
    () async {
      final schema = await createSchema('ai-trace.v1.schema.json');
      final valid = <String, Object?>{
        'factionId': 'gp-spain',
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
      final invalidUnknownField = Map<String, Object?>.from(valid)
        ..['unexpected'] = <String, Object?>{};
      final invalidOutcome = Map<String, Object?>.from(valid)
        ..['outcome'] = <String, Object?>{
          'domainOutputs': <String, Object?>{},
        };

      expect(schema.validate(valid).isValid, isTrue);
      expect(schema.validate(invalidUnknownField).isValid, isFalse);
      expect(schema.validate(invalidOutcome).isValid, isFalse);
    },
  );

  test(
    'resolution schema validates ordered phase payload and rejects malformed events',
    () async {
      final schema = await createSchema('turn-resolution-trace.v1.schema.json');
      final valid = <String, Object?>{
        'phases': <Object?>[
          <String, Object?>{
            'phaseId': 'movement',
            'beforeState': <String, Object?>{'units': 12},
            'afterState': <String, Object?>{'units': 10},
            'orderEvents': <Object?>[
              <String, Object?>{
                'sequence': 0,
                'orderId': 'order-001',
                'eventType': 'order_applied',
              },
            ],
          },
        ],
      };
      final invalid = <String, Object?>{
        'phases': <Object?>[
          <String, Object?>{
            'phaseId': 'movement',
            'beforeState': <String, Object?>{},
            'afterState': <String, Object?>{},
            'orderEvents': <Object?>[
              <String, Object?>{
                'sequence': -1,
                'orderId': 'order-001',
                'eventType': 'order_applied',
              },
            ],
          },
        ],
      };

      expect(schema.validate(valid).isValid, isTrue);
      expect(schema.validate(invalid).isValid, isFalse);
    },
  );

  test(
    'resolution schema rejects unknown phase fields and missing order event keys',
    () async {
      final schema = await createSchema('turn-resolution-trace.v1.schema.json');
      final valid = <String, Object?>{
        'phases': <Object?>[
          <String, Object?>{
            'phaseId': 'support',
            'beforeState': <String, Object?>{},
            'afterState': <String, Object?>{},
            'orderEvents': <Object?>[
              <String, Object?>{
                'sequence': 1,
                'orderId': 'order-100',
                'eventType': 'order_applied',
              },
            ],
          },
        ],
      };
      final invalidUnknownPhaseField = <String, Object?>{
        'phases': <Object?>[
          <String, Object?>{
            'phaseId': 'support',
            'beforeState': <String, Object?>{},
            'afterState': <String, Object?>{},
            'orderEvents': <Object?>[
              <String, Object?>{
                'sequence': 1,
                'orderId': 'order-100',
                'eventType': 'order_applied',
              },
            ],
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
              <String, Object?>{
                'sequence': 1,
                'orderId': 'order-100',
              },
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
      final schema = await createSchema('merged-trace.v1.schema.json');
      final merged = TurnTraceMergedDocument(
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
      final invalid = Map<String, Object?>.from(merged)
        ..remove('turnResolution');

      expect(schema.validate(merged).isValid, isTrue);
      expect(schema.validate(invalid).isValid, isFalse);
    },
  );

  test(
    'merged schema rejects invalid schemaVersion and unknown top-level fields',
    () async {
      final schema = await createSchema('merged-trace.v1.schema.json');
      final valid = <String, Object?>{
        'schemaVersion': 'v1.1',
        'meta': <String, Object?>{
          'gameId': 'game-123',
          'turnNumber': 22,
          'traceEnabled': true,
          'exportedAt': '2026-05-08T06:00:00Z',
        },
        'ai': <Object?>[
          <String, Object?>{
            'factionId': 'gp-france',
            'state': <String, Object?>{
              'winningCandidate': <String, Object?>{'id': 'candidate-1'},
              'topAlternates': <Object?>[],
              'aggregates': <String, Object?>{},
            },
            'thresholds': <String, Object?>{
              'constants': <String, Object?>{},
              'derived': <String, Object?>{},
              'effective': <String, Object?>{},
              'gates': <Object?>[],
            },
            'outcome': <String, Object?>{
              'finalAggregatedOrders': <Object?>[],
              'domainOutputs': <String, Object?>{},
            },
          },
        ],
        'turnResolution': <String, Object?>{
          'phases': <Object?>[
            <String, Object?>{
              'phaseId': 'combat',
              'beforeState': <String, Object?>{},
              'afterState': <String, Object?>{},
              'orderEvents': <Object?>[
                <String, Object?>{
                  'sequence': 0,
                  'orderId': 'order-1',
                  'eventType': 'order_applied',
                },
              ],
            },
          ],
        },
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
