// Visual goldens for the GAME40001 research slot-card turn-preview states
// (Refs #3512): the funded-Medium card (dual-segment bar + RP delta + gold row
// + funding toggles), the None-funding card (no RP delta, collapsed gold row),
// the debt-blocked card (no anticipated segment, greyed gold row), and the
// funding breakdown dialog. These close the widget-golden coverage gap flagged
// on issue #3512 for the user-visible turn-preview ACs.
//
// Each surface is rendered directly under `AppThemes.editorialMonocle` (the
// running-app dark theme) at device pixel ratio 1.0 inside a keyed
// `RepaintBoundary`, matching the committed golden harness pattern
// (`new_game_leader_selection_dialog_golden_test.dart`). The structural
// finder assertions that map these states to their ACs live in
// `research_slot_turn_preview_view_test.dart` and
// `technology_panel_funding_toggles_test.dart`; this file adds the
// `matchesGoldenFile` visual proof the issue requires.
//
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview + Acceptance criteria
// (Slot turn-preview visual golden coverage).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/utils/research_slot_preview.dart';
import 'package:colonizethis_app/features/game/widgets/research_slot_turn_preview_view.dart';
import 'package:colonizethis_app/features/game/widgets/technology_panel.dart';
import 'package:colonizethis_app/l10n/l10n.dart';

// A tier-1 tech (cost 1800 RP after the #3512 rebalance) used as the assigned
// tech for every slot-card golden so the captures are deterministic.
const String _kTechId = kTechIdCropRotation;
const int _kCost = 1800;
const int _kCommitted = 600;

// Medium funding, sufficient treasury: anticipated 300 RP / 150 gold spend.
const ResearchSlotTurnPreview _mediumFunded = ResearchSlotTurnPreview(
  funding: ResearchFundingLevel.medium,
  committedProgress: _kCommitted,
  cost: _kCost,
  baseRpPerTurn: 300,
  industrialBonusRpPerTurn: 0,
  anticipatedRpPerTurn: 300,
  goldCostPerTurn: 150,
  goldSpentThisTurn: 150,
  debtBlocked: false,
);

// None funding: no anticipated spend, gold row collapses.
const ResearchSlotTurnPreview _noneFunding = ResearchSlotTurnPreview(
  funding: ResearchFundingLevel.none,
  committedProgress: _kCommitted,
  cost: _kCost,
  baseRpPerTurn: 0,
  industrialBonusRpPerTurn: 0,
  anticipatedRpPerTurn: 0,
  goldCostPerTurn: 0,
  goldSpentThisTurn: 0,
  debtBlocked: false,
);

// Medium funding but debt-blocked: effective RP is known but applied RP / spend
// are zero, segment B and RP delta are hidden, gold row greyed.
const ResearchSlotTurnPreview _debtBlocked = ResearchSlotTurnPreview(
  funding: ResearchFundingLevel.medium,
  committedProgress: _kCommitted,
  cost: _kCost,
  baseRpPerTurn: 300,
  industrialBonusRpPerTurn: 0,
  anticipatedRpPerTurn: 0,
  goldCostPerTurn: 150,
  goldSpentThisTurn: 0,
  debtBlocked: true,
);

Future<void> _pumpHost(
  WidgetTester tester, {
  required Key boundaryKey,
  required Widget child,
  Size surfaceSize = const Size(380, 360),
}) async {
  addTearDown(tester.view.reset);
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _slotCard({
  required ResearchFundingLevel funding,
  required ResearchSlotTurnPreview preview,
}) {
  return SizedBox(
    width: 340,
    child: ResearchSlotCard(
      slotIndex: 0,
      techId: _kTechId,
      progress: preview.committedProgress,
      cost: preview.cost,
      canEdit: true,
      funding: funding,
      onFundingChanged: (_) {},
      onCancel: () {},
      onChooseTech: () {},
      turnPreview: preview,
    ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: Medium-funded slot card shows toggles, dual-segment bar, RP delta '
    'and gold row (Refs #3512 AC6/AC8/AC12)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('researchSlotCardMediumGolden');
      await _pumpHost(
        tester,
        boundaryKey: boundaryKey,
        child: _slotCard(
          funding: ResearchFundingLevel.medium,
          preview: _mediumFunded,
        ),
      );

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/research_slot_card_medium_funded.png'),
      );
    },
  );

  testWidgets(
    'golden: None-funding slot card hides the RP delta and collapses the gold '
    'row (Refs #3512 AC9)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('researchSlotCardNoneGolden');
      await _pumpHost(
        tester,
        boundaryKey: boundaryKey,
        child: _slotCard(
          funding: ResearchFundingLevel.none,
          preview: _noneFunding,
        ),
      );

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/research_slot_card_none_funding.png'),
      );
    },
  );

  testWidgets(
    'golden: debt-blocked slot card hides segment B / RP delta and greys the '
    'gold row (Refs #3512 AC10)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('researchSlotCardDebtBlockedGolden');
      await _pumpHost(
        tester,
        boundaryKey: boundaryKey,
        child: _slotCard(
          funding: ResearchFundingLevel.medium,
          preview: _debtBlocked,
        ),
      );

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/research_slot_card_debt_blocked.png'),
      );
    },
  );

  testWidgets(
    'golden: research funding breakdown dialog (Refs #3512 AC11)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('researchFundingBreakdownGolden');
      await _pumpHost(
        tester,
        boundaryKey: boundaryKey,
        surfaceSize: const Size(420, 360),
        child: const ResearchFundingBreakdownDialog(preview: _mediumFunded),
      );

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/research_funding_breakdown_dialog.png'),
      );
    },
  );
}
