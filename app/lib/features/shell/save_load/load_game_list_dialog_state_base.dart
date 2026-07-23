// Shared mutable state and handlers for [LoadGameListDialog] mixins (Refs #4117).

import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/game_session_clear.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'load_game_list_dialog_widget.dart';

mixin LoadGameListDialogStateBase on ConsumerState<LoadGameListDialog> {
  LoadableSaveEntry? pendingLoad;
  LoadableSaveEntry? pendingDelete;
  int manualPageIndex = 0;
  List<LoadableSaveEntry>? mutablePreview;

  @override
  void initState() {
    super.initState();
    final preview = widget.previewEntries;
    if (preview != null) {
      mutablePreview = List<LoadableSaveEntry>.from(preview);
    }
    final pendingId = widget.previewPendingDeleteId;
    if (pendingId != null && mutablePreview != null) {
      for (final entry in mutablePreview!) {
        if (entry.storageId == pendingId) {
          pendingDelete = entry;
          break;
        }
      }
    }
  }

  List<LoadableSaveEntry> currentEntries() {
    return mutablePreview ?? ref.read(gameServiceProvider).listLoadableSaves();
  }

  void onSelect(LoadableSaveEntry entry) {
    if (widget.fromPause) {
      setState(() => pendingLoad = entry);
      return;
    }
    loadEntry(entry);
  }

  void onDiscardCancel() {
    setState(() => pendingLoad = null);
  }

  void onDiscardConfirm() {
    final entry = pendingLoad;
    if (entry == null) {
      return;
    }
    loadEntry(entry);
  }

  void onDeleteRequest(LoadableSaveEntry entry) {
    setState(() => pendingDelete = entry);
  }

  void onDeleteCancel() {
    setState(() => pendingDelete = null);
  }

  void onDeleteConfirm() {
    final entry = pendingDelete;
    if (entry == null) {
      return;
    }
    if (mutablePreview != null) {
      mutablePreview!.removeWhere((e) => e.storageId == entry.storageId);
    } else {
      ref.read(gameServiceProvider).deleteSave(entry.storageId);
    }
    setState(() {
      pendingDelete = null;
      final manuals = currentEntries()
          .where((e) => e.kind == LoadableSaveKind.manual)
          .length;
      final pageCount = manuals == 0
          ? 0
          : ((manuals + kLoadGameManualPageSize - 1) ~/
                kLoadGameManualPageSize);
      if (pageCount == 0) {
        manualPageIndex = 0;
      } else if (manualPageIndex >= pageCount) {
        manualPageIndex = pageCount - 1;
      }
    });
  }

  void loadEntry(LoadableSaveEntry entry) {
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
}
