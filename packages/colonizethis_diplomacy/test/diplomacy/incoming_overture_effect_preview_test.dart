import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  const offerer = 'Spain';

  IncomingOvertureEffectLines linesFor(OvertureStage stage) =>
      buildIncomingOvertureEffectLines(
        offererDisplayName: offerer,
        stage: stage,
      );

  test('NAP accept states pact, no treasury charge, and war not blocked', () {
    final lines = linesFor(OvertureStage.nap);
    expect(lines.acceptEffect, startsWith('Effect:'));
    expect(lines.acceptEffect, contains('Non-Aggression Pact'));
    expect(lines.acceptEffect, contains(offerer));
    expect(lines.acceptEffect.toLowerCase(), contains('treasury'));
    expect(lines.acceptEffect.toLowerCase(), contains('declare war'));
    expect(lines.acceptEffect, isNot(contains('joinEmpire')));
    expect(lines.acceptEffect, isNot(contains('OvertureStage')));
  });

  test('Join Empire accept states absorption without enum ids', () {
    final lines = linesFor(OvertureStage.joinEmpire);
    expect(lines.acceptEffect, contains('absorbed'));
    expect(lines.acceptEffect, contains('provinces transfer'));
    expect(lines.acceptEffect, contains(offerer));
    expect(lines.acceptEffect, isNot(contains('joinEmpire')));
    expect(lines.acceptEffect, isNot(contains('OvertureStage')));
  });

  test('Consulate and Embassy accept state the human pays nothing', () {
    final consulate = linesFor(OvertureStage.tradeConsulate);
    expect(consulate.acceptEffect, contains('Trade Consulate'));
    expect(consulate.acceptEffect, contains('You pay nothing'));
    expect(consulate.acceptEffect, contains('charged only if you accept'));

    final embassy = linesFor(OvertureStage.embassy);
    expect(embassy.acceptEffect, contains('Embassy'));
    expect(embassy.acceptEffect, contains('You pay nothing'));
  });

  test('reject copy is stage-stable and invents no standing penalty', () {
    for (final stage in OvertureStage.values) {
      if (stage == OvertureStage.none) continue;
      final lines = linesFor(stage);
      expect(lines.rejectEffect, startsWith('Effect:'));
      expect(lines.rejectEffect, contains('lapses'));
      expect(lines.rejectEffect, contains('does not advance'));
      expect(lines.rejectEffect.toLowerCase(), contains('pay nothing'));
      expect(lines.rejectEffect.toLowerCase(), isNot(contains('standing')));
      expect(lines.rejectEffect.toLowerCase(), isNot(contains('score')));
      expect(lines.rejectEffect.toLowerCase(), isNot(contains('penalty')));
      expect(lines.rejectEffect, isNot(contains('-50')));
      expect(lines.rejectEffect, isNot(contains('-10')));
    }
  });
}
