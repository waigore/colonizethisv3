// Treasury amount formatting for the map gold HUD (Refs #4560).
//
// SPEC: SPEC/ui/empire-overview.md § Treasury teaching surface.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Stable key for widget tests that open the treasury details popover.
const Key kTreasuryDetailsPanelKey = Key('treasury_details_panel');

/// Formats treasury amounts for chip and popover Exact / Compact modes.
String formatTreasuryAmount(int value, {required bool showExact}) {
  if (showExact) {
    return NumberFormat.decimalPattern().format(value);
  }
  final compactRaw = NumberFormat.compact(locale: 'en_US').format(value);
  final compact = compactRaw.replaceAll('K', 'k');
  if (compact.contains('.') || !compact.endsWith('k')) {
    return compact;
  }
  return compact.replaceFirst('k', '.0k');
}

String? formatTreasuryDeltaLabel(int? delta) {
  if (delta == null || delta == 0) {
    return null;
  }
  if (delta > 0) {
    return '+$delta';
  }
  return '$delta';
}
