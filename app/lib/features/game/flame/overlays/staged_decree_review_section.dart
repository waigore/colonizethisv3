/// Compact + expandable staged-decree section for `DLG60001`.
/// SPEC: SPEC/ui/components/staged-decree-review.md
library;

import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Hosts the staged-decree summary. Returns [SizedBox.shrink] when [review]
/// is empty so the empty-draft confirm stays simple.
class StagedDecreeReviewSection extends StatefulWidget {
  const StagedDecreeReviewSection({
    super.key,
    required this.review,
    required this.bodyStyle,
    required this.mutedStyle,
    this.onGoToFamily,
  });

  final StagedDecreeReview review;
  final TextStyle bodyStyle;
  final TextStyle mutedStyle;
  final void Function(StagedDecreeFamily family)? onGoToFamily;

  @override
  State<StagedDecreeReviewSection> createState() =>
      _StagedDecreeReviewSectionState();
}

class _StagedDecreeReviewSectionState extends State<StagedDecreeReviewSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.review.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = appL10n(context);
    final summary = widget.review.families
        .map(
          (g) => l10n.game_nextTurnConfirm_familyCount(g.familyLabel, g.count),
        )
        .join(l10n.game_nextTurnConfirm_familySeparator);
    return Column(
      key: const ValueKey('nextTurnConfirm.stagedSection'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: CtSpacing.l),
        CtSectionLabel(l10n.game_nextTurnConfirm_stagedSection),
        const SizedBox(height: CtSpacing.m),
        Text(summary, style: widget.bodyStyle),
        const SizedBox(height: CtSpacing.m),
        CtActionTextButton(
          key: const ValueKey('nextTurnConfirm.reviewDecrees'),
          label: _expanded
              ? l10n.game_nextTurnConfirm_hideDecrees
              : l10n.game_nextTurnConfirm_reviewDecrees,
          onPressed: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded) ...[
          const SizedBox(height: CtSpacing.m),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final group in widget.review.families)
                    _StagedFamilyBlock(
                      group: group,
                      bodyStyle: widget.bodyStyle,
                      mutedStyle: widget.mutedStyle,
                      locateTooltip: l10n.common_locate,
                      onGoTo: widget.onGoToFamily == null
                          ? null
                          : () => widget.onGoToFamily!(group.family),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StagedFamilyBlock extends StatelessWidget {
  const _StagedFamilyBlock({
    required this.group,
    required this.bodyStyle,
    required this.mutedStyle,
    required this.locateTooltip,
    required this.onGoTo,
  });

  final StagedDecreeFamilyGroup group;
  final TextStyle bodyStyle;
  final TextStyle mutedStyle;
  final String locateTooltip;
  final VoidCallback? onGoTo;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: CtSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.game_nextTurnConfirm_familyCount(
                    group.familyLabel,
                    group.count,
                  ),
                  style: bodyStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CtIconAction(
                key: ValueKey('staged-decree-locate-${group.family.name}'),
                icon: Icons.my_location,
                tooltip: locateTooltip,
                onPressed: onGoTo,
              ),
            ],
          ),
          for (final row in group.rows)
            Padding(
              padding: const EdgeInsets.only(
                left: CtSpacing.m,
                top: CtSpacing.s,
              ),
              child: Text(
                row.label,
                style: mutedStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
