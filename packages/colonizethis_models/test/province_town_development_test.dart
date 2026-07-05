import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Province townDevelopmentLevel (Refs #3870)', () {
    test('default is 1', () {
      const p = Province(id: 'oldWorld|p1', regionId: 'oldWorld');
      expect(p.townDevelopmentLevel, kTownDevelopmentLevelMin);
    });

    test('fromJson coerces legacy 0 to 1', () {
      final p = Province.fromJson({
        'id': 'oldWorld|p1',
        'regionId': 'oldWorld',
        'townDevelopmentLevel': 0,
      });
      expect(p.townDevelopmentLevel, 1);
    });

    test('toJson omits default level 1', () {
      const p = Province(id: 'oldWorld|p1', regionId: 'oldWorld');
      expect(p.toJson().containsKey('townDevelopmentLevel'), isFalse);
    });

    test('normalizeTownDevelopmentLevel clamps high values', () {
      expect(normalizeTownDevelopmentLevel(99), kTownDevelopmentLevelMax);
    });
  });
}
