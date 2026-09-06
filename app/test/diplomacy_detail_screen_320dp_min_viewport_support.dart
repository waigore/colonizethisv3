// Shared 320 dp DiplomacyDetailScreen pump (Refs #4734 Slice F).
// SPEC: SPEC/ui/mobile-adaptation.md § 7.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy/diplomacy_detail_screen.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_detail_screen_test_support.dart';
import 'min_viewport_harness.dart';

const Size kDiplomacyDetailScreen320MinViewport = Size(kMinViewportWidth, 640);
const Size kDiplomacyDetailScreen320WideViewport = Size(1024, 768);

Future<void> pumpDiplomacyDetailScreen320(
  WidgetTester tester, {
  required Size size,
  required Game game,
  required FactionKind kind,
  required DiplomacyRelation? relation,
}) async {
  await pumpAtMinViewport(
    tester,
    size: size,
    child: DiplomacyDetailScreen(
      game: game,
      humanPlayerId: diplomacyDetailHumanId,
      factionId: diplomacyDetailOtherId,
      factionDisplayName: 'Other GP',
      kind: kind,
      relation: relation,
    ),
    settle: true,
  );
}
