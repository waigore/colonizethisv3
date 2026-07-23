// Load-game list dialog row rendering (Refs #4117).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';

import 'load_game_list_dialog_state_base.dart';
import 'load_game_list_dialog_widget.dart';

mixin LoadGameListDialogRow
    on ConsumerState<LoadGameListDialog>, LoadGameListDialogStateBase {
  String? secondaryMetaLine(AppLocalizations l10n, LoadableSaveEntry entry) {
    final turn = entry.turnNumber;
    final year = entry.calendarYear;
    final nation = entry.humanNation;
    if (turn != null && year != null && nation != null && nation.isNotEmpty) {
      return l10n.loadGameList_metaLine(turn, year, nation);
    }
    return turn == null ? null : l10n.loadGameList_turnSubtitle(turn);
  }

  String? lastSavedLine(LoadableSaveEntry entry) {
    final at = entry.lastSavedAt;
    return at == null ? null : DateFormat.yMd().add_jm().format(at.toLocal());
  }

  Widget rowContent({
    required AppLocalizations l10n,
    required TextStyle bodyStyle,
    required TextStyle mutedStyle,
    required LoadableSaveEntry entry,
  }) {
    final meta = secondaryMetaLine(l10n, entry);
    final savedAt = lastSavedLine(entry);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CtNinePatchButton(
            key: LoadGameListDialog.rowKey(entry.storageId),
            onPressed: () => onSelect(entry),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.label, style: bodyStyle),
                if (meta != null)
                  Text(
                    meta,
                    key: LoadGameListDialog.rowMetaKey(entry.storageId),
                    style: mutedStyle,
                  ),
                if (savedAt != null)
                  Text(
                    savedAt,
                    key: LoadGameListDialog.rowSavedAtKey(entry.storageId),
                    style: mutedStyle,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: CtSpacing.s),
        CtNinePatchButton(
          key: LoadGameListDialog.deleteButtonKey(entry.storageId),
          onPressed: () => onDeleteRequest(entry),
          child: Text(l10n.loadGameList_delete),
        ),
      ],
    );
  }
}
