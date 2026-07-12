// Load-game list dialog. OpenDialogEvent id `load_game_list`.
// SPEC/ui/load-game-list-dialog.md.

import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/observe_session_provider.dart';
import 'package:colonizethis_app/providers/production_allocation_provider.dart';
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
    final session = entry.storageId == kAutoSaveSlotId
        ? service.loadAutoSaveSession()
        : service.loadGameSession(entry.storageId);
    if (session == null) {
      return;
    }
    ref.read(observeSessionProvider.notifier).reset();
    ref.read(currentGameProvider.notifier).setGame(session.game);
    ref.read(currentOrdersProvider.notifier).replaceAll(session.draftOrders);
    ref
        .read(productionDesiredOutputProvider.notifier)
        .replaceAll(session.productionDesiredOutputByRecipe);
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

  String? _secondaryMetaLine(AppLocalizations l10n, LoadableSaveEntry entry) {
    final turn = entry.turnNumber;
    final year = entry.calendarYear;
    final nation = entry.humanNation;
    if (turn != null && year != null && nation != null && nation.isNotEmpty) {
      return l10n.loadGameList_metaLine(turn, year, nation);
    }
    if (turn != null) {
      return l10n.loadGameList_turnSubtitle(turn);
    }
    return null;
  }

  String? _lastSavedLine(LoadableSaveEntry entry) {
    final at = entry.lastSavedAt;
    if (at == null) {
      return null;
    }
    return DateFormat.yMd().add_jm().format(at.toLocal());
  }

  Widget _rowContent({
    required AppLocalizations l10n,
    required TextStyle bodyStyle,
    required TextStyle mutedStyle,
    required LoadableSaveEntry entry,
  }) {
    final meta = _secondaryMetaLine(l10n, entry);
    final savedAt = _lastSavedLine(entry);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CtNinePatchButton(
            key: LoadGameListDialog.rowKey(entry.storageId),
            onPressed: () => _onSelect(entry),
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
          onPressed: () => _onDeleteRequest(entry),
          child: Text(l10n.loadGameList_delete),
        ),
      ],
    );
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
          if (pendingDelete != null) ...[
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
                  onPressed: _onDeleteCancel,
                  child: Text(l10n.common_cancel),
                ),
                const SizedBox(width: CtSpacing.m),
                CtNinePatchButton(
                  key: LoadGameListDialog.deleteConfirmButtonKey,
                  onPressed: _onDeleteConfirm,
                  child: Text(l10n.loadGameList_delete),
                ),
              ],
            ),
          ] else if (pendingLoad != null) ...[
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
                  onPressed: _onDiscardCancel,
                  child: Text(l10n.common_cancel),
                ),
                const SizedBox(width: CtSpacing.m),
                CtNinePatchButton(
                  key: LoadGameListDialog.discardConfirmButtonKey,
                  onPressed: _onDiscardConfirm,
                  child: Text(l10n.loadGameList_load),
                ),
              ],
            ),
          ] else ...[
            if (entries.isEmpty)
              Text(
                l10n.loadGameList_empty,
                key: LoadGameListDialog.emptyStateKey,
                style: mutedStyle,
              )
            else
              ConstrainedBox(
                key: LoadGameListDialog.listKey,
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (autoSave != null) ...[
                      Container(
                        key: LoadGameListDialog.autoSaveSectionKey,
                        padding: const EdgeInsets.all(CtSpacing.s),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: EditorialMonoclePalette.accent,
                            width: 2,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              EditorialMonoclePalette.surfaceLite,
                              EditorialMonoclePalette.surface,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.loadGameList_autoSaveBadge,
                              style: mutedStyle.copyWith(
                                color: EditorialMonoclePalette.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: CtSpacing.s),
                            _rowContent(
                              l10n: l10n,
                              bodyStyle: bodyStyle,
                              mutedStyle: mutedStyle,
                              entry: autoSave,
                            ),
                          ],
                        ),
                      ),
                      if (pageManuals.isNotEmpty) ...[
                        CtGap.m,
                        const CtBrassDivider(),
                        CtGap.m,
                      ],
                    ],
                    for (var i = 0; i < pageManuals.length; i++) ...[
                      if (i > 0) CtGap.m,
                      _rowContent(
                        l10n: l10n,
                        bodyStyle: bodyStyle,
                        mutedStyle: mutedStyle,
                        entry: pageManuals[i],
                      ),
                    ],
                  ],
                ),
              ),
            if (showPager) ...[
              CtGap.m,
              Row(
                key: LoadGameListDialog.pagerKey,
                children: [
                  CtNinePatchButton(
                    key: LoadGameListDialog.previousButtonKey,
                    onPressed: pageIndex <= 0
                        ? null
                        : () => setState(() => _manualPageIndex = pageIndex - 1),
                    child: Text(l10n.loadGameList_previous),
                  ),
                  Expanded(
                    child: Text(
                      l10n.loadGameList_pageOf(pageIndex + 1, pageCount),
                      key: LoadGameListDialog.pageLabelKey,
                      textAlign: TextAlign.center,
                      style: mutedStyle,
                    ),
                  ),
                  CtNinePatchButton(
                    key: LoadGameListDialog.nextButtonKey,
                    onPressed: pageIndex >= pageCount - 1
                        ? null
                        : () => setState(() => _manualPageIndex = pageIndex + 1),
                    child: Text(l10n.loadGameList_next),
                  ),
                ],
              ),
            ],
            CtGap.l,
            Align(
              alignment: Alignment.centerRight,
              child: CtNinePatchButton(
                key: LoadGameListDialog.closeButtonKey,
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.common_close),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
