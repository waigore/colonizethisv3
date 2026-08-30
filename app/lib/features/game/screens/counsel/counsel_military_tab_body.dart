// Counsel screen body — Military tab listing and Agree actions. Refs #4307.

import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_gap.dart';
import 'counsel_military_recommendation_card.dart';

export 'counsel_military_recommendation_card.dart'
    show
        CounselMilitaryCallbacks,
        CounselMilitaryRecommendationCard,
        CounselMilitaryCardTitleRow,
        CounselMilitaryCardDetailLines;

class CounselMilitaryTabBody extends StatelessWidget {
  const CounselMilitaryTabBody({
    super.key,
    required this.game,
    required this.recommendations,
    required this.highlightRecommendationId,
    required this.l10n,
    required this.canEdit,
    this.callbacks = const CounselMilitaryCallbacks(),
  });

  final Game game;
  final List<MilitaryCounselRecommendation> recommendations;
  final String? highlightRecommendationId;
  final AppLocalizations l10n;
  final bool canEdit;
  final CounselMilitaryCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return _CounselMilitaryEmptyState(l10n: l10n);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: recommendations.length,
      separatorBuilder: (_, _) => CtGap.m,
      itemBuilder: (context, index) {
        final recommendation = recommendations[index];
        final highlighted =
            highlightRecommendationId != null &&
            recommendation.recommendationId == highlightRecommendationId;
        return CounselMilitaryRecommendationCard(
          game: game,
          recommendation: recommendation,
          highlighted: highlighted,
          l10n: l10n,
          canEdit: canEdit,
          callbacks: callbacks,
        );
      },
    );
  }
}

class _CounselMilitaryEmptyState extends StatelessWidget {
  const _CounselMilitaryEmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.militaryCounsel_empty,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: EditorialMonoclePalette.muted,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
