// Counsel screen body — Industry tab listing. Refs #4190 / #4191.

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_gap.dart';
import '../../widgets/production/industry_counsel_l10n.dart';

class CounselIndustryTabBody extends StatelessWidget {
  const CounselIndustryTabBody({
    super.key,
    required this.recommendations,
    required this.highlightRecommendationId,
    required this.l10n,
  });

  final List<IndustryCounselRecommendation> recommendations;
  final String? highlightRecommendationId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return _CounselIndustryEmptyState(l10n: l10n);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: recommendations.length,
      separatorBuilder: (_, __) => CtGap.m,
      itemBuilder: (context, index) {
        final recommendation = recommendations[index];
        final highlighted =
            highlightRecommendationId != null &&
            recommendation.recommendationId == highlightRecommendationId;
        return CounselIndustryRecommendationCard(
          recommendation: recommendation,
          highlighted: highlighted,
          l10n: l10n,
        );
      },
    );
  }
}

class _CounselIndustryEmptyState extends StatelessWidget {
  const _CounselIndustryEmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.industryCounsel_empty,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: EditorialMonoclePalette.muted,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class CounselIndustryRecommendationCard extends StatelessWidget {
  const CounselIndustryRecommendationCard({
    super.key,
    required this.recommendation,
    required this.highlighted,
    required this.l10n,
  });

  final IndustryCounselRecommendation recommendation;
  final bool highlighted;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final brief = industryCounselBriefForReason(
      l10n,
      recommendation.briefReasonKey,
    );
    final detail = recommendation.detailReasonKeys
        .map((key) => industryCounselDetailForReason(l10n, key))
        .join(' ');
    final title = industryCounselTitleForRecommendation(l10n, recommendation);
    final theme = Theme.of(context);

    return Material(
      color: highlighted
          ? EditorialMonoclePalette.surfaceLite.withValues(alpha: 0.9)
          : EditorialMonoclePalette.surface.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: highlighted
              ? EditorialMonoclePalette.accentBright
              : EditorialMonoclePalette.accentDim,
          width: highlighted ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: highlighted
                    ? EditorialMonoclePalette.accentBright
                    : EditorialMonoclePalette.accentDim,
              ),
            ),
            CtGap.m,
            Text(brief, style: theme.textTheme.bodyMedium),
            if (highlighted || detail != brief) ...[
              CtGap.m,
              Text(
                detail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: EditorialMonoclePalette.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
