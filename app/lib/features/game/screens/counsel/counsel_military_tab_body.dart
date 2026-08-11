// Counsel screen body — Military tab listing and Agree actions. Refs #4307.

import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import 'military_counsel_l10n.dart';

final class CounselMilitaryCallbacks {
  const CounselMilitaryCallbacks({
    this.onAgreeTrain,
    this.onAgreeInvade,
  });

  final void Function(MilitaryCounselRecommendation recommendation)?
  onAgreeTrain;
  final void Function(MilitaryCounselRecommendation recommendation)?
  onAgreeInvade;
}

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

class CounselMilitaryRecommendationCard extends StatelessWidget {
  const CounselMilitaryRecommendationCard({
    super.key,
    required this.game,
    required this.recommendation,
    required this.highlighted,
    required this.l10n,
    required this.canEdit,
    required this.callbacks,
  });

  final Game game;
  final MilitaryCounselRecommendation recommendation;
  final bool highlighted;
  final AppLocalizations l10n;
  final bool canEdit;
  final CounselMilitaryCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final brief = militaryCounselBriefForReason(
      l10n,
      recommendation.briefReasonKey,
    );
    final title = militaryCounselTitleForRecommendation(l10n, recommendation);
    final theme = Theme.of(context);
    final action = _buildPrimaryAction(l10n);
    final detailLines = _detailLines(l10n);

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
            if (detailLines.isNotEmpty) ...[
              CtGap.m,
              for (final line in detailLines)
                Text(
                  line,
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

  List<String> _detailLines(AppLocalizations l10n) {
    return switch (recommendation.kind) {
      MilitaryCounselRecommendationKind.trainUnit => [
        militaryCounselCostSummary(l10n, recommendation),
      ],
      MilitaryCounselRecommendationKind.invade => [
        l10n.militaryCounsel_ownerLine(
          militaryCounselOwnerLabel(l10n, game, recommendation),
        ),
        ...militaryCounselInvasionIntelLines(
          l10n,
          recommendation.invasionIntel,
        ),
      ],
    };
  }

  Widget? _buildPrimaryAction(AppLocalizations l10n) {
    if (!canEdit) return null;
    return switch (recommendation.kind) {
      MilitaryCounselRecommendationKind.trainUnit => _trainAction(l10n),
      MilitaryCounselRecommendationKind.invade => _invadeAction(l10n),
    };
  }

  Widget? _trainAction(AppLocalizations l10n) {
    final onAgree = callbacks.onAgreeTrain;
    if (onAgree == null) return null;
    return CtNinePatchButton(
      key: ValueKey<String>(
        'counsel_agree_military_train_${recommendation.unitType}',
      ),
      onPressed: () => onAgree(recommendation),
      child: Text(l10n.militaryCounsel_action_agree),
    );
  }

  Widget? _invadeAction(AppLocalizations l10n) {
    final onAgree = callbacks.onAgreeInvade;
    if (onAgree == null) return null;
    return CtNinePatchButton(
      key: ValueKey<String>(
        'counsel_agree_military_invade_${recommendation.recommendationId}',
      ),
      onPressed: () => onAgree(recommendation),
      child: Text(l10n.militaryCounsel_action_agree),
    );
  }
}
