import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/commodity_display_name.dart';

/// Resolved per-panel text styles, isolated as a value object so the
/// [DealBookPanel] build path stays under the 60-line cap.
class DealBookPanelStyles {
  const DealBookPanelStyles({
    required this.title,
    required this.sectionHeading,
    required this.body,
    required this.muted,
    required this.totals,
  });

  factory DealBookPanelStyles.of(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DealBookPanelStyles(
      title: (theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16))
          .copyWith(color: EditorialMonoclePalette.accent),
      sectionHeading:
          (theme.textTheme.labelMedium ?? const TextStyle(fontSize: 12))
              .copyWith(color: EditorialMonoclePalette.accentDim),
      body: (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14))
          .copyWith(color: EditorialMonoclePalette.fg),
      muted: (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12))
          .copyWith(color: EditorialMonoclePalette.muted),
      totals: (theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14))
          .copyWith(color: EditorialMonoclePalette.accentBright),
    );
  }

  final TextStyle title;
  final TextStyle sectionHeading;
  final TextStyle body;
  final TextStyle muted;
  final TextStyle totals;
}

/// Single filled-deal row inside a Deal Book panel. Lays out
/// `{displayName} — qty at £price = £notional` with optional FRR / FTP
/// tags so the player can audit how the deal cleared per
/// `SPEC/game/world-market.md` § Matching + § First Right of Refusal.
class DealBookFilledRow extends StatelessWidget {
  const DealBookFilledRow({
    super.key,
    required this.rowKey,
    required this.deal,
    required this.rowStyle,
    required this.tagStyle,
    required this.matchTagFirstRight,
    required this.matchTagFavoredPartner,
  });

  final Key rowKey;
  final FilledDeal deal;
  final TextStyle rowStyle;
  final TextStyle tagStyle;
  final String matchTagFirstRight;
  final String matchTagFavoredPartner;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = appL10n(context);
    final int unitPrice = deal.pricePerUnit.floor();
    final int notional = deal.quantity * unitPrice;
    final String name = commodityDisplayName(l10n, deal.commodityId);
    final List<String> tags = <String>[
      if (deal.isFirstRightOfRefusalMatch) matchTagFirstRight,
      if (deal.isFtpMatch) matchTagFavoredPartner,
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      key: rowKey,
      children: <Widget>[
        Expanded(
          child: Text(
            l10n.tradeDealBook_filledRow(
              name,
              deal.quantity,
              unitPrice,
              notional,
            ),
            style: rowStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (tags.isNotEmpty) ...<Widget>[
          const SizedBox(width: 6),
          Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            tags.join(' '),
            style: tagStyle,
          ),
        ],
      ],
    );
  }
}
