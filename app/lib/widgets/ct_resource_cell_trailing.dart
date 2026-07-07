part of 'ct_resource_cell.dart';

extension _CtResourceCellTrailing on CtResourceCell {
  /// A single trailing monospace [Text] (ellipsizing, one line). Kept as a
  /// distinct widget per value so the quantity and delta remain individually
  /// findable / colour-assertable, while [trailingCluster] composes them.
  Widget monoText(
    BuildContext context, {
    required String text,
    required Color color,
    required double fontSize,
  }) {
    return Text(
      text,
      style: monoStyle(context, color: color, fontSize: fontSize),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Builds the trailing quantity + optional delta as the **last** flex child
  /// of the outer [Row] (see [CtResourceCell.build]). The cluster slot's
  /// right edge coincides with the card's inner-right edge, and the cluster's
  /// content is right-aligned within the slot via [Alignment.centerRight], so
  /// the quantity (and, when present, the trailing `+N` / `-N` delta) is pinned
  /// hard against the card's right edge whether or not a delta is shown (issue
  /// #3485). The optional delta sits immediately to the right of the quantity
  /// per the mockup `.resource-cell` order. Inside the cluster each value is a
  /// loose [Flexible] with `maxLines: 1` + ellipsis so it shrinks as a
  /// defensive last-resort fallback at pathologically narrow widths instead of
  /// overflowing; in normal usage neither value ellipsizes (Refs #2862 S9 / C10,
  /// #3485).
  Widget trailingCluster(
    BuildContext context, {
    required String quantityText,
    required String? deltaText,
    required Color? deltaTextColor,
  }) {
    return Flexible(
      fit: FlexFit.loose,
      flex: CtResourceCell.trailingFlex,
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              fit: FlexFit.loose,
              child: monoText(
                context,
                text: quantityText,
                color: EditorialMonoclePalette.accentDim,
                fontSize: CtResourceCell.quantityFontSize,
              ),
            ),
            if (deltaText != null) ...<Widget>[
              const SizedBox(width: CtResourceCell.quantityToDeltaGap),
              Flexible(
                fit: FlexFit.loose,
                child: monoText(
                  context,
                  text: deltaText,
                  color: deltaTextColor!,
                  fontSize: CtResourceCell.deltaFontSize,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
