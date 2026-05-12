import 'package:colonizethis_logic/src/diplomacy/overture_stage_helpers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('OvertureStageProgression.next (Refs #2391 AC1)', () {
    test('none -> tradeConsulate', () {
      expect(OvertureStage.none.next, OvertureStage.tradeConsulate);
    });

    test('tradeConsulate -> embassy', () {
      expect(OvertureStage.tradeConsulate.next, OvertureStage.embassy);
    });

    test('embassy -> nap', () {
      expect(OvertureStage.embassy.next, OvertureStage.nap);
    });

    test('nap -> joinEmpire', () {
      expect(OvertureStage.nap.next, OvertureStage.joinEmpire);
    });

    test('joinEmpire -> null (terminal)', () {
      expect(OvertureStage.joinEmpire.next, isNull);
    });
  });

  group('OvertureStageProgression.previous (Refs #2391 AC1)', () {
    test('tradeConsulate -> none', () {
      expect(OvertureStage.tradeConsulate.previous, OvertureStage.none);
    });

    test('embassy -> tradeConsulate', () {
      expect(OvertureStage.embassy.previous, OvertureStage.tradeConsulate);
    });

    test('nap -> embassy', () {
      expect(OvertureStage.nap.previous, OvertureStage.embassy);
    });

    test('joinEmpire -> nap', () {
      expect(OvertureStage.joinEmpire.previous, OvertureStage.nap);
    });

    test('none -> none (stays terminal)', () {
      expect(OvertureStage.none.previous, OvertureStage.none);
    });
  });

  group(
    'next and previous are mathematical inverses for non-terminal stages',
    () {
      test('previous(next(stage)) == stage for stages with a forward edge', () {
        const stagesWithForward = <OvertureStage>[
          OvertureStage.none,
          OvertureStage.tradeConsulate,
          OvertureStage.embassy,
          OvertureStage.nap,
        ];
        for (final stage in stagesWithForward) {
          final forward = stage.next;
          expect(forward, isNotNull, reason: 'next($stage) should not be null');
          expect(forward!.previous, stage, reason: 'inverse failed for $stage');
        }
      });
    },
  );

  group('top-level shims preserve existing public API', () {
    test('nextOvertureStage delegates to extension', () {
      for (final stage in OvertureStage.values) {
        expect(nextOvertureStage(stage), stage.next);
      }
    });

    test('previousStage delegates to extension', () {
      for (final stage in OvertureStage.values) {
        expect(previousStage(stage), stage.previous);
      }
    });
  });
}
