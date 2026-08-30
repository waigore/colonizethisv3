// Default-timeout pins extracted from
// e2e_pick_first_valid_work_tile_and_await_overlay_clear_test.dart (#4598).
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

void registerE2ePickFirstValidWorkTileAndAwaitOverlayClearConstantsGroup() {
  group('Default constants', () {
    test(
      'kE2eDefaultCivilianWorkTileAppearTimeout matches legacy 15 s budget',
      () {
        expect(
          kE2eDefaultCivilianWorkTileAppearTimeout,
          const Duration(seconds: 15),
          reason:
              'A silent budget bump would change wall-clock guarantees for '
              'every call site that relies on the default; require an explicit '
              'override at the call site instead. Refs GitHub #2336 / AC4.',
        );
      },
    );

    test(
      'kE2eDefaultCivilianWorkTileClearTimeout matches legacy 5 s budget',
      () {
        expect(
          kE2eDefaultCivilianWorkTileClearTimeout,
          const Duration(seconds: 5),
          reason:
              'A silent budget bump would change wall-clock guarantees for '
              'every call site that relies on the default; require an explicit '
              'override at the call site instead. Refs GitHub #2336 / AC4.',
        );
      },
    );
  });

}
