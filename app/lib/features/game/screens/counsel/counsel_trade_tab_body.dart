// Counsel screen body — Trade tab listing and Apply/Agree actions. Refs #4282.

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import 'trade_counsel_l10n.dart';

final class CounselTradeCallbacks {
  const CounselTradeCallbacks({
    this.onApplyBook,
    this.onAgreeLine,
  });

  final VoidCallback? onApplyBook;
  final void Function(TradeOrder order)? onAgreeLine;
}

class CounselTradeTabBody extends StatelessWidget {
  const CounselTradeTabBody({
    super.key,
    required this.recommendations,
    required this.book,
    required this.highlightRecommendationId,
    required this.l10n,
    required this.canEdit,
    this.callbacks = const CounselTradeCallbacks(),
  });

  final List<TradeCounselRecommendation> recommendations;
  final List<TradeOrder> book;
  final String? highlightRecommendationId;
  final AppLocalizations l10n;
  final bool canEdit;
  final CounselTradeCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return _CounselTradeEmptyState(l10n: l10n);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canEdit && callbacks.onApplyBook != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: CtNinePatchButton(
              key: const ValueKey<String>('counsel_apply_trade_book'),
              onPressed: callbacks.onApplyBook,
              child: Text(l10n.tradeCounsel_action_applyBook),
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: recommendations.length,
            separatorBuilder: (_, _) => CtGap.m,
            itemBuilder: (context, index) {
              final recommendation = recommendations[index];
              final highlighted =
                  highlightRecommendationId != null &&
                  recommendation.recommendationId ==
                      highlightRecommendationId;
              return CounselTradeRecommendationCard(
                recommendation: recommendation,
                highlighted: highlighted,
                l10n: l10n,
                canEdit: canEdit,
                callbacks: callbacks,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CounselTradeEmptyState extends StatelessWidget {
  const _CounselTradeEmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.tradeCounsel_empty,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: EditorialMonoclePalette.muted,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class CounselTradeRecommendationCard extends StatelessWidget {
  const CounselTradeRecommendationCard({
    super.key,
    required this.recommendation,
    required this.highlighted,
    required this.l10n,
    required this.canEdit,
    required this.callbacks,
  });

  final TradeCounselRecommendation recommendation;
  final bool highlighted;
  final AppLocalizations l10n;
  final bool canEdit;
  final CounselTradeCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final brief = tradeCounselBriefForReason(
      l10n,
      recommendation.briefReasonKey,
    );
    final title = tradeCounselTitleForRecommendation(l10n, recommendation);
    final theme = Theme.of(context);
    final onAgree = callbacks.onAgreeLine;

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: highlighted
                          ? EditorialMonoclePalette.accentBright
                          : EditorialMonoclePalette.accentDim,
                    ),
                  ),
                ),
                if (recommendation.isHighlight)
                  Text(
                    '★',
                    style: TextStyle(
                      color: EditorialMonoclePalette.accentBright,
                    ),
                  ),
              ],
            ),
            CtGap.m,
            Text(brief, style: theme.textTheme.bodyMedium),
            if (canEdit && onAgree != null) ...[
              CtGap.m,
              CtNinePatchButton(
                key: ValueKey<String>(
                  'counsel_agree_trade_${recommendation.recommendationId}',
                ),
                onPressed: () => onAgree(recommendation.order),
                child: Text(l10n.tradeCounsel_action_agree),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
