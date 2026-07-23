part of 'new_game_leader_selection_dialog.dart';

/// Per-slot nation/leader/profile picker row and responsive layout chrome for
/// [NewGameLeaderSelectionDialog] (Refs #3878 shell modularization).
mixin _NewGameLeaderSelectionDialogSlotRow
    on
        State<NewGameLeaderSelectionDialog>,
        _NewGameLeaderSelectionDialogStateBase,
        _NewGameLeaderSelectionDialogSlots {
  Widget _buildSlotRow(
    BuildContext context,
    int slotIndex,
    AppLocalizations l10n,
    _LeaderDialogTextStyles styles, {
    bool isDuplicate = false,
  }) {
    final gpId = _orderedGpIdsBySlot[slotIndex];
    final available = _availableGpIdsForSlot(slotIndex);
    final effectiveGpId = available.contains(gpId) ? gpId : available.first;
    final gp = widget.naming.gpById(effectiveGpId);
    if (gp == null || gp.leaderVariants.isEmpty) {
      return const SizedBox.shrink();
    }
    final variants = gp.leaderVariants;
    final currentVariantId =
        _leaderByGpId[effectiveGpId] ?? gp.defaultLeaderVariantId;

    final Widget nationDropdownCore = CtDropdown<String>(
      value: effectiveGpId,
      items: available,
      hint: l10n.shell_newGame_selectNation,
      itemLabel: (id) => widget.naming.gpById(id)?.countryName ?? id,
      itemLeading: (ctx, id) => GpDefaultMapColorSwatch(greatPowerId: id),
      onChanged: (value) {
        if (value == null) {
          return;
        }
        final newGp = widget.naming.gpById(value);
        if (newGp == null) {
          return;
        }
        setState(() {
          _orderedGpIdsBySlot[slotIndex] = value;
          _leaderByGpId[value] = newGp.defaultLeaderVariantId;
        });
      },
    );

    // Duplicate slot validation feedback (Refs #2867 R19): wrap the nation
    // dropdown in a 1 dp `--danger` border when this slot's GP id also
    // appears in another slot. The wrapper is keyed by slot index so widget
    // tests can assert that exactly the duplicate slots carry the border.
    // Non-duplicate slots render the dropdown directly (no key) so the
    // negative AC has a definite absence to assert.
    final Widget nationDropdown = isDuplicate
        ? DecoratedBox(
            key: ValueKey<String>(
              NewGameLeaderSelectionDialog.duplicateSlotBorderKey(slotIndex),
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: EditorialMonoclePalette.danger,
                width: NewGameLeaderSelectionDialog.duplicateSlotBorderWidth,
              ),
            ),
            child: nationDropdownCore,
          )
        : nationDropdownCore;

    final leaderDropdown = CtDropdown<String>(
      value: variants.any((v) => v.id == currentVariantId)
          ? currentVariantId
          : variants.first.id,
      items: variants.map((v) => v.id).toList(),
      hint: l10n.shell_leaderDialog_selectLeaderHint,
      itemLabel: (id) => variants.firstWhere((v) => v.id == id).name,
      onChanged: (value) {
        if (value != null) {
          setState(() => _leaderByGpId[effectiveGpId] = value);
        }
      },
    );

    final Widget? profileDropdown = slotIndex == 0
        ? null
        : CtDropdown<String>(
            value: _profileBySlot[slotIndex] ?? _kNormalProfileChoiceId,
            items: <String>[
              _kNormalProfileChoiceId,
              ...widget.blessedProfileNames,
            ],
            hint: l10n.shell_leaderDialog_aiProfileLabel,
            itemLabel: (id) =>
                id.isEmpty ? l10n.shell_leaderDialog_aiProfileNormal : id,
            onChanged: (value) {
              setState(() {
                if (value == null || value.isEmpty) {
                  _profileBySlot.remove(slotIndex);
                } else {
                  _profileBySlot[slotIndex] = value;
                }
              });
            },
          );

    // Mockup `.profile-line`: inline "AI Profile:" label beside the dropdown
    // (AI slots only). The dropdown takes the remaining width.
    final Widget? profileLine = profileDropdown == null
        ? null
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.shell_leaderDialog_aiProfileInlineLabel,
                style: styles.profileInlineLabel,
              ),
              const SizedBox(width: CtSpacing.s),
              Expanded(child: profileDropdown),
            ],
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            EditorialMonoclePalette.surface,
            EditorialMonoclePalette.bgDeep,
          ],
        ),
        border: Border(
          top: BorderSide(color: EditorialMonoclePalette.accentDim),
          bottom: BorderSide(color: EditorialMonoclePalette.accentDim),
        ),
      ),
      child: Padding(
        padding: _kSlotRowPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSlotLabel(l10n, slotIndex, styles),
            const SizedBox(height: CtSpacing.s),
            _SlotPickersBody(
              nationDropdown: nationDropdown,
              leaderDropdown: leaderDropdown,
              profileLine: profileLine,
            ),
          ],
        ),
      ),
    );
  }
}
