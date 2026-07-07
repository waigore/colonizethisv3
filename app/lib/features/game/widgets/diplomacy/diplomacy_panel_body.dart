/// Filtered faction-row list body for the diplomacy panel.
/// SPEC/ui/diplomacy-panel.md.

part of 'diplomacy_panel.dart';

class _DiplomacyPanelBody extends StatelessWidget {
  const _DiplomacyPanelBody({
    required this.gps,
    required this.minors,
    required this.tribes,
    required this.showGps,
    required this.showMinors,
    required this.showTribes,
    required this.firstShownKind,
    required this.onAction,
    required this.onTap,
    required this.readOnly,
  });

  final List<DiplomacyRowData> gps;
  final List<DiplomacyRowData> minors;
  final List<DiplomacyRowData> tribes;
  final bool showGps;
  final bool showMinors;
  final bool showTribes;
  final FactionKind? firstShownKind;
  final void Function(DiplomaticOrder order) onAction;
  final void Function(DiplomacyRowData row) onTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: CtSpacing.l,
        vertical: CtSpacing.m,
      ),
      children: [
        // SPEC/ui/diplomacy-panel.md § Section headings: each section
        // heading is always rendered (subject to the mode-bar filter),
        // even when the section has no rows. An empty visible section
        // renders placeholder copy beneath its heading.
        if (showGps)
          ..._diplomacySectionWidgets(
            title: l10n.diplomacy_section_greatPowers,
            rows: gps,
            emptyText: l10n.diplomacy_panel_noGreatPowers,
            kind: FactionKind.greatPower,
          ),
        if (showMinors)
          ..._diplomacySectionWidgets(
            title: l10n.diplomacy_section_minorNations,
            rows: minors,
            emptyText: l10n.diplomacy_panel_noMinorNations,
            kind: FactionKind.minor,
          ),
        if (showTribes)
          ..._diplomacySectionWidgets(
            title: l10n.diplomacy_section_tribes,
            rows: tribes,
            emptyText: l10n.diplomacy_panel_noTribes,
            kind: FactionKind.tribe,
          ),
      ],
    );
  }

  List<Widget> _diplomacySectionWidgets({
    required String title,
    required List<DiplomacyRowData> rows,
    required String emptyText,
    required FactionKind kind,
  }) {
    return [
      _DiplomacySectionHeader(
        title: title,
        isFirst: firstShownKind == kind,
      ),
      if (rows.isEmpty)
        _DiplomacyEmptySectionPlaceholder(text: emptyText)
      else
        ...rows.map(
          (r) => _DiplomacyRow(
            data: r,
            onAction: onAction,
            onTap: () => onTap(r),
            readOnly: readOnly,
          ),
        ),
    ];
  }
}

/// Placeholder copy rendered beneath an empty (but always-visible)
/// section heading. SPEC/ui/diplomacy-panel.md § Section headings —
/// muted italic text using the editorial-monocle `--muted` token
/// (matches the mockup `.empty` style), e.g. the Tribes section before
/// any tribe has been contacted shows "No tribes contacted yet.".
class _DiplomacyEmptySectionPlaceholder extends StatelessWidget {
  const _DiplomacyEmptySectionPlaceholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CtSpacing.s,
        vertical: CtSpacing.m,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: EditorialMonoclePalette.muted,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
