/// Number / currency formatting helpers shared by app UI.
///
/// SPEC: `SPEC/ui/train-civilians-dialog.md`,
/// `SPEC/ui/train-military-dialog.md`, `SPEC/ui/components/train-dialog-chrome.md`.
library;

/// Formats [value] with comma thousands separators (e.g. `5000` -> `5,000`,
/// `-1240` -> `-1,240`). Grouping is applied to the absolute value and the
/// minus sign is preserved for negative inputs.
String formatThousands(int value) {
  final String digits = value.abs().toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      out.write(',');
    }
    out.write(digits[i]);
  }
  final String grouped = out.toString();
  return value < 0 ? '-$grouped' : grouped;
}

/// Formats [value] as a treasury amount with the `£` symbol and comma
/// thousands grouping (e.g. `5000` -> `£5,000`).
String formatTreasuryCurrency(int value) => '£${formatThousands(value)}';
