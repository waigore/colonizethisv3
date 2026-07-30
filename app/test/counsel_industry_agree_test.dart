// Counsel Industry tab Agree actions. SPEC/ui/counsel-panel.md (Refs #4191).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/screens/counsel/counsel_industry_tab_body.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'app_shell_harness.dart';
import 'production_panel_test_support.dart';
import 'widget_test_pumps.dart';

IndustryCounselRecommendation _produceRec(String recipeId) {
  return IndustryCounselRecommendation(
    recommendationId: 'produce:$recipeId',
    kind: IndustryCounselRecommendationKind.produceRecipe,
    rankScore: 20,
    briefReasonKey: IndustryCounselReasonKey.outputShortage,
    detailReasonKeys: const [IndustryCounselReasonKey.outputShortage],
    recipeId: recipeId,
    suggestedDesiredOutput: 2,
  );
}

IndustryCounselRecommendation _trainRec(WorkerTier tier) {
  return IndustryCounselRecommendation(
    recommendationId: 'train:${tier.name}',
    kind: IndustryCounselRecommendationKind.trainWorker,
    rankScore: 15,
    briefReasonKey: IndustryCounselReasonKey.labourDeficit,
    detailReasonKeys: const [IndustryCounselReasonKey.labourDeficit],
    trainTier: tier,
  );
}

void main() {
  suppressLogsForTests();

  Widget buildTab({
    required List<IndustryCounselRecommendation> recommendations,
    bool canEdit = true,
    CounselIndustryCallbacks callbacks = const CounselIndustryCallbacks(),
  }) {
    final l10n = lookupAppLocalizations(const Locale('en'));
    return buildAppShell(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      child: CounselIndustryTabBody(
        recommendations: recommendations,
        highlightRecommendationId: null,
        l10n: l10n,
        canEdit: canEdit,
        callbacks: callbacks,
      ),
    );
  }

  group('Counsel Industry Agree actions', () {
    final stubCallbacks = CounselIndustryCallbacks(
      onApplyProduceAllocation: _noop,
      onAgreeTrain: _noopTier,
      onOpenDevelopment: _noop,
    );

    testWidgets('editable produce card shows apply allocation button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTab(
          recommendations: [_produceRec('lumber_from_timber')],
          callbacks: stubCallbacks,
        ),
      );
      await pumpSettleCapped(tester);

      expect(
        find.byKey(const ValueKey<String>('counsel_apply_produce_allocation')),
        findsOneWidget,
      );
      expect(
        find.text('Apply recommended industry allocation'),
        findsOneWidget,
      );
    });

    testWidgets('apply produce allocation invokes callback', (
      WidgetTester tester,
    ) async {
      var applied = false;
      await tester.pumpWidget(
        buildTab(
          recommendations: [_produceRec('lumber_from_timber')],
          callbacks: CounselIndustryCallbacks(
            onApplyProduceAllocation: () => applied = true,
          ),
        ),
      );
      await pumpSettleCapped(tester);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('counsel_apply_produce_allocation'),
        ),
      );
      await pumpSettleCapped(tester);

      expect(applied, isTrue);
    });

    testWidgets('read-only hides Agree controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTab(
          recommendations: [
            _produceRec('lumber_from_timber'),
            _trainRec(WorkerTier.peasant),
          ],
          canEdit: false,
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.byType(CtNinePatchButton), findsNothing);
    });

    testWidgets('train card shows Agree button', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTab(
          recommendations: [_trainRec(WorkerTier.peasant)],
          callbacks: stubCallbacks,
        ),
      );
      await pumpSettleCapped(tester);

      expect(
        find.byKey(
          const ValueKey<String>('counsel_agree_train_peasant'),
        ),
        findsOneWidget,
      );
      expect(find.text('Agree'), findsOneWidget);
    });

    testWidgets('empty state shows no pressing advice copy', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTab(recommendations: const [], callbacks: stubCallbacks),
      );
      await pumpSettleCapped(tester);

      expect(
        find.text('No pressing industry advice this turn.'),
        findsOneWidget,
      );
      expect(find.byType(CtNinePatchButton), findsNothing);
    });
  });
}

void _noop() {}

void _noopTier(WorkerTier _) {}
