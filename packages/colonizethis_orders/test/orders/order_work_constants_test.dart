import 'dart:io';

import 'package:colonizethis_logic/colonizethis_logic.dart' as barrel;
import 'package:colonizethis_logic/src/constants.dart' as core_constants;
import 'package:colonizethis_orders/src/orders/order_work_constants.dart'
    as order_constants;
import 'package:colonizethis_test/test.dart';

/// Order/work-domain constant ownership (Refs #3290 — colonizethis_orders
/// extraction prerequisite). The definitions live in the `orders` domain at
/// `orders/order_work_constants.dart`; the neutral `lib/src/constants.dart`
/// re-exports them so existing `package:colonizethis_logic` consumers keep
/// their import paths unchanged during the package split.
void main() {
  group('order_work_constants ownership (Refs #3290)', () {
    test('work-target / mineral / prospect constants are defined in the orders '
        'domain file', () {
      expect(order_constants.kWorkTargetExplore, 'explore');
      expect(order_constants.kWorkTargetProspect, 'prospect');
      expect(order_constants.kWorkTargetStealTech, 'steal_tech');
      expect(order_constants.kWorkTargetPurchaseLand, 'purchase_land');
      expect(order_constants.kWorkTargetBuildRail, 'build_rail');
      expect(order_constants.kMineralResourceIds, contains('iron'));
      expect(order_constants.kMineralResourceIds, contains('gold'));
      expect(order_constants.isProspectableTerrainId('not_a_terrain'), isFalse);
      expect(order_constants.isProspectableTerrainId(null), isFalse);
      expect(order_constants.isProspectableTerrainId(''), isFalse);
    });

    test(
      'lib/src/constants.dart re-exports the same order constants (back-compat)',
      () {
        // Identity across import paths: the neutral shim and the orders-domain
        // file resolve to the same declarations.
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
      },
    );

    test(
      'public colonizethis_logic barrel still exposes the order constants',
      () {
        expect(barrel.kWorkTargetExplore, 'explore');
        expect(barrel.kMineralResourceIds, contains('coal'));
        expect(barrel.isProspectableTerrainId('not_a_terrain'), isFalse);
      },
    );

    test(
      'definitions moved out of the neutral core file into the orders domain',
      () {
        // Tests run from packages/colonizethis_orders; paths are repo-relative.
        final ownerFile = File(
          'lib/src/orders/order_work_constants.dart',
        );
        final coreFile = File(
          '../colonizethis_logic/lib/src/constants.dart',
        );
        expect(
          ownerFile.existsSync(),
          isTrue,
          reason: 'orders domain must own the order/work constants file',
        );
        final ownerSrc = ownerFile.readAsStringSync();
        final coreSrc = coreFile.readAsStringSync();

        // The orders-domain file declares the constants.
        expect(
          ownerSrc.contains("const String kWorkTargetExplore = 'explore';"),
          isTrue,
        );
        // The neutral core file no longer declares them; it only re-exports.
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
      },
    );
  });
}
