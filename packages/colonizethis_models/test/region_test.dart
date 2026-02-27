import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Region', () {
    test('fromJson/toJson round-trip', () {
      for (final r in Region.values) {
        expect(RegionJson.fromJson(r.toJson()), r);
      }
    });
    test('fromJson throws for unknown value', () {
      expect(() => RegionJson.fromJson('unknown'), throwsArgumentError);
    });
  });
}
