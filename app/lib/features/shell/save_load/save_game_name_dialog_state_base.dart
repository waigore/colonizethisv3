import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/production_allocation_provider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'save_game_name_dialog.dart';

/// Shared mutable state for [SaveGameNameDialog] (Refs #4117 de-part).
mixin SaveGameNameDialogStateBase on ConsumerState<SaveGameNameDialog> {
  late final TextEditingController controller;
  String? errorText;
  bool awaitingOverwrite = false;
  String? pendingSanitizedId;
  String? pendingDisplayName;

  void setFeedback({
    String? error,
    bool awaiting = false,
    String? id,
    String? name,
  }) {
    setState(() {
      errorText = error;
      awaitingOverwrite = awaiting;
      pendingSanitizedId = id;
      pendingDisplayName = name;
    });
  }

  void onCancel() => Navigator.of(context).pop();

  void onSavePressed() {
    final typed = controller.text;
    final sanitized = sanitizeGameId(typed);
    if (sanitized == null) {
      setFeedback(error: appL10n(context).saveGameName_invalidName);
      return;
    }
    final service = ref.read(gameServiceProvider);
    if (service.listGameIds().contains(sanitized)) {
      setFeedback(awaiting: true, id: sanitized, name: typed.trim());
      return;
    }
    if (!service.canCreateNewManualSave()) {
      setFeedback(error: appL10n(context).saveGameName_atCapError);
      return;
    }
    persist(sanitized, typed.trim());
  }

  void onOverwriteConfirm() {
    final id = pendingSanitizedId;
    final name = pendingDisplayName;
    if (id != null && name != null) persist(id, name);
  }

  void onOverwriteCancel() => setFeedback();

  void persist(String saveGameId, String displayName) {
    final game = ref.read(currentGameProvider);
    if (game == null) return;
    ref.read(gameServiceProvider).saveGameSession(
      sessionGame: game,
      saveGameId: saveGameId,
      draftOrders: ref.read(currentOrdersProvider),
      productionDesiredOutputByRecipe: ref.read(productionDesiredOutputProvider),
      displayName: displayName,
    );
    ref.read(appEventBusProvider).emit(
      ShowSnackBarEvent(message: appL10n(context).saveGameName_gameSaved),
    );
    if (mounted) Navigator.of(context).pop();
  }
}
