/// Operator-facing log line timestamps (session buffer, ctdev file, Sim Log).
///
/// Format: local wall clock as `YYYY-MM-DDTHH:mm:ss.SSS±HH:MM`, or
/// `YYYY-MM-DDTHH:mm:ss.SSSZ` when the host zone offset is UTC.
/// Milliseconds are always three digits (including `.000`).
String formatOperatorLogTimestamp(DateTime instant) {
  final local = instant.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final mo = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final mi = local.minute.toString().padLeft(2, '0');
  final s = local.second.toString().padLeft(2, '0');
  final ms = local.millisecond.toString().padLeft(3, '0');
  final off = local.timeZoneOffset;
  final String tzSuffix;
  if (off.inMinutes == 0) {
    tzSuffix = 'Z';
  } else {
    final sign = off.isNegative ? '-' : '+';
    final absMinutes = off.abs().inMinutes;
    final oh = (absMinutes ~/ 60).toString().padLeft(2, '0');
    final om = (absMinutes % 60).toString().padLeft(2, '0');
    tzSuffix = '$sign$oh:$om';
  }
  return '$y-$mo-${d}T$h:$mi:$s.$ms$tzSuffix';
}
