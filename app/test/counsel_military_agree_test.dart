// Counsel Military tab Agree actions. SPEC/ui/counsel-panel.md (Refs #4307).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/military_counsel_api.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/screens/counsel/counsel_military_tab_body.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'app_shell_harness.dart';
import 'panel_fixtures/train.dart';
import 'widget_test_pumps.dart';

MilitaryCounselRecommendation _trainRec() {
  return MilitaryCounselRecommendation(
    recommendationId: 'train:peasant_levies',
    kind: MilitaryCounselRecommendationKind.trainUnit,
    rankScore: 10,
    briefReasonKey: MilitaryCounselReasonKey.affordableTrain,
    detailReasonKeys: const [MilitaryCounselReasonKey.affordableTrain],
    unitType: 'peasant_levies',
    count: 2,
    costSnapshot: const MilitaryCounselBuildCostSnapshot(
      treasuryCost: 10,
      materialCosts: {},
      peasantCost: 1,
    ),
  );
}

MilitaryCounselRecommendation _invadeRec() {
  return MilitaryCounselRecommendation(
    recommendationId: 'invade:army1:oldWorld|p2',
    kind: MilitaryCounselRecommendationKind.invade,
    rankScore: 5,
    briefReasonKey: MilitaryCounselReasonKey.declareWarInvasion,
    detailReasonKeys: const [MilitaryCounselReasonKey.declareWarInvasion],
    armyId: 'army1',
    destinationProvinceId: 'oldWorld|p2',
    destinationProvinceLabel: 'Border Province',
    ownerFactionId: 'gp2',
    requiresDeclareWar: true,
    invasionIntel: const MilitaryCounselInvasionIntelSummary(
      intelLevel: MilitaryCounselInvasionIntelLevel.unknown,
    ),
  );
}

void main() {
  suppressLogsForTests();

  Widget buildTab({
    required List<MilitaryCounselRecommendation> recommendations,
    bool canEdit = true,
    CounselMilitaryCallbacks callbacks = const CounselMilitaryCallbacks(),
  }) {
    final l10n = lookupAppLocalizations(const Locale('en'));
    return buildAppShell(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      child: CounselMilitaryTabBody(
        game: buildUnitPanelsTestGame(),
        recommendations: recommendations,
        highlightRecommendationId: null,
        l10n: l10n,
        canEdit: canEdit,
        callbacks: callbacks,
      ),
    );
  }

  group('Counsel Military Agree actions', () {
    final stubCallbacks = CounselMilitaryCallbacks(
      onAgreeTrain: _noopTrain,
      onAgreeInvade: _noopInvade,
    );

    testWidgets('train card shows Agree button', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTab(recommendations: [_trainRec()], callbacks: stubCallbacks),
      );
      await pumpSettleCapped(tester);

      expect(
        find.byKey(
          const ValueKey<String>('counsel_agree_military_train_peasant_levies'),
        ),
        findsOneWidget,
      );
      expect(find.text('Agree'), findsOneWidget);
    });

    testWidgets('invade card shows Agree button', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTab(recommendations: [_invadeRec()], callbacks: stubCallbacks),
      );
      await pumpSettleCapped(tester);

      expect(
        find.byKey(
          const ValueKey<String>(
            'counsel_agree_military_invade_invade:army1:oldWorld|p2',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('train Agree invokes callback', (WidgetTester tester) async {
      MilitaryCounselRecommendation? agreed;
      await tester.pumpWidget(
        buildTab(
          recommendations: [_trainRec()],
          callbacks: CounselMilitaryCallbacks(
            onAgreeTrain: (rec) => agreed = rec,
          ),
        ),
      );
      await pumpSettleCapped(tester);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('counsel_agree_military_train_peasant_levies'),
        ),
      );
      await pumpSettleCapped(tester);

      expect(agreed?.unitType, 'peasant_levies');
    });

    testWidgets('read-only hides Agree controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTab(
          recommendations: [_trainRec(), _invadeRec()],
          canEdit: false,
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.byType(CtNinePatchButton), findsNothing);
    });

    testWidgets('empty state shows no pressing advice copy', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTab(recommendations: const [], callbacks: stubCallbacks),
      );
      await pumpSettleCapped(tester);

      expect(
        find.text('No pressing military advice this turn.'),
        findsOneWidget,
      );
      expect(find.byType(CtNinePatchButton), findsNothing);
    });
  });
}

void _noopTrain(MilitaryCounselRecommendation _) {}

void _noopInvade(MilitaryCounselRecommendation _) {}
