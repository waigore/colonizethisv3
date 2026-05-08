import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_logic/src/turn/trace/turn_trace_contracts.dart';
import 'package:json_schema/json_schema.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  final schemaDir = Directory('lib/src/turn/trace');

  Future<Map<String, dynamic>> loadSchema(String fileName) async {
    final file = File('${schemaDir.path}/$fileName');
    final content = await file.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  Future<JsonSchema> createSchema(String fileName) async {
    final schemaMap = await loadSchema(fileName);
    final fetchedFromUri = Uri.parse(
      'https://colonizethis.dev/schemas/$fileName',
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
      final schema = await createSchema('turn-trace-ai-v1.schema.json');
      final valid = <String, Object?>{
        'schemaVersion': kTurnTraceSchemaVersionV1,
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
          'gatingChecks': <Object?>[
            <String, Object?>{'name': 'can_attack', 'passed': true},
          ],
        },
        'outcome': <String, Object?>{
          'finalOrders': <Object?>[
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
    'resolution schema validates ordered phase payload and rejects malformed events',
    () async {
      final schema = await createSchema('turn-trace-resolution-v1.schema.json');
      final valid = <String, Object?>{
        'schemaVersion': kTurnTraceSchemaVersionV1,
        'turnNumber': 7,
        'phases': <Object?>[
          <String, Object?>{
            'phase': 'movement',
            'beforeState': <String, Object?>{'units': 12},
            'afterState': <String, Object?>{'units': 10},
            'orderEvents': <Object?>[
              <String, Object?>{
                'sequence': 0,
                'phase': 'movement',
                'eventType': 'order_applied',
                'orderType': 'move',
              },
            ],
          },
        ],
      };
      final invalid = <String, Object?>{
        'schemaVersion': kTurnTraceSchemaVersionV1,
        'turnNumber': 7,
        'phases': <Object?>[
          <String, Object?>{
            'phase': 'movement',
            'beforeState': <String, Object?>{},
            'afterState': <String, Object?>{},
            'orderEvents': <Object?>[
              <String, Object?>{
                'sequence': -1,
                'phase': 'movement',
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
    'merged schema validates composed document and rejects missing sections',
    () async {
      final schema = await createSchema('turn-trace-merged-v1.schema.json');
      final merged = TurnTraceMergedDocument(
        schemaVersion: kTurnTraceSchemaVersionV1,
        meta: const TurnTraceMeta(
          gameId: 'game-123',
          turnNumber: 12,
          capturedAtUtc: '2026-05-08T03:10:00Z',
        ),
        ai: const <TurnTraceAiSection>[
          TurnTraceAiSection(
            schemaVersion: kTurnTraceSchemaVersionV1,
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
              'gatingChecks': <Object?>[],
            },
            outcome: <String, Object?>{
              'finalOrders': <Object?>[],
              'domainOutputs': <String, Object?>{},
            },
          ),
        ],
        turnResolution: const TurnTraceResolutionSection(
          schemaVersion: kTurnTraceSchemaVersionV1,
          turnNumber: 12,
          phases: <TurnTracePhaseTrace>[
            TurnTracePhaseTrace(
              phase: 'combat',
              beforeState: <String, Object?>{'battles': 2},
              afterState: <String, Object?>{'battles': 0},
              orderEvents: <TurnTraceOrderEvent>[
                TurnTraceOrderEvent(
                  sequence: 0,
                  phase: 'combat',
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
}
