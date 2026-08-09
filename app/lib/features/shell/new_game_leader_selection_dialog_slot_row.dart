import 'package:flutter/material.dart';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app/widgets/gp_default_map_color_swatch.dart';

import 'new_game_leader_selection_dialog.dart';
import 'new_game_leader_selection_dialog_layout.dart';
import 'new_game_leader_selection_dialog_slot_row_pickers.dart';
import 'new_game_leader_selection_dialog_slots.dart';
import 'new_game_leader_selection_dialog_state_base.dart';

/// Per-slot nation/leader/profile picker row and responsive layout chrome for
/// [NewGameLeaderSelectionDialog] (Refs #4117).
mixin NewGameLeaderSelectionDialogSlotRow
    on
        State<NewGameLeaderSelectionDialog>,
        NewGameLeaderSelectionDialogStateBase,
        NewGameLeaderSelectionDialogSlots {
  Widget buildSlotRow(
    BuildContext context,
    int slotIndex,
    AppLocalizations l10n,
    NewGameLeaderDialogTextStyles styles, {
    bool isDuplicate = false,
  }) {
    final gpId = orderedGpIdsBySlot[slotIndex];
    final available = availableGpIdsForSlot(slotIndex);
    final effectiveGpId = available.contains(gpId) ? gpId : available.first;
    final gp = widget.naming.gpById(effectiveGpId);
    if (gp == null || gp.leaderVariants.isEmpty) {
      return const SizedBox.shrink();
    }
    final variants = gp.leaderVariants;
    final currentVariantId =
        leaderByGpId[effectiveGpId] ?? gp.defaultLeaderVariantId;

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
          orderedGpIdsBySlot[slotIndex] = value;
          leaderByGpId[value] = newGp.defaultLeaderVariantId;
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
          setState(() => leaderByGpId[effectiveGpId] = value);
        }
      },
    );

    final Widget? profileDropdown = slotIndex == 0
        ? null
        : CtDropdown<String>(
            value:
                profileBySlot[slotIndex] ??
                kNewGameLeaderSelectionNormalProfileChoiceId,
            items: <String>[
              kNewGameLeaderSelectionNormalProfileChoiceId,
              ...widget.blessedProfileNames,
            ],
            hint: l10n.shell_leaderDialog_aiProfileLabel,
            itemLabel: (id) =>
                id.isEmpty ? l10n.shell_leaderDialog_aiProfileNormal : id,
            onChanged: (value) {
              setState(() {
                if (value == null || value.isEmpty) {
                  profileBySlot.remove(slotIndex);
                } else {
                  profileBySlot[slotIndex] = value;
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
        padding: kNewGameLeaderSelectionSlotRowPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            buildSlotLabel(l10n, slotIndex, styles),
            const SizedBox(height: CtSpacing.s),
            NewGameLeaderSelectionDialogSlotPickersBody(
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
