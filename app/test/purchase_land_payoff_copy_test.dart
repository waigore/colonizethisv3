// Display-only Purchase land payoff gist (Refs #4630).
import 'package:colonizethis_app/features/game/widgets/units/civilian/purchase_land_payoff_copy.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  test(
    'tradeable gist names the good, court, first bid, and that land stays theirs',
    () {
      final line = purchaseLandPayoffGistLine(
        l10n: l10n,
        resourceName: 'Timber',
        courtName: 'Portugal',
        isRiches: false,
      );
      expect(line, contains('Timber'));
      expect(line, contains('Portugal'));
      expect(line, contains('first bid'));
      expect(line.toLowerCase(), contains('land stays'));
      expect(line.toLowerCase(), isNot(contains('warehouse')));
      expect(line, isNot(contains('purchase_land')));
      expect(line, isNot(contains('this Next turn')));
    },
  );

  test('riches gist names treasury handoff and does not claim first bid', () {
    final line = purchaseLandPayoffGistLine(
      l10n: l10n,
      resourceName: 'Gold',
      courtName: 'Ashanti',
      isRiches: true,
    );
    expect(line, contains('Gold'));
    expect(line, contains('Ashanti'));
    expect(line.toLowerCase(), contains('treasury'));
    expect(line.toLowerCase(), isNot(contains('first bid')));
    expect(line.toLowerCase(), isNot(contains('trade')));
  });

  test('tradeable teaching tooltip reuses Trade First right gist', () {
    final copy = PurchaseLandPayoffCopy(
      gist: purchaseLandPayoffGistLine(
        l10n: l10n,
        resourceName: 'Timber',
        courtName: 'Portugal',
        isRiches: false,
      ),
      isRiches: false,
    );
    expect(
      purchaseLandPayoffTeachingTooltip(l10n: l10n, copy: copy),
      l10n.tradeMarket_firstRightTooltip,
    );
  });

  test('riches teaching tooltip is omitted', () {
    const copy = PurchaseLandPayoffCopy(gist: 'x', isRiches: true);
    expect(purchaseLandPayoffTeachingTooltip(l10n: l10n, copy: copy), isNull);
  });
}
