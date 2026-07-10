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
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lists loadable saves (manual + auto-save). Optional discard confirm from pause.
class LoadGameListDialog extends ConsumerStatefulWidget {
  const LoadGameListDialog({
    super.key,
    this.fromPause = false,
    this.previewEntries,
  });

  /// SPEC/ui/load-game-list-dialog.md — [UiScreenIds.loadGameListDialog].
  static const screenId = UiScreenIds.loadGameListDialog;

  /// When true, confirm discard of the active session before loading.
  final bool fromPause;

  /// Optional fixed list for Widgetbook / tests (skips [GameService] listing).
  final List<LoadableSaveEntry>? previewEntries;

  static const Key emptyStateKey = ValueKey<String>(
    'loadGameListDialog.emptyState',
  );
  static const Key listKey = ValueKey<String>('loadGameListDialog.list');
  static const Key discardConfirmKey = ValueKey<String>(
    'loadGameListDialog.discardConfirm',
  );
  static const Key discardCancelButtonKey = ValueKey<String>(
    'loadGameListDialog.discardCancel',
  );
  static const Key discardConfirmButtonKey = ValueKey<String>(
    'loadGameListDialog.discardConfirmButton',
  );
  static const Key closeButtonKey = ValueKey<String>(
    'loadGameListDialog.closeButton',
  );

  static Key rowKey(String storageId) =>
      ValueKey<String>('loadGameListDialog.row_$storageId');

  @override
  ConsumerState<LoadGameListDialog> createState() => _LoadGameListDialogState();
}

class _LoadGameListDialogState extends ConsumerState<LoadGameListDialog> {
  LoadableSaveEntry? _pendingEntry;

  void _onSelect(LoadableSaveEntry entry) {
    if (widget.fromPause) {
      setState(() => _pendingEntry = entry);
      return;
    }
    _loadEntry(entry);
  }

  void _onDiscardCancel() {
    setState(() => _pendingEntry = null);
  }

  void _onDiscardConfirm() {
    final entry = _pendingEntry;
    if (entry == null) {
      return;
    }
    _loadEntry(entry);
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
    final entries =
        widget.previewEntries ??
        ref.read(gameServiceProvider).listLoadableSaves();
    final pending = _pendingEntry;

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
          if (pending != null) ...[
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
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => CtGap.m,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final turn = entry.turnNumber;
                    return CtNinePatchButton(
                      key: LoadGameListDialog.rowKey(entry.storageId),
                      onPressed: () => _onSelect(entry),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(entry.label, style: bodyStyle),
                          if (turn != null)
                            Text(
                              l10n.loadGameList_turnSubtitle(turn),
                              style: mutedStyle,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
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
