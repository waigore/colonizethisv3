import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('tech catalog', () {
    test('contains basic gathering and transport techs', () {
      expect(techById('gathering_1'), isNotNull);
      expect(techById('gathering_2'), isNotNull);
      expect(techById('gathering_3'), isNotNull);
      expect(techById('road_construction'), isNotNull);
      expect(techById('early_steam_engine'), isNotNull);
    });

    test('prerequisites are consistent', () {
      final g2 = techById('gathering_2')!;
      expect(g2.prerequisiteIds, contains('gathering_1'));
      final g3 = techById('gathering_3')!;
      expect(g3.prerequisiteIds, contains('gathering_2'));
      final rail = techById('early_steam_engine')!;
      expect(rail.prerequisiteIds, contains('road_construction'));
    });
  });
}

