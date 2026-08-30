// Counsel screen body — Development tab listing and Agree actions. Refs #4332.

import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import 'development_counsel_l10n.dart';

final class CounselDevelopmentCallbacks {
  const CounselDevelopmentCallbacks({this.onAgreeBuildPort});

  final void Function(DevelopmentCounselRecommendation recommendation)?
  onAgreeBuildPort;
}

class CounselDevelopmentTabBody extends StatelessWidget {
  const CounselDevelopmentTabBody({
    super.key,
    required this.recommendations,
    required this.highlightRecommendationId,
    required this.l10n,
    required this.canEdit,
    this.callbacks = const CounselDevelopmentCallbacks(),
  });

  final List<DevelopmentCounselRecommendation> recommendations;
  final String? highlightRecommendationId;
  final AppLocalizations l10n;
  final bool canEdit;
  final CounselDevelopmentCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return _CounselDevelopmentEmptyState(l10n: l10n);
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
        return CounselDevelopmentRecommendationCard(
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

class _CounselDevelopmentEmptyState extends StatelessWidget {
  const _CounselDevelopmentEmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.developmentCounsel_empty,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: EditorialMonoclePalette.muted,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class CounselDevelopmentRecommendationCard extends StatelessWidget {
  const CounselDevelopmentRecommendationCard({
    super.key,
    required this.recommendation,
    required this.highlighted,
    required this.l10n,
    required this.canEdit,
    required this.callbacks,
  });

  final DevelopmentCounselRecommendation recommendation;
  final bool highlighted;
  final AppLocalizations l10n;
  final bool canEdit;
  final CounselDevelopmentCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final brief = developmentCounselBriefForReason(
      l10n,
      recommendation.briefReasonKey,
    );
    final title = developmentCounselTitleForRecommendation(
      l10n,
      recommendation,
    );
    final theme = Theme.of(context);
    final agreeEnabled = canEdit && callbacks.onAgreeBuildPort != null;

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
            _CounselDevelopmentCardTitleRow(
              title: title,
              showStar: recommendation.isHighlight,
              theme: theme,
            ),
            CtGap.m,
            Text(brief, style: theme.textTheme.bodyMedium),
            CtGap.m,
            _CounselDevelopmentAgreeButton(
              recommendationId: recommendation.recommendationId,
              agreeLabel: l10n.developmentCounsel_action_agree,
              onPressed: agreeEnabled
                  ? () => callbacks.onAgreeBuildPort!(recommendation)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CounselDevelopmentCardTitleRow extends StatelessWidget {
  const _CounselDevelopmentCardTitleRow({
    required this.title,
    required this.showStar,
    required this.theme,
  });

  final String title;
  final bool showStar;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
        if (showStar)
          Text(
            '★',
            style: theme.textTheme.titleSmall?.copyWith(
              color: EditorialMonoclePalette.accentBright,
            ),
          ),
      ],
    );
  }
}

class _CounselDevelopmentAgreeButton extends StatelessWidget {
  const _CounselDevelopmentAgreeButton({
    required this.recommendationId,
    required this.agreeLabel,
    required this.onPressed,
  });

  final String recommendationId;
  final String agreeLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: CtNinePatchButton(
        key: ValueKey<String>('development_counsel_agree_$recommendationId'),
        onPressed: onPressed,
        child: Text(agreeLabel),
      ),
    );
  }
}
