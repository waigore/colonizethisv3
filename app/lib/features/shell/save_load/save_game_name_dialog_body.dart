part of 'save_game_name_dialog.dart';

extension on _SaveGameNameDialogState {
  void _persist(String saveGameId, String displayName) {
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

  Widget _actionRow({
    required Key cancelKey,
    required Key confirmKey,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    required String cancelLabel,
    required String confirmLabel,
  }) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CtNinePatchButton(
            key: cancelKey,
            onPressed: onCancel,
            child: Text(cancelLabel),
          ),
          const SizedBox(width: CtSpacing.m),
          CtNinePatchButton(
            key: confirmKey,
            onPressed: onConfirm,
            child: Text(confirmLabel),
          ),
        ],
      );

  Widget _dialogBody(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final titleStyle = (theme.textTheme.titleMedium ?? const TextStyle())
        .copyWith(
          color: EditorialMonoclePalette.accent,
          fontWeight: FontWeight.w700,
        );
    final bodyStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.fg);
    final idleBorder = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: EditorialMonoclePalette.border),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.saveGameName_title, style: titleStyle),
        CtGap.ml,
        TextField(
          key: SaveGameNameDialog.nameFieldKey,
          controller: _controller,
          style: bodyStyle,
          decoration: InputDecoration(
            isDense: true,
            border: idleBorder,
            enabledBorder: idleBorder,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(
                color: EditorialMonoclePalette.accent,
                width: 2,
              ),
            ),
          ),
          onChanged: (_) {
            if (_errorText != null || _awaitingOverwrite) _setFeedback();
          },
        ),
        if (_errorText != null) ...[
          CtGap.m,
          Text(
            _errorText!,
            key: SaveGameNameDialog.errorTextKey,
            style: bodyStyle.copyWith(color: EditorialMonoclePalette.danger),
          ),
        ],
        if (_awaitingOverwrite) ...[
          CtGap.m,
          Text(
            l10n.saveGameName_overwriteConfirm,
            key: SaveGameNameDialog.overwriteConfirmKey,
            style: bodyStyle,
          ),
          CtGap.m,
          _actionRow(
            cancelKey: SaveGameNameDialog.overwriteCancelButtonKey,
            confirmKey: SaveGameNameDialog.overwriteConfirmButtonKey,
            onCancel: _onOverwriteCancel,
            onConfirm: _onOverwriteConfirm,
            cancelLabel: l10n.common_cancel,
            confirmLabel: l10n.saveGameName_overwrite,
          ),
        ] else ...[
          CtGap.l,
          _actionRow(
            cancelKey: SaveGameNameDialog.cancelButtonKey,
            confirmKey: SaveGameNameDialog.saveButtonKey,
            onCancel: _onCancel,
            onConfirm: _onSavePressed,
            cancelLabel: l10n.common_cancel,
            confirmLabel: l10n.saveGameName_save,
          ),
        ],
      ],
    );
  }
}
