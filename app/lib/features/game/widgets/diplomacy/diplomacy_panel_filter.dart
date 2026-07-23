// Diplomacy panel row filter assembly. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../config/routes.dart';
import '../../../../config/themes.dart' show editorialMonocleDisplayFontFamily;
import '../../../../core/services/app_event_handler/app_event_handler_scope.dart';
import '../../../../widgets/ct_gradients.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_radius.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/relation_meter.dart';
import 'diplomacy_order_helpers.dart';
import 'diplomacy_panel_rows_models.dart';
import 'fnv1a_hash_constants.dart';
import 'relative_power_line.dart';
// Diplomacy panel row filter assembly. SPEC/ui/diplomacy-panel.md.


class DiplomacyPanelFilteredRows {
  const DiplomacyPanelFilteredRows({
    required this.gps,
    required this.minors,
    required this.tribes,
    required this.showGps,
    required this.showMinors,
    required this.showTribes,
    required this.firstShownKind,
  });

  final List<DiplomacyRowData> gps;
  final List<DiplomacyRowData> minors;
  final List<DiplomacyRowData> tribes;
  final bool showGps;
  final bool showMinors;
  final bool showTribes;
  final FactionKind? firstShownKind;
}

DiplomacyPanelFilteredRows filterDiplomacyPanelRows({
  required List<DiplomacyRowData> rows,
  required DiplomacyFilterMode filterMode,
}) {
  final gps = <DiplomacyRowData>[];
  final minors = <DiplomacyRowData>[];
  final tribes = <DiplomacyRowData>[];
  for (final r in rows) {
    switch (r.kind) {
      case FactionKind.greatPower:
        gps.add(r);
      case FactionKind.minor:
        minors.add(r);
      case FactionKind.tribe:
        tribes.add(r);
    }
  }
  final showGps = diplomacyFilterShowsKind(filterMode, FactionKind.greatPower);
  final showMinors = diplomacyFilterShowsKind(filterMode, FactionKind.minor);
  final showTribes = diplomacyFilterShowsKind(filterMode, FactionKind.tribe);

  // SPEC/ui/diplomacy-panel.md § Section headings (first-heading top rhythm,
  // Refs #3621): the first heading rendered under the active filter drops
  // its top gap to 0 (mockup `.section-head:first-child`).
  final FactionKind? firstShownKind = showGps
      ? FactionKind.greatPower
      : showMinors
      ? FactionKind.minor
      : showTribes
      ? FactionKind.tribe
      : null;

  return DiplomacyPanelFilteredRows(
    gps: gps,
    minors: minors,
    tribes: tribes,
    showGps: showGps,
    showMinors: showMinors,
    showTribes: showTribes,
    firstShownKind: firstShownKind,
  );
}
