// Load-game list dialog. OpenDialogEvent id `load_game_list`.
// SPEC/ui/load-game-list-dialog.md.

import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/core/services/game_session_clear.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_gap.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

part 'load_game_list_dialog_row.dart';
part 'load_game_list_dialog_confirm.dart';
part 'load_game_list_dialog_body.dart';

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
  ConsumerState<LoadGameListDialog> createState() => _LoadGameListDialogState();
}

class _LoadGameListDialogState extends ConsumerState<LoadGameListDialog> {
  LoadableSaveEntry? _pendingLoad;
  LoadableSaveEntry? _pendingDelete;
  int _manualPageIndex = 0;
  List<LoadableSaveEntry>? _mutablePreview;

  @override
  void initState() {
    super.initState();
    final preview = widget.previewEntries;
    if (preview != null) {
      _mutablePreview = List<LoadableSaveEntry>.from(preview);
    }
    final pendingId = widget.previewPendingDeleteId;
    if (pendingId != null && _mutablePreview != null) {
      for (final entry in _mutablePreview!) {
        if (entry.storageId == pendingId) {
          _pendingDelete = entry;
          break;
        }
      }
    }
  }

  List<LoadableSaveEntry> _currentEntries() {
    return _mutablePreview ??
        ref.read(gameServiceProvider).listLoadableSaves();
  }

  void _onSelect(LoadableSaveEntry entry) {
    if (widget.fromPause) {
      setState(() => _pendingLoad = entry);
      return;
    }
    _loadEntry(entry);
  }

  void _onDiscardCancel() {
    setState(() => _pendingLoad = null);
  }

  void _onDiscardConfirm() {
    final entry = _pendingLoad;
    if (entry == null) {
      return;
    }
    _loadEntry(entry);
  }

  void _onDeleteRequest(LoadableSaveEntry entry) {
    setState(() => _pendingDelete = entry);
  }

  void _onDeleteCancel() {
    setState(() => _pendingDelete = null);
  }

  void _onDeleteConfirm() {
    final entry = _pendingDelete;
    if (entry == null) {
      return;
    }
    if (_mutablePreview != null) {
      _mutablePreview!.removeWhere((e) => e.storageId == entry.storageId);
    } else {
      ref.read(gameServiceProvider).deleteSave(entry.storageId);
    }
    setState(() {
      _pendingDelete = null;
      final manuals = _currentEntries()
          .where((e) => e.kind == LoadableSaveKind.manual)
          .length;
      final pageCount = manuals == 0
          ? 0
          : ((manuals + kLoadGameManualPageSize - 1) ~/
                kLoadGameManualPageSize);
      if (pageCount == 0) {
        _manualPageIndex = 0;
      } else if (_manualPageIndex >= pageCount) {
        _manualPageIndex = pageCount - 1;
      }
    });
  }

  void _loadEntry(LoadableSaveEntry entry) {
    final service = ref.read(gameServiceProvider);
    final container = ProviderScope.containerOf(context, listen: false);
    final session = clearLoadAndApplyGameSession(
      container: container,
      load: () => entry.storageId == kAutoSaveSlotId
          ? service.loadAutoSaveSession()
          : service.loadGameSession(entry.storageId),
    );
    if (session == null) {
      return;
    }
    final bus = ref.read(appEventBusProvider);
    if (widget.fromPause) {
      bus.emit(const ClosePanelEvent());
    } else {
      bus.emit(const NavigateToRouteEvent(Routes.game));
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final titleStyle = (theme.textTheme.titleMedium ?? const TextStyle())
        .copyWith(
          color: EditorialMonoclePalette.accent,
          fontWeight: FontWeight.w700,
        );
    final bodyStyle = (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: EditorialMonoclePalette.fg,
    );
    final mutedStyle = bodyStyle.copyWith(color: EditorialMonoclePalette.muted);
    final entries = _currentEntries();
    final pendingLoad = _pendingLoad;
    final pendingDelete = _pendingDelete;

    LoadableSaveEntry? autoSave;
    final manuals = <LoadableSaveEntry>[];
    for (final entry in entries) {
      if (entry.kind == LoadableSaveKind.autoSave) {
        autoSave = entry;
      } else {
        manuals.add(entry);
      }
    }
    final pageCount = manuals.isEmpty
        ? 0
        : ((manuals.length + kLoadGameManualPageSize - 1) ~/
              kLoadGameManualPageSize);
    final showPager = manuals.length > kLoadGameManualPageSize;
    final pageIndex = pageCount == 0
        ? 0
        : _manualPageIndex.clamp(0, pageCount - 1);
    final pageManuals = pageCount == 0
        ? const <LoadableSaveEntry>[]
        : manuals
              .skip(pageIndex * kLoadGameManualPageSize)
              .take(kLoadGameManualPageSize)
              .toList();

    final showConfirm = pendingDelete != null || pendingLoad != null;

    return CtDialogShell(
      maxWidth: 420,
      maxHeight: 480,
      padding: const EdgeInsets.all(CtSpacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.loadGameList_title, style: titleStyle),
          CtGap.ml,
          if (showConfirm)
            ..._confirmBodyChildren(
              l10n: l10n,
              bodyStyle: bodyStyle,
              pendingDelete: pendingDelete,
              pendingLoad: pendingLoad,
            )
          else
            ..._listAndPagerChildren(
              l10n: l10n,
              bodyStyle: bodyStyle,
              mutedStyle: mutedStyle,
              entries: entries,
              autoSave: autoSave,
              pageManuals: pageManuals,
              showPager: showPager,
              pageIndex: pageIndex,
              pageCount: pageCount,
            ),
        ],
      ),
    );
  }
}
