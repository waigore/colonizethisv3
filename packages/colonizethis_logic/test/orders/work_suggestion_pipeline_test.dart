import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_logic/src/orders/work_suggestion_pipeline.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

List<String> _suggestWorkLines(List<LogEvent> events) => [
  for (final e in events)
    if (e.message.contains('suggest_work')) e.message,
];

void main() {
  suppressLogsForTests();
  group('WorkSuggestionPipeline', () {
    late List<LogEvent> capturedEvents;
    late void Function(LogEvent) listener;

    setUp(() {
      capturedEvents = [];
      listener = capturedEvents.add;
      Logger.addLogListener(listener);
      Logger.level = Level.debug;
    });

    tearDown(() {
      Logger.removeLogListener(listener);
      capturedEvents.clear();
      Logger.level = Level.info;
    });

    test(
      'duplicate pending target short-circuits without adding suggestions',
      () {
        const playerId = 'gp1';
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeBuilder,
          ownerId: playerId,
          locationProvinceId: 'ow|p1',
          tileKey: 'ow|p1|0|0',
          status: UnitStatus.idle,
        );
        final suggestions = <WorkOrder>[];
        final existing = <String, Set<String>>{
          unit.id: {kWorkTargetBuildImprovement},
        };

        WorkSuggestionPipeline.run(
          unit: unit,
          unitType: unit.type,
          unitRegionId: 'ow',
          atProvinceId: 'ow|p1',
          workTarget: kWorkTargetBuildImprovement,
          existingTargetsByUnit: existing,
          suggestions: suggestions,
          candidatesProvider: () => [
            WorkOrder(
              unitId: unit.id,
              target: kWorkTargetBuildImprovement,
              targetTileKey: 'ow|p1|0|0',
            ),
          ],
          candidateAcceptor: (_) => true,
          noCandidateReason: 'no_valid_tile',
        );

        expect(suggestions, isEmpty);
        final lines = _suggestWorkLines(capturedEvents);
        expect(lines, isNotEmpty);
        expect(lines.first, contains('reason=duplicate_pending'));
      },
    );

    test(
      'first accepted candidate stops iteration when includeAllAccepted is false',
      () {
        const playerId = 'gp1';
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeBuilder,
          ownerId: playerId,
          locationProvinceId: 'ow|p1',
          tileKey: 'ow|p1|0|0',
          status: UnitStatus.idle,
        );
        final suggestions = <WorkOrder>[];
        final existing = <String, Set<String>>{};

        WorkSuggestionPipeline.run(
          unit: unit,
          unitType: unit.type,
          unitRegionId: 'ow',
          atProvinceId: 'ow|p1',
          workTarget: kWorkTargetBuildImprovement,
          existingTargetsByUnit: existing,
          suggestions: suggestions,
          candidatesProvider: () sync* {
            yield WorkOrder(
              unitId: unit.id,
              target: kWorkTargetBuildImprovement,
              targetTileKey: 'a',
            );
            yield WorkOrder(
              unitId: unit.id,
              target: kWorkTargetBuildImprovement,
              targetTileKey: 'b',
            );
          },
          candidateAcceptor: (_) => true,
          noCandidateReason: 'no_valid_tile',
        );

        expect(suggestions, hasLength(1));
        expect(suggestions.single.targetTileKey, 'a');
        expect(existing[unit.id], contains(kWorkTargetBuildImprovement));
      },
    );

    test(
      'includeAllAccepted collects multiple rows and logs includedCount',
      () {
        const playerId = 'gp1';
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeBuilder,
          ownerId: playerId,
          locationProvinceId: 'ow|p1',
          tileKey: 'ow|p1|0|0',
          status: UnitStatus.idle,
        );
        final suggestions = <WorkOrder>[];
        final existing = <String, Set<String>>{};

        WorkSuggestionPipeline.run(
          unit: unit,
          unitType: unit.type,
          unitRegionId: 'ow',
          atProvinceId: 'ow|p1',
          workTarget: kWorkTargetBuildImprovement,
          existingTargetsByUnit: existing,
          suggestions: suggestions,
          candidatesProvider: () sync* {
            yield WorkOrder(
              unitId: unit.id,
              target: kWorkTargetBuildImprovement,
              targetTileKey: 'a',
            );
            yield WorkOrder(
              unitId: unit.id,
              target: kWorkTargetBuildImprovement,
              targetTileKey: 'b',
            );
          },
          candidateAcceptor: (_) => true,
          noCandidateReason: 'no_valid_tile',
          includeAllAccepted: true,
        );

        expect(suggestions, hasLength(2));
        final lines = _suggestWorkLines(capturedEvents);
        expect(lines.last, contains('includedCount=2'));
      },
    );

    test('no candidates logs noCandidateReason', () {
      const playerId = 'gp1';
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: playerId,
        locationProvinceId: 'ow|p1',
        tileKey: 'ow|p1|0|0',
        status: UnitStatus.idle,
      );
      final suggestions = <WorkOrder>[];
      final existing = <String, Set<String>>{};

      WorkSuggestionPipeline.run(
        unit: unit,
        unitType: unit.type,
        unitRegionId: 'ow',
        atProvinceId: 'ow|p1',
        workTarget: kWorkTargetBuildImprovement,
        existingTargetsByUnit: existing,
        suggestions: suggestions,
        candidatesProvider: () => const <WorkOrder>[],
        candidateAcceptor: (_) => true,
        noCandidateReason: 'custom_empty',
      );

      expect(suggestions, isEmpty);
      final lines = _suggestWorkLines(capturedEvents);
      expect(lines.single, contains('reason=custom_empty'));
    });

    test(
      'resolveNoCandidateReason overrides noCandidateReason when nothing yielded',
      () {
        const playerId = 'gp1';
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeBuilder,
          ownerId: playerId,
          locationProvinceId: 'ow|p1',
          tileKey: 'ow|p1|0|0',
          status: UnitStatus.idle,
        );
        final suggestions = <WorkOrder>[];
        final existing = <String, Set<String>>{};
        var probeLast = 'fallback';

        WorkSuggestionPipeline.run(
          unit: unit,
          unitType: unit.type,
          unitRegionId: 'ow',
          atProvinceId: 'ow|p1',
          workTarget: kWorkTargetBuildImprovement,
          existingTargetsByUnit: existing,
          suggestions: suggestions,
          candidatesProvider: () sync* {
            probeLast = 'after_probe';
          },
          candidateAcceptor: (_) => true,
          noCandidateReason: 'ignored_when_resolver',
          resolveNoCandidateReason: () => probeLast,
        );

        expect(suggestions, isEmpty);
        final lines = _suggestWorkLines(capturedEvents);
        expect(lines.single, contains('reason=after_probe'));
      },
    );

    test('rejected candidates log engineRejectedReason', () {
      const playerId = 'gp1';
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: playerId,
        locationProvinceId: 'ow|p1',
        tileKey: 'ow|p1|0|0',
        status: UnitStatus.idle,
      );
      final suggestions = <WorkOrder>[];
      final existing = <String, Set<String>>{};

      WorkSuggestionPipeline.run(
        unit: unit,
        unitType: unit.type,
        unitRegionId: 'ow',
        atProvinceId: 'ow|p1',
        workTarget: kWorkTargetBuildImprovement,
        existingTargetsByUnit: existing,
        suggestions: suggestions,
        candidatesProvider: () => [
          WorkOrder(
            unitId: unit.id,
            target: kWorkTargetBuildImprovement,
            targetTileKey: 'a',
          ),
        ],
        candidateAcceptor: (_) => false,
        noCandidateReason: 'no_valid_tile',
        engineRejectedReason: 'rejected_by_test',
      );

      expect(suggestions, isEmpty);
      final lines = _suggestWorkLines(capturedEvents);
      expect(lines.single, contains('reason=rejected_by_test'));
    });
  });
}
