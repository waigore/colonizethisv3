// Shared Deal Book leftover-reason golden harness (Refs #4500).
// Concern split under repo.app_test_file_size.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen_deal_book.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'trade_screen_test_support.dart';

const String kDealBookLeftoverGoldensHumanPlayerId = kTradeTestHumanPlayerId;
const Size kDealBookLeftoverGoldensPanelViewport = Size(400, 360);
const Size kDealBookLeftoverGoldensRowViewport = Size(520, 160);

Future<void> pumpDealBookLeftoverReasonGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Game game,
  required Size viewport,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: viewport,
    center: false,
    includeLocalizations: true,
    child: SizedBox(
      width: viewport.width,
      height: viewport.height,
      child: SingleChildScrollView(
        child: DealBookTabContent(
          game: game,
          playerId: kDealBookLeftoverGoldensHumanPlayerId,
        ),
      ),
    ),
  );
}
