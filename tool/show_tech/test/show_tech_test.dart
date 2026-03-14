import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('tech catalog', () {
    test('contains basic gathering and transport techs', () {
      expect(techById('crop_rotation'), isNotNull);
      expect(techById('saw_mill'), isNotNull);
      expect(techById('land_enclosure'), isNotNull);
      expect(techById('road_construction'), isNotNull);
      expect(techById('early_steam_engine'), isNotNull);
    });

    test('prerequisites are consistent', () {
      final windSaw = techById('wind_saw_mill')!;
      expect(windSaw.prerequisiteIds, contains('saw_mill'));
      final seedDrill = techById('seed_drill')!;
      expect(seedDrill.prerequisiteIds, contains('land_enclosure'));
      final rail = techById('early_steam_engine')!;
      expect(rail.prerequisiteIds, contains('road_construction'));
    });
  });
}

