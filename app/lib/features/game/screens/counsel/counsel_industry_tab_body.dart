// Counsel screen body — Industry tab listing and Agree actions. Refs #4190 / #4191.

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../widgets/production/industry_counsel_l10n.dart';

/// Callbacks for Industry Counsel Agree actions (Refs #4191).
final class CounselIndustryCallbacks {
  const CounselIndustryCallbacks({
    this.onApplyProduceAllocation,
    this.onAgreeTrain,
    this.onOpenDevelopment,
  });

  final VoidCallback? onApplyProduceAllocation;
  final void Function(WorkerTier tier)? onAgreeTrain;
  final VoidCallback? onOpenDevelopment;
}

class CounselIndustryTabBody extends StatelessWidget {
  const CounselIndustryTabBody({
    super.key,
    required this.recommendations,
    required this.highlightRecommendationId,
    required this.l10n,
    required this.canEdit,
    this.callbacks = const CounselIndustryCallbacks(),
  });

  final List<IndustryCounselRecommendation> recommendations;
  final String? highlightRecommendationId;
  final AppLocalizations l10n;
  final bool canEdit;
  final CounselIndustryCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return _CounselIndustryEmptyState(l10n: l10n);
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
        return CounselIndustryRecommendationCard(
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
    required this.canEdit,
    required this.callbacks,
  });

  final IndustryCounselRecommendation recommendation;
  final bool highlighted;
  final AppLocalizations l10n;
  final bool canEdit;
  final CounselIndustryCallbacks callbacks;

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
    final action = _buildPrimaryAction(l10n);

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
            if (action != null) ...[
              CtGap.m,
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildPrimaryAction(AppLocalizations l10n) {
    if (!canEdit) return null;
    switch (recommendation.kind) {
      case IndustryCounselRecommendationKind.produceRecipe:
        final onPressed = callbacks.onApplyProduceAllocation;
        if (onPressed == null) return null;
        return CtNinePatchButton(
          key: const ValueKey<String>('counsel_apply_produce_allocation'),
          onPressed: onPressed,
          child: Text(l10n.industryCounsel_action_applyProduceAllocation),
        );
      case IndustryCounselRecommendationKind.trainWorker:
        final tier = recommendation.trainTier;
        final onAgree = callbacks.onAgreeTrain;
        if (tier == null || onAgree == null) return null;
        return CtNinePatchButton(
          key: ValueKey<String>('counsel_agree_train_${tier.name}'),
          onPressed: () => onAgree(tier),
          child: Text(l10n.industryCounsel_action_agreeTrain),
        );
      case IndustryCounselRecommendationKind.unblockFeedstock:
        final onOpen = callbacks.onOpenDevelopment;
        if (onOpen == null) return null;
        return CtNinePatchButton(
          key: const ValueKey<String>('counsel_open_development'),
          onPressed: onOpen,
          child: Text(l10n.industryCounsel_action_openDevelopment),
        );
    }
  }
}
