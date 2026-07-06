part of 'new_game_leader_selection_dialog.dart';

/// Slot rows, duplicate validation, and responsive picker layout for
/// [NewGameLeaderSelectionDialog] (Refs #3878 shell modularization).
mixin _NewGameLeaderSelectionDialogSlots
    on State<NewGameLeaderSelectionDialog>, _NewGameLeaderSelectionDialogStateBase {
  /// Slot heading row: `Slot N` plus a `YOU` tag for the human slot (0).
  /// Mirrors the mockup `.slot-label` / `.you-tag`: the literal copy stays
  /// `You` ([AppLocalizations.shell_leaderDialog_slotYouTag]) and uppercasing
  /// is applied here as presentation, matching the mockup's CSS
  /// `text-transform:uppercase`.
  Widget _buildSlotLabel(
    AppLocalizations l10n,
    int slotIndex,
    _LeaderDialogTextStyles styles,
  ) {
    final bool isYou = slotIndex == 0;
    final TextStyle labelStyle = styles.slotLabel.copyWith(
      color: isYou
          ? EditorialMonoclePalette.accentDim
          : EditorialMonoclePalette.muted,
      fontWeight: isYou ? FontWeight.w600 : FontWeight.normal,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n.shell_leaderDialog_slotLabel(slotIndex + 1),
          style: labelStyle,
        ),
        if (isYou) ...[
          const SizedBox(width: CtSpacing.s),
          Text(
            l10n.shell_leaderDialog_slotYouTag.toUpperCase(),
            key: const ValueKey<String>('leaderSelectionDialogSlotYouTag'),
            style: styles.slotYouTag,
          ),
        ],
      ],
    );
  }

  _LeaderDialogTextStyles _resolveTextStyles(ThemeData theme) {
    final TextStyle bodySmall =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    return _LeaderDialogTextStyles(
      title: (theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16))
          .copyWith(
            color: EditorialMonoclePalette.accent,
            letterSpacing: (theme.textTheme.titleMedium?.fontSize ?? 16) * 0.05,
            fontWeight: FontWeight.w600,
          ),
      intro: (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14))
          .copyWith(
            color: EditorialMonoclePalette.muted,
            fontStyle: FontStyle.italic,
          ),
      fieldLabel: bodySmall.copyWith(
        color: EditorialMonoclePalette.accentDim,
        fontWeight: FontWeight.w600,
      ),
      helper: bodySmall.copyWith(
        color: EditorialMonoclePalette.muted,
        fontSize: 12,
      ),
      slotLabel: bodySmall.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.48,
      ),
      slotYouTag: bodySmall.copyWith(
        fontSize: 9,
        letterSpacing: 0.54,
        color: EditorialMonoclePalette.accentDim,
        fontWeight: FontWeight.normal,
      ),
      profileInlineLabel: bodySmall.copyWith(
        fontSize: 10,
        letterSpacing: 0.4,
        color: EditorialMonoclePalette.muted,
      ),
    );
  }

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

class _LeaderDialogTextStyles {
  const _LeaderDialogTextStyles({
    required this.title,
    required this.intro,
    required this.fieldLabel,
    required this.helper,
    required this.slotLabel,
    required this.slotYouTag,
    required this.profileInlineLabel,
  });

  final TextStyle title;
  final TextStyle intro;
  final TextStyle fieldLabel;
  final TextStyle helper;
  final TextStyle slotLabel;
  final TextStyle slotYouTag;
  final TextStyle profileInlineLabel;
}

/// Pickers body that switches between a side-by-side `Row` and a vertically
/// stacked `Column` at the [kLeaderSelectionNarrowBreakpoint] (540 dp) viewport
/// width — the DLG10001-dedicated breakpoint matching the mockup
/// `@media (min-width: 540px)` rule.
///
/// SPEC: `SPEC/ui/new-game-leader-selection-dialog.md` § Layout / wireframe
/// + Acceptance Criteria narrow-viewport stacking AC;
/// `SPEC/ui/mobile-adaptation.md` § 4 New game leader selection.
class _SlotPickersBody extends StatelessWidget {
  const _SlotPickersBody({
    required this.nationDropdown,
    required this.leaderDropdown,
    this.profileLine,
  });

  final Widget nationDropdown;
  final Widget leaderDropdown;

  /// Pre-built AI Profile line (inline label + dropdown) for AI slots; `null`
  /// for the human slot (0).
  final Widget? profileLine;

  /// Vertical gap between the nation dropdown and the leader dropdown when
  /// the slot body is stacked (matches the slot label ↔ pickers gap of
  /// `CtSpacing.m / 2` = 4 dp).
  static const double stackedGap = CtSpacing.m / 2;

  /// Key applied to the vertically stacked `Column` body (narrow viewport).
  /// Tests pin the narrow-stacking AC by asserting one such column per slot.
  static const Key stackedColumnKey = ValueKey<String>(
    'newGameLeaderDialogSlotPickersColumn',
  );

  /// Key applied to the side-by-side `Row` body (wide viewport).
  /// Tests pin the wide-row AC by asserting one such row per slot.
  static const Key sideBySideRowKey = ValueKey<String>(
    'newGameLeaderDialogSlotPickersRow',
  );

  @override
  Widget build(BuildContext context) {
    final bool narrow =
        MediaQuery.sizeOf(context).width < kLeaderSelectionNarrowBreakpoint;
    if (narrow) {
      return Column(
        key: stackedColumnKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          nationDropdown,
          const SizedBox(height: stackedGap),
          leaderDropdown,
          if (profileLine != null) ...[
            const SizedBox(height: stackedGap),
            profileLine!,
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          key: sideBySideRowKey,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: nationDropdown),
            const SizedBox(width: CtSpacing.s),
            Expanded(child: leaderDropdown),
          ],
        ),
        if (profileLine != null) ...[
          const SizedBox(height: stackedGap),
          profileLine!,
        ],
      ],
    );
  }
}
