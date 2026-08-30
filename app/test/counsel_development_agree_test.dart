// Counsel Development tab Agree actions. SPEC/ui/counsel-panel.md (Refs #4332).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/screens/counsel/counsel_development_tab_body.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'app_shell_harness.dart';
import 'widget_test_pumps.dart';

DevelopmentCounselRecommendation _portRec() {
  return const DevelopmentCounselRecommendation(
    recommendationId: 'build_port:oldWorld|P1|0|0',
    kind: DevelopmentCounselRecommendationKind.buildPort,
    rankScore: 290,
    briefReasonKey: DevelopmentCounselReasonKey.resourceCoast,
    detailReasonKeys: [DevelopmentCounselReasonKey.resourceCoast],
    isHighlight: true,
    targetTileKey: 'oldWorld|P1|0|0',
    provinceId: 'oldWorld|P1',
    provinceDisplayName: 'Harbor',
    unitId: 'e1',
  );
}

void main() {
  suppressLogsForTests();

  Widget buildTab({
    required List<DevelopmentCounselRecommendation> recommendations,
    bool canEdit = true,
    CounselDevelopmentCallbacks callbacks = const CounselDevelopmentCallbacks(),
  }) {
    final l10n = lookupAppLocalizations(const Locale('en'));
    return buildAppShell(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      child: CounselDevelopmentTabBody(
        recommendations: recommendations,
        highlightRecommendationId: null,
        l10n: l10n,
        canEdit: canEdit,
        callbacks: callbacks,
      ),
    );
  }

  group('Counsel Development Agree actions', () {
    testWidgets('shows empty state when no recommendations', (tester) async {
      await tester.pumpWidget(buildTab(recommendations: const []));
      await pumpSettleCapped(tester);
      expect(find.text('No pressing development advice this turn.'), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsNothing);
    });

    testWidgets('Agree fires when editable', (tester) async {
      DevelopmentCounselRecommendation? agreed;
      await tester.pumpWidget(
        buildTab(
          recommendations: [_portRec()],
          callbacks: CounselDevelopmentCallbacks(
            onAgreeBuildPort: (r) => agreed = r,
          ),
        ),
      );
      await pumpSettleCapped(tester);
      expect(find.textContaining('Build port'), findsWidgets);
      await tester.tap(
        find.byKey(
          const ValueKey<String>(
            'development_counsel_agree_build_port:oldWorld|P1|0|0',
          ),
        ),
      );
      await pumpSettleCapped(tester);
      expect(agreed?.recommendationId, 'build_port:oldWorld|P1|0|0');
    });

    testWidgets('Agree disabled when read-only', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTab(
          recommendations: [_portRec()],
          canEdit: false,
          callbacks: CounselDevelopmentCallbacks(
            onAgreeBuildPort: (_) => tapped = true,
          ),
        ),
      );
      await pumpSettleCapped(tester);
      await tester.tap(
        find.byKey(
          const ValueKey<String>(
            'development_counsel_agree_build_port:oldWorld|P1|0|0',
          ),
        ),
      );
      await pumpSettleCapped(tester);
      expect(tapped, isFalse);
    });
  });
}
