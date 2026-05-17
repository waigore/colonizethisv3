import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

/// SPEC/game/ships-and-naval.md: every tech-unlocked ship + baseline carrack has
/// economy and naval stats entries.
void main() {
  group('ship catalog alignment', () {
    test('carrack has no unlocking tech and full catalog entries', () {
      expect(unlockingTechByShipId['carrack'], isNull);
      expect(ShipEconomyCatalog.byId['carrack'], isNotNull);
      expect(NavalStatsCatalog.byId['carrack'], isNotNull);
    });

    test(
      'every shipUnlockIds target has ShipEconomyCatalog and NavalStatsCatalog',
      () {
        final shipIds = unlockingTechByShipId.keys.toList()..sort();
        expect(shipIds, isNotEmpty);
        for (final id in shipIds) {
          expect(
            ShipEconomyCatalog.byId[id],
            isNotNull,
            reason: 'missing ShipEconomyEntry for $id',
          );
          expect(
            NavalStatsCatalog.byId[id],
            isNotNull,
            reason: 'missing NavalStatsEntry for $id',
          );
        }
      },
    );

    test('every ship has food upkeep 2 per workers-and-population / ships-and-naval', () {
      for (final e in ShipEconomyCatalog.all) {
        expect(e.foodUpkeep, 2, reason: e.shipTypeId);
      }
    });

    test('ShipEconomyCatalog.all matches byId keys exactly', () {
      final fromList = {for (final e in ShipEconomyCatalog.all) e.shipTypeId};
      expect(fromList, NavalStatsCatalog.byId.keys.toSet());
      expect(fromList, ShipEconomyCatalog.byId.keys.toSet());
    });

    test('warships have zero cargoHold, merchants positive', () {
      const warships = {
        'sloop',
        'frigate',
        'raider',
        kTechIdShipOfTheLine,
        'ironclad',
      };
      const merchants = {
        'carrack',
        'fluyte',
        'trader',
        'galleon',
        'indiaman',
        'clipper',
        'merchant_steamship',
      };
      for (final id in warships) {
        expect(
          NavalStatsCatalog.byId[id]!.cargoHold,
          0,
          reason: '$id should be warship (cargo 0)',
        );
      }
      for (final id in merchants) {
        expect(
          NavalStatsCatalog.byId[id]!.cargoHold,
          greaterThan(0),
          reason: '$id should be merchant',
        );
      }
    });
  });
}
