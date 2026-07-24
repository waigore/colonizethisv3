import 'package:colonizethis_app/widgets/ct_gap.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'load_game_list_dialog.dart';
import 'load_game_list_dialog_state_base.dart';

/// Delete/discard confirm body for [LoadGameListDialog] (Refs #4117 de-part).
mixin LoadGameListDialogConfirm on ConsumerState<LoadGameListDialog>, LoadGameListDialogStateBase {
  List<Widget> confirmBodyChildren({
    required AppLocalizations l10n,
    required TextStyle bodyStyle,
    required LoadableSaveEntry? pendingDeleteEntry,
    required LoadableSaveEntry? pendingLoadEntry,
  }) {
    if (pendingDeleteEntry != null) {
      return [
        Text(
          l10n.loadGameList_deleteConfirm,
          key: LoadGameListDialog.deleteConfirmKey,
          style: bodyStyle,
        ),
        CtGap.l,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CtNinePatchButton(
              key: LoadGameListDialog.deleteCancelButtonKey,
              onPressed: onDeleteCancel,
              child: Text(l10n.common_cancel),
            ),
            const SizedBox(width: CtSpacing.m),
            CtNinePatchButton(
              key: LoadGameListDialog.deleteConfirmButtonKey,
              onPressed: onDeleteConfirm,
              child: Text(l10n.loadGameList_delete),
            ),
          ],
        ),
      ];
    }
    if (pendingLoadEntry != null) {
      return [
        Text(
          l10n.loadGameList_discardConfirm,
          key: LoadGameListDialog.discardConfirmKey,
          style: bodyStyle,
        ),
        CtGap.l,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CtNinePatchButton(
              key: LoadGameListDialog.discardCancelButtonKey,
              onPressed: onDiscardCancel,
              child: Text(l10n.common_cancel),
            ),
            const SizedBox(width: CtSpacing.m),
            CtNinePatchButton(
              key: LoadGameListDialog.discardConfirmButtonKey,
              onPressed: onDiscardConfirm,
              child: Text(l10n.loadGameList_load),
            ),
          ],
        ),
      ];
    }
    return const <Widget>[];
  }
}
