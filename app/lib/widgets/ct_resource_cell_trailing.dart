import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

import 'ct_resource_cell.dart';
import 'ct_resource_cell_format.dart';

/// One-line monospace [Text] for quantity/delta (non-ellipsizing).
Widget ctResourceCellMonoText(
  BuildContext context, {
  required String text,
  required Color color,
  required double fontSize,
  Key? key,
}) {
  return Text(
    text,
    key: key,
    style: ctResourceCellMonoStyle(
      context,
      color: color,
      fontSize: fontSize,
    ),
    maxLines: 1,
    softWrap: false,
    overflow: TextOverflow.visible,
  );
}

/// Quantity + optional delta inside [FittedBox] scale-down (Refs #3999).
///
/// When [deltaText] is null the trailing cluster is quantity-only so the
/// painted amount's right inset matches the leading icon inset
/// ([CtSpacing.s]); a non-null delta sits immediately to the right of the
/// quantity (owner wide-layout inset parity follow-up on #3999).
Widget ctResourceCellTrailingCluster(
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
        ctResourceCellMonoText(
          context,
          key: CtResourceCell.quantityTextKey,
          text: quantityText,
          color: EditorialMonoclePalette.accentDim,
          fontSize: CtResourceCell.quantityFontSize,
        ),
        if (deltaText != null) ...<Widget>[
          const SizedBox(width: CtResourceCell.quantityToDeltaGap),
          ctResourceCellMonoText(
            context,
            key: CtResourceCell.deltaTextKey,
            text: deltaText,
            color: deltaTextColor!,
            fontSize: CtResourceCell.deltaFontSize,
          ),
        ],
      ],
    ),
  );
}
