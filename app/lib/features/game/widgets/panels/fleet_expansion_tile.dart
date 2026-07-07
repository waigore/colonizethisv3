import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../config/ct_e2e.dart';
import '../../../../config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_spacing.dart';
import 'tree_builders/naval_tree_builder.dart';
import '../units/shared/units_entity_action_row.dart';
import '../units/shared/units_entity_card.dart';

part 'fleet_expansion_tile_expanded.dart';
part 'fleet_expansion_tile_title.dart';

/// Naval-units fleet row.
///
/// Implements `Refs #2866` S8 mockup-fidelity gaps R25–R29 (see
/// `SPEC/ui/naval-units-panel.md` § *Naval mockup fidelity (R25–R29)* and
/// `SPEC/ui/mockups/UNIT30001-naval-units-panel.html`):
/// - R25 — actions render through [UnitsEntityActionRow] with
///   `dense: true`, so Move / Split / Locate stay on a single inline row
///   at the default panel width.
/// - R26 — when [FleetRow.isHomeFleet] is `true`, the title appends a
///   compact uppercase `HOME` chip styled with `--accent-dim` / `--bg-deep`
///   tokens.
/// - R27 — the locate control lives at the **right end** of the actions
///   cluster (icon-only `CtNinePatchButton` via
///   [UnitsEntityAction.iconOnly]); regular fleets get Move + Split + Locate,
///   Home Fleets get Split + Locate (Move stays hidden per R19).
/// - R28 — the localised `(in port)` / `(at sea)` qualifier is built into
///   [FleetRow.locationLabel] by `naval_tree_builder.dart`; this widget just
///   renders that subtitle.
/// - R29 — the expanded children render a single composition `Table` with
///   columns `Type | ×Count | Role`, an optional Home-Fleet
///   `Cargo capacity: X holds` line, and a single-line
///   `Total ships: X · Warships: Y · Merchants: Z` summary plus the
///   retained `Strength: V` line, replacing the previous per-stat
///   `ListTile` stack.
///
/// The collapsed/expanded chrome is the shared [UnitsEntityCard] mockup
/// `.fleet-row` bordered gradient card (`bg-deep → surface` gradient + 1 px
/// `--border` collapsed; flat `--surface` + 1 px `--accent-dim` expanded with
/// a child top divider) rather than the bare Material `ExpansionTile`,
/// matching the military army-row migration (issue #3514 owner decision #6 /
/// AC-6; `SPEC/ui/mockups/UNIT30001-naval-units-panel.html` `.fleet-row`).
/// The dense [UnitsEntityActionRow] is hosted with `chrome: false` so the
/// card border is not double-painted; the title row stays on a single inline
/// row (collapsing to icon-only at narrow widths) so Move / Split / Locate
/// remain overflow-free under the card chrome.
class FleetExpansionTile extends StatelessWidget {
  const FleetExpansionTile({
    super.key,
    required this.row,
    required this.l10n,
    this.onTap,
    required this.isSelectedForCombine,
    this.combineSelectionEnabled = true,
    required this.onCombineSelectionToggle,
    this.onSplitFleet,
    this.onMoveFleet,
    this.isSplitAllowed = false,
  });

  final FleetRow row;
  final AppLocalizations l10n;
  final VoidCallback? onTap;
  final bool isSelectedForCombine;
  final bool combineSelectionEnabled;
  final VoidCallback onCombineSelectionToggle;
  final VoidCallback? onSplitFleet;
  final VoidCallback? onMoveFleet;
  final bool isSplitAllowed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: CtSpacing.m),
      child: UnitsEntityCard(
        title: buildFleetTitleRow(),
        subtitle: buildFleetSubtitle(),
        children: _buildChildren(),
      ),
    );
  }

  List<Widget> _buildChildren() {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          CtSpacing.l,
          4,
          CtSpacing.l,
          CtSpacing.m,
        ),
        child: _FleetExpandedContent(row: row, l10n: l10n),
      ),
    ];
  }
}
