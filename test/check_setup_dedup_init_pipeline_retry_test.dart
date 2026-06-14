import 'package:test/test.dart';

import '../tool/check_setup_dedup_init_pipeline_retry.dart';

void main() {
  group('findSetupDedupInitPipelineRetryViolations', () {
    test('flags an inline per-attempt seed bump (* 100003)', () {
      const src = r'''
for (var attempt = 0; attempt < 64; attempt++) {
  final mapSeed = effectiveSeed + attempt * 100003;
}
''';
      final violations = findSetupDedupInitPipelineRetryViolations(
        sourcesByPath: const {
          'packages/colonizethis_setup/lib/src/setup/init_game_orchestrator.dart':
              src,
        },
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('100003'));
    });

    test('accepts the canonical named seed-bump constant and usage', () {
      const src = r'''
const int kInitPipelineSeedBump = 100003;
final mapSeed = effectiveSeed + attempt * kInitPipelineSeedBump;
''';
      final violations = findSetupDedupInitPipelineRetryViolations(
        sourcesByPath: const {
          'packages/colonizethis_setup/lib/src/setup/init_pipeline_retry.dart':
              src,
        },
      );
      expect(violations, isEmpty);
    });

    test('accepts a single retriable-code predicate occurrence', () {
      const src = r'''
bool isRetriableInitTopologyCode(String code) =>
    code == 'assigner_exhausted' ||
    code == 'faction_component_bin_pack_failed' ||
    code == 'assignment_remainder_not_connected';
''';
      final violations = findSetupDedupInitPipelineRetryViolations(
        sourcesByPath: const {
          'packages/colonizethis_setup/lib/src/setup/init_pipeline_retry.dart':
              src,
        },
      );
      expect(violations, isEmpty);
    });

    test('flags a duplicated retriable-code predicate (>= 2 occurrences)', () {
      const canonical = r'''
bool isRetriableInitTopologyCode(String code) =>
    code == 'faction_component_bin_pack_failed';
''';
      const reinlined = r'''
} on SetupTopologyDataException catch (e) {
  final retriable = e.code == 'faction_component_bin_pack_failed';
}
''';
      final violations = findSetupDedupInitPipelineRetryViolations(
        sourcesByPath: const {
          'packages/colonizethis_setup/lib/src/setup/init_pipeline_retry.dart':
              canonical,
          'packages/colonizethis_setup/lib/src/setup/init_game_orchestrator.dart':
              reinlined,
        },
      );
      expect(violations, hasLength(2));
      expect(
        violations.every(
          (v) => v.message.contains('isRetriableInitTopologyCode'),
        ),
        isTrue,
      );
    });

    test('does not flag throw sites that use code: (colon, not ==)', () {
      const src = r'''
throw SetupTopologyDataException(
  code: 'faction_component_bin_pack_failed',
  details: 'pack failed',
);
''';
      final violations = findSetupDedupInitPipelineRetryViolations(
        sourcesByPath: const {
          'packages/colonizethis_setup/lib/src/setup/game_setup_ownership_remainder_factions.dart':
              src,
        },
      );
      expect(violations, isEmpty);
    });

    test('ignores patterns appearing only in comment lines', () {
      const src = r'''
// historical: final mapSeed = effectiveSeed + attempt * 100003;
/// e.code == 'faction_component_bin_pack_failed' is the retriable predicate.
''';
      final violations = findSetupDedupInitPipelineRetryViolations(
        sourcesByPath: const {
          'packages/colonizethis_setup/lib/src/setup/init_pipeline_retry.dart':
              src,
        },
      );
      expect(violations, isEmpty);
    });
  });
}
