import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test('confirm lines name matching, prices, and First right', () {
    final lines = favoredTradingPartnerConfirmLines('Spain');
    final body = lines.join('\n');
    expect(body, contains('No treasury charge'));
    expect(body, contains('Favored Trading Partners'));
    expect(body, contains('same bid rank'));
    expect(body, contains('Prices do not change'));
    expect(body, contains('First right of refusal'));
    expect(lines.any((l) => l.startsWith('When:')), isFalse);
    expect(body, isNot(contains('65')));
    expect(body, isNot(contains('establishFtp')));
  });

  test('incoming reject line names the offering court', () {
    expect(
      favoredTradingPartnerRejectEffectLine('Portugal'),
      'Effect: You decline Favored Trading Partner with Portugal.',
    );
  });
}
