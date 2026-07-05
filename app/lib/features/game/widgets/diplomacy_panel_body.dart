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
        if (showGps) ...[
          _DiplomacySectionHeader(
            title: l10n.diplomacy_section_greatPowers,
            isFirst: firstShownKind == FactionKind.greatPower,
          ),
          if (gps.isEmpty)
            _DiplomacyEmptySectionPlaceholder(
              text: l10n.diplomacy_panel_noGreatPowers,
            )
          else
            ...gps.map(
              (r) => _DiplomacyRow(
                data: r,
                onAction: onAction,
                onTap: () => onTap(r),
                readOnly: readOnly,
              ),
            ),
        ],
        if (showMinors) ...[
          _DiplomacySectionHeader(
            title: l10n.diplomacy_section_minorNations,
            isFirst: firstShownKind == FactionKind.minor,
          ),
          if (minors.isEmpty)
            _DiplomacyEmptySectionPlaceholder(
              text: l10n.diplomacy_panel_noMinorNations,
            )
          else
            ...minors.map(
              (r) => _DiplomacyRow(
                data: r,
                onAction: onAction,
                onTap: () => onTap(r),
                readOnly: readOnly,
              ),
            ),
        ],
        if (showTribes) ...[
          _DiplomacySectionHeader(
            title: l10n.diplomacy_section_tribes,
            isFirst: firstShownKind == FactionKind.tribe,
          ),
          if (tribes.isEmpty)
            _DiplomacyEmptySectionPlaceholder(text: l10n.diplomacy_panel_noTribes)
          else
            ...tribes.map(
              (r) => _DiplomacyRow(
                data: r,
                onAction: onAction,
                onTap: () => onTap(r),
                readOnly: readOnly,
              ),
            ),
        ],
      ],
    );
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
