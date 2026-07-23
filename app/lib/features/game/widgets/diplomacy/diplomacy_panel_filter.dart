// Diplomacy panel row filter assembly. SPEC/ui/diplomacy-panel.md.

part of 'diplomacy_panel.dart';

class _DiplomacyPanelFilteredRows {
  const _DiplomacyPanelFilteredRows({
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

_DiplomacyPanelFilteredRows _filterDiplomacyPanelRows({
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

  return _DiplomacyPanelFilteredRows(
    gps: gps,
    minors: minors,
    tribes: tribes,
    showGps: showGps,
    showMinors: showMinors,
    showTribes: showTribes,
    firstShownKind: firstShownKind,
  );
}
