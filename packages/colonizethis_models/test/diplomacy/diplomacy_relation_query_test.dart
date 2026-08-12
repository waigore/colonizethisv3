import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  test('DiplomacyRelation.involvesNation is true for either faction id', () {
    const r = DiplomacyRelation(factionId1: 'gp1', factionId2: 'minor2');
    expect(r.involvesNation('gp1'), isTrue);
    expect(r.involvesNation('minor2'), isTrue);
    expect(r.involvesNation('other'), isFalse);
  });
}
