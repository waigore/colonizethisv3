part of 'ct_resource_cell.dart';

extension _CtResourceCellTrailing on CtResourceCell {
  /// A single trailing monospace [Text] (one line, non-ellipsizing). Kept as a
  /// distinct widget per value so the quantity and delta remain individually
  /// findable / colour-assertable, while [trailingCluster] composes them.
  Widget monoText(
    BuildContext context, {
    required String text,
    required Color color,
    required double fontSize,
    Key? key,
  }) {
    return Text(
      text,
      key: key,
      style: monoStyle(context, color: color, fontSize: fontSize),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
    );
  }

  /// Builds the trailing quantity + reserved delta slot as the sole non-flex
  /// sibling of the name [Flexible] inside the inner [Row].
  ///
  /// The leading [CtResourceCell.itemGap] is included inside the [FittedBox]
  /// so the outer row has only one non-flex child and cannot overflow when the
  /// Available grid slot is tighter than gap + trailing intrinsic width
  /// (Refs #3999). [FittedBox] `scaleDown` keeps amounts visible (scaled) when
  /// space is scarce instead of ellipsizing them to a blank region. A fixed
  /// delta slot is always reserved so quantity right edges share a panel-wide
  /// column whether or not a signed delta is painted.
  Widget trailingCluster(
    BuildContext context, {
    required String quantityText,
    required String? deltaText,
    required Color? deltaTextColor,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(width: CtResourceCell.itemGap),
          monoText(
            context,
            key: CtResourceCell.quantityTextKey,
            text: quantityText,
            color: EditorialMonoclePalette.accentDim,
            fontSize: CtResourceCell.quantityFontSize,
          ),
          SizedBox(
            width:
                CtResourceCell.quantityToDeltaGap +
                CtResourceCell.reservedDeltaSlotWidth,
            child: deltaText == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(
                      left: CtResourceCell.quantityToDeltaGap,
                    ),
                    child: monoText(
                      context,
                      key: CtResourceCell.deltaTextKey,
                      text: deltaText,
                      color: deltaTextColor!,
                      fontSize: CtResourceCell.deltaFontSize,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
