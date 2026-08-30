import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/features/game/widgets/train/train_naval_ship_role_display.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('TrainNavalShipRoleDisplay', () {
    test('merchant carrack shows Merchant and cargo holds', () {
      expect(TrainNavalShipRoleDisplay.isMerchant('carrack'), isTrue);
      expect(
        TrainNavalShipRoleDisplay.roleLabel(l10n, 'carrack'),
        l10n.naval_units_compositionRoleMerchant,
      );
      expect(
        TrainNavalShipRoleDisplay.capabilityLine(l10n, 'carrack'),
        '+${NavalStatsCatalog.carrack.cargoHold} cargo holds',
      );
    });

    test('warship sloop shows Warship and fast interceptor gist', () {
      expect(TrainNavalShipRoleDisplay.isMerchant('sloop'), isFalse);
      expect(
        TrainNavalShipRoleDisplay.roleLabel(l10n, 'sloop'),
        l10n.naval_units_compositionRoleWarship,
      );
      expect(
        TrainNavalShipRoleDisplay.capabilityLine(l10n, 'sloop'),
        l10n.trainNaval_warshipRoleFastInterceptor,
      );
    });

    test('ship of the line shows battle ship gist', () {
      expect(
        TrainNavalShipRoleDisplay.capabilityLine(l10n, kTechIdShipOfTheLine),
        l10n.trainNaval_warshipRoleBattleShip,
      );
    });

    test('food upkeep line uses catalog value', () {
      expect(
        TrainNavalShipRoleDisplay.foodUpkeepForShip('carrack'),
        ShipEconomyCatalog.carrack.foodUpkeep,
      );
      expect(
        TrainNavalShipRoleDisplay.foodUpkeepLine(
          l10n,
          ShipEconomyCatalog.carrack.foodUpkeep,
        ),
        '${ShipEconomyCatalog.carrack.foodUpkeep} food / turn',
      );
    });
  });
}
