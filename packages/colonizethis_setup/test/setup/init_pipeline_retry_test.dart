import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_setup/src/setup/init_pipeline_retry.dart';
import 'package:colonizethis_setup/src/setup/setup_exceptions.dart';
import 'package:colonizethis_test/test.dart';

/// Shared init-pipeline retry runner (Refs #3449): both the locked and freeform
/// pipelines delegate the bounded attempt loop, per-attempt seed bump, retriable
/// topology-code classification, and exhaustion throw to this one runner. These
/// tests cover the control flow via throwing attempts; the success-return path
/// is exercised end-to-end by the `runInitGame` orchestrator tests.
void main() {
  group('isRetriableInitTopologyCode', () {
    test('positive: true for the retriable topology codes', () {
      expect(isRetriableInitTopologyCode('assigner_exhausted'), isTrue);
      expect(
        isRetriableInitTopologyCode('faction_component_bin_pack_failed'),
        isTrue,
      );
      expect(
        isRetriableInitTopologyCode('assignment_remainder_not_connected'),
        isTrue,
      );
      // Tribe sea-bound ownership gate triggers map regeneration (S4b / #3753).
      expect(
        isRetriableInitTopologyCode('tribe_missing_sea_bound_province'),
        isTrue,
      );
    });

    test('negative: false for unrelated / hard-failure codes', () {
      expect(isRetriableInitTopologyCode('map_partition_exhausted'), isFalse);
      expect(
        isRetriableInitTopologyCode('no_sea_bound_capital_province'),
        isFalse,
      );
      expect(isRetriableInitTopologyCode(''), isFalse);
    });
  });

  group('runInitPipelineWithRetries', () {
    test('constants match the documented retry contract', () {
      expect(kMaxInitPipelineAttempts, 64);
      expect(kInitPipelineSeedBump, 100003);
    });

    test('retries retriable topology codes and bumps the seed per attempt', () {
      // Faithful to the pre-dedup pipelines: when every attempt throws a
      // retriable code, all attempts run and the final attempt's exception is
      // rethrown (the post-loop exhaustion throw is a defensive fallback).
      const effectiveSeed = 5000;
      final seenSeeds = <int>[];
      expect(
        () => runInitPipelineWithRetries(
          effectiveSeed: effectiveSeed,
          modeLabel: 'test',
          generateAndCreate: (mapSeed) {
            seenSeeds.add(mapSeed);
            throw SetupTopologyDataException(
              code: 'assigner_exhausted',
              details: 'retry me',
            );
          },
        ),
        throwsA(
          isA<SetupTopologyDataException>()
              .having((e) => e.code, 'code', 'assigner_exhausted')
              .having((e) => e.message, 'details', contains('retry me')),
        ),
      );
      expect(seenSeeds, hasLength(kMaxInitPipelineAttempts));
      expect(seenSeeds.first, effectiveSeed);
      expect(seenSeeds[1], effectiveSeed + kInitPipelineSeedBump);
      expect(seenSeeds.last, effectiveSeed + 63 * kInitPipelineSeedBump);
    });

    test('rethrows a non-retriable topology code immediately', () {
      var attempts = 0;
      expect(
        () => runInitPipelineWithRetries(
          effectiveSeed: 1,
          modeLabel: 'test',
          generateAndCreate: (mapSeed) {
            attempts++;
            throw SetupTopologyDataException(
              code: 'old_world_gp_assignment_infeasible',
              details: 'hard failure',
            );
          },
        ),
        throwsA(
          isA<SetupTopologyDataException>().having(
            (e) => e.code,
            'code',
            'old_world_gp_assignment_infeasible',
          ),
        ),
      );
      expect(attempts, 1);
    });

    test('stops retrying when a later attempt hits a non-retriable code', () {
      var attempts = 0;
      expect(
        () => runInitPipelineWithRetries(
          effectiveSeed: 0,
          modeLabel: 'test',
          generateAndCreate: (mapSeed) {
            attempts++;
            if (attempts == 1) {
              throw SetupTopologyDataException(
                code: 'assigner_exhausted',
                details: 'retry',
              );
            }
            throw SetupTopologyDataException(
              code: 'old_world_gp_landmass_packing_failed',
              details: 'stop',
            );
          },
        ),
        throwsA(
          isA<SetupTopologyDataException>().having(
            (e) => e.code,
            'code',
            'old_world_gp_landmass_packing_failed',
          ),
        ),
      );
      expect(attempts, 2);
    });

    test('onAttemptError can retry then convert on the final attempt', () {
      var attempts = 0;
      expect(
        () => runInitPipelineWithRetries(
          effectiveSeed: 7,
          modeLabel: 'locked full-init',
          onAttemptError: (error, stackTrace, attempt, isLastAttempt) {
            if (error is! MapPartitionGatesExhaustedException) {
              return InitPipelineErrorAction.unhandled;
            }
            if (!isLastAttempt) return InitPipelineErrorAction.retry;
            throw SetupTopologyDataException(
              code: MapPartitionGatesExhaustedException.codeValue,
              details: error.toString(),
            );
          },
          generateAndCreate: (mapSeed) {
            attempts++;
            throw MapPartitionGatesExhaustedException(attempts: 1);
          },
        ),
        throwsA(
          isA<SetupTopologyDataException>().having(
            (e) => e.code,
            'code',
            MapPartitionGatesExhaustedException.codeValue,
          ),
        ),
      );
      expect(attempts, kMaxInitPipelineAttempts);
    });

    test('onAttemptError returning unhandled rethrows the original error', () {
      var attempts = 0;
      expect(
        () => runInitPipelineWithRetries(
          effectiveSeed: 0,
          modeLabel: 'test',
          onAttemptError: (error, stackTrace, attempt, isLastAttempt) =>
              InitPipelineErrorAction.unhandled,
          generateAndCreate: (mapSeed) {
            attempts++;
            throw const FormatException('not a setup error');
          },
        ),
        throwsA(isA<FormatException>()),
      );
      expect(attempts, 1);
    });
  });
}
