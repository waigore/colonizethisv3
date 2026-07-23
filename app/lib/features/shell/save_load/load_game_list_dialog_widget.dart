// Load-game list dialog. OpenDialogEvent id `load_game_list`.
// SPEC/ui/load-game-list-dialog.md.
//
// De-parted wave-9 cluster (Refs #4117): explicit-import libraries replace the
// former 4-part library. Public surface: [LoadGameListDialog].

import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'load_game_list_dialog_state.dart';

/// Manual saves shown per page in [LoadGameListDialog] (auto-save excluded).
const int kLoadGameManualPageSize = 10;

/// Lists loadable saves (manual + auto-save). Optional discard confirm from pause.
class LoadGameListDialog extends ConsumerStatefulWidget {
  const LoadGameListDialog({
    super.key,
    this.fromPause = false,
    this.previewEntries,
    this.previewPendingDeleteId,
  });

  /// SPEC/ui/load-game-list-dialog.md — [UiScreenIds.loadGameListDialog].
  static const screenId = UiScreenIds.loadGameListDialog;

  /// When true, confirm discard of the active session before loading.
  final bool fromPause;

  /// Optional fixed list for Widgetbook / tests (skips [GameService] listing).
  final List<LoadableSaveEntry>? previewEntries;

  /// Widgetbook: open already on delete-confirm for this [storageId].
  final String? previewPendingDeleteId;

  static const Key emptyStateKey = ValueKey<String>(
    'loadGameListDialog.emptyState',
  );
  static const Key listKey = ValueKey<String>('loadGameListDialog.list');
  static const Key autoSaveSectionKey = ValueKey<String>(
    'loadGameListDialog.autoSaveSection',
  );
  static const Key pagerKey = ValueKey<String>('loadGameListDialog.pager');
  static const Key previousButtonKey = ValueKey<String>(
    'loadGameListDialog.previous',
  );
  static const Key nextButtonKey = ValueKey<String>('loadGameListDialog.next');
  static const Key pageLabelKey = ValueKey<String>(
    'loadGameListDialog.pageLabel',
  );
  static const Key discardConfirmKey = ValueKey<String>(
    'loadGameListDialog.discardConfirm',
  );
  static const Key discardCancelButtonKey = ValueKey<String>(
    'loadGameListDialog.discardCancel',
  );
  static const Key discardConfirmButtonKey = ValueKey<String>(
    'loadGameListDialog.discardConfirmButton',
  );
  static const Key deleteConfirmKey = ValueKey<String>(
    'loadGameListDialog.deleteConfirm',
  );
  static const Key deleteCancelButtonKey = ValueKey<String>(
    'loadGameListDialog.deleteCancel',
  );
  static const Key deleteConfirmButtonKey = ValueKey<String>(
    'loadGameListDialog.deleteConfirmButton',
  );
  static const Key closeButtonKey = ValueKey<String>(
    'loadGameListDialog.closeButton',
  );

  static Key rowKey(String storageId) =>
      ValueKey<String>('loadGameListDialog.row_$storageId');

  static Key rowMetaKey(String storageId) =>
      ValueKey<String>('loadGameListDialog.rowMeta_$storageId');

  static Key rowSavedAtKey(String storageId) =>
      ValueKey<String>('loadGameListDialog.rowSavedAt_$storageId');

  static Key deleteButtonKey(String storageId) =>
      ValueKey<String>('loadGameListDialog.delete_$storageId');

  @override
  ConsumerState<LoadGameListDialog> createState() => LoadGameListDialogState();
}
