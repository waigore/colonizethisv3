// Order/work constant ownership assertions (Refs #3949 wave 3).

import 'dart:io';

import 'package:colonizethis_logic/colonizethis_logic.dart' as barrel;
import 'package:colonizethis_logic/colonizethis_logic.dart' as core_constants;
import 'package:colonizethis_orders/src/orders/order_work_constants.dart'
    as order_constants;
import 'package:colonizethis_test/test.dart';

enum OrderWorkConstantsTarget {
  definedInOrdersDomain,
  coreReexportsBackCompat,
  barrelStillExposes,
  movedOutOfNeutralCore,
}

void runOrderWorkConstantsExpectation(OrderWorkConstantsTarget target) {
  switch (target) {
    case OrderWorkConstantsTarget.definedInOrdersDomain:
      expect(order_constants.kWorkTargetExplore, 'explore');
      expect(order_constants.kWorkTargetProspect, 'prospect');
      expect(order_constants.kWorkTargetCounterSpy, 'counter_spy');
      expect(order_constants.kWorkTargetPurchaseLand, 'purchase_land');
      expect(order_constants.kWorkTargetBuildRail, 'build_rail');
      expect(order_constants.kMineralResourceIds, contains('iron'));
      expect(order_constants.kMineralResourceIds, contains('gold'));
      expect(order_constants.isProspectableTerrainId('not_a_terrain'), isFalse);
      expect(order_constants.isProspectableTerrainId(null), isFalse);
      expect(order_constants.isProspectableTerrainId(''), isFalse);

    case OrderWorkConstantsTarget.coreReexportsBackCompat:
      expect(
        identical(
          core_constants.kMineralResourceIds,
          order_constants.kMineralResourceIds,
        ),
        isTrue,
      );
      expect(
        core_constants.kWorkTargetExplore,
        order_constants.kWorkTargetExplore,
      );

    case OrderWorkConstantsTarget.barrelStillExposes:
      expect(barrel.kWorkTargetExplore, 'explore');
      expect(barrel.kMineralResourceIds, contains('coal'));
      expect(barrel.isProspectableTerrainId('not_a_terrain'), isFalse);

    case OrderWorkConstantsTarget.movedOutOfNeutralCore:
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
}
