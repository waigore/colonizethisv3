part of 'ct_resource_cell.dart';

String? _ctResourceCellFormattedDeltaText(int? delta) {
  if (delta == null) return null;
  if (delta > 0) return '+$delta';
  return '$delta';
}

Color? _ctResourceCellDeltaColor(int? delta) {
  if (delta == null) return null;
  if (delta > 0) return EditorialMonoclePalette.success;
  if (delta < 0) return EditorialMonoclePalette.danger;
  return EditorialMonoclePalette.muted;
}

String _ctResourceCellFormatQuantity(int value) {
  final String raw = value.abs().toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < raw.length; i++) {
    final int posFromRight = raw.length - i;
    if (i > 0 && posFromRight % 3 == 0) out.write(',');
    out.write(raw[i]);
  }
  if (value < 0) return '-${out.toString()}';
  return out.toString();
}

extension _CtResourceCellFormat on CtResourceCell {
  TextStyle nameStyle(BuildContext context) {
    final TextStyle base =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    return base.copyWith(
      color: EditorialMonoclePalette.fg,
      fontSize: CtResourceCell.nameFontSize,
    );
  }

  TextStyle monoStyle(
    BuildContext context, {
    required Color color,
    required double fontSize,
  }) {
    final TextStyle base =
        Theme.of(context).textTheme.labelMedium ?? const TextStyle(fontSize: 12);
    return base.copyWith(
      color: color,
      fontSize: fontSize,
      fontFamilyFallback: const <String>['SF Mono', 'Menlo', 'monospace'],
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }
}
