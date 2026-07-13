part of 'ct_resource_cell.dart';

extension _CtResourceCellTrailing on CtResourceCell {
  /// One-line monospace [Text] for quantity/delta (non-ellipsizing).
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

  /// Quantity + reserved delta slot inside [FittedBox] scale-down (Refs #3999).
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
