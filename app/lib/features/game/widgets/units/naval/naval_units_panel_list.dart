/// Naval panel tree list projection. SPEC/ui/naval-units-panel.md.

part of 'naval_units_panel.dart';

extension _NavalUnitsPanelList on _NavalUnitsPanelState {
  List<Widget> _navalListChildren({
    required List<
      ({
        String regionId,
        FleetRow? homeFleet,
        List<NavalTreeLocationNode> locations,
      })
    >
    tree,
    required AppLocalizations l10n,
    required bool readOnly,
  }) {
    return [
      for (final group in tree) ...[
        RegionSectionHeader(
          label: regionDisplayLabel(group.regionId),
          variant: RegionHeaderVariant.leftBar,
        ),
        if (group.homeFleet != null)
          FleetExpansionTile(
            row: group.homeFleet!,
            l10n: l10n,
            onTap: group.homeFleet!.tileKey != null
                ? () => widget.bus.emit(
                    LocateMapTileEvent(
                      tileKey: group.homeFleet!.tileKey!,
                      regionId: group.homeFleet!.regionId,
                    ),
                  )
                : null,
            isSelectedForCombine: isSelected(
              _selectionFleetId(group.homeFleet!),
            ),
            combineSelectionEnabled: !readOnly,
            onCombineSelectionToggle: () =>
                _toggleFleetSelection(group.homeFleet!),
            onSplitFleet: readOnly
                ? null
                : () => _openSplitDialog(group.homeFleet!),
            onMoveFleet: null,
            isSplitAllowed: !readOnly,
          ),
        for (final loc in group.locations) ...[
          LocationSectionHeader(
            label: loc.displayLabel,
            regionLabel: regionDisplayLabel(loc.regionId),
          ),
          for (final row in loc.fleets)
            FleetExpansionTile(
              row: row,
              l10n: l10n,
              onTap: row.tileKey != null
                  ? () => widget.bus.emit(
                      LocateMapTileEvent(
                        tileKey: row.tileKey!,
                        regionId: row.regionId,
                      ),
                    )
                  : null,
              isSelectedForCombine: isSelected(_selectionFleetId(row)),
              combineSelectionEnabled: !readOnly,
              onCombineSelectionToggle: () => _toggleFleetSelection(row),
              onSplitFleet: readOnly ? null : () => _openSplitDialog(row),
              onMoveFleet: readOnly ? null : () => _openMoveFleetDialog(row),
              isSplitAllowed: true,
            ),
        ],
      ],
    ];
  }
}
