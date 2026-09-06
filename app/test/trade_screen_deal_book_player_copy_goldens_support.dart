// Shared pump for Deal Book player-language golden tests (Refs #4734 Slice G).

import 'package:colonizethis_app/features/game/screens/trade/trade_screen_deal_book.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'trade_screen_test_support.dart';

const String kDealBookPlayerCopyHumanPlayerId = kTradeTestHumanPlayerId;
const Size kDealBookPlayerCopyPanelViewport = Size(400, 320);
const Size kDealBookPlayerCopyRowViewport = Size(520, 120);

Future<void> pumpDealBookPlayerCopyGolden(
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
          playerId: kDealBookPlayerCopyHumanPlayerId,
        ),
      ),
    ),
  );
}
