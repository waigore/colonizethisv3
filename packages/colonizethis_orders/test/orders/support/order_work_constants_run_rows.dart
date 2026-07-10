// Scenario run tear-offs for order/work constants (Refs #3949 wave 3).

import 'dart:io';
import 'package:colonizethis_logic/colonizethis_logic.dart' as barrel;
import 'package:colonizethis_logic/colonizethis_logic.dart' as core_constants;
import 'package:colonizethis_orders/src/orders/order_work_constants.dart'
    as order_constants;
import 'package:colonizethis_test/test.dart';

void owcRunDefinedInOrdersDomain() {
  expect(order_constants.kWorkTargetExplore, isNotEmpty);
  expect(order_constants.kWorkTargetProspect, isNotEmpty);
  expect(order_constants.kWorkTargetCounterSpy, isNotEmpty);
  expect(order_constants.kWorkTargetPurchaseLand, isNotEmpty);
  expect(order_constants.kWorkTargetBuildRail, isNotEmpty);
  expect(order_constants.kMineralResourceIds, contains('iron'));
  expect(order_constants.kMineralResourceIds, contains('gold'));
  expect(order_constants.isProspectableTerrainId('not_a_terrain'), isFalse);
  expect(order_constants.isProspectableTerrainId(null), isFalse);
  expect(order_constants.isProspectableTerrainId(''), isFalse);
}

void owcRunCoreReexportsBackCompat() {
  expect(
    identical(
      core_constants.kMineralResourceIds,
      order_constants.kMineralResourceIds,
    ),
    isTrue,
  );
  expect(core_constants.kWorkTargetExplore, order_constants.kWorkTargetExplore);
}

void owcRunBarrelStillExposes() {
  expect(barrel.kWorkTargetExplore, order_constants.kWorkTargetExplore);
  expect(barrel.kMineralResourceIds, contains('coal'));
  expect(barrel.isProspectableTerrainId('not_a_terrain'), isFalse);
}

void owcRunMovedOutOfNeutralCore() {
  final ownerFile = File('lib/src/orders/order_work_constants.dart');
  final coreFile = File('../colonizethis_logic/lib/src/constants.dart');
  expect(
    ownerFile.existsSync(),
    isTrue,
    reason: 'orders domain must own the order/work constants file',
  );
  final ownerSrc = ownerFile.readAsStringSync();
  final coreSrc = coreFile.readAsStringSync();
  expect(
    ownerSrc.contains("const String kWorkTargetExplore = 'explore';"),
    isTrue,
  );
  expect(
    coreSrc.contains("const String kWorkTargetExplore = 'explore';"),
    isFalse,
    reason:
        'order/work constant definitions must not live in the '
        'neutral lib/src/constants.dart core',
  );
  expect(
    coreSrc.contains(
      "export 'package:colonizethis_orders/src/orders/order_work_constants.dart';",
    ),
    isTrue,
    reason:
        'the neutral core must re-export the orders-domain constants '
        'for backward compatibility',
  );
}
