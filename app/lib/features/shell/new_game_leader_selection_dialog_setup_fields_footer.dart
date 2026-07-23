part of 'new_game_leader_selection_dialog.dart';

/// Footer actions and start confirmation for [NewGameLeaderSelectionDialog]
/// (Refs #3878).
mixin _NewGameLeaderSelectionDialogSetupFieldsFooter
    on State<NewGameLeaderSelectionDialog>,
        _NewGameLeaderSelectionDialogStateBase,
        _NewGameLeaderSelectionDialogSetupFieldsOptions {
  Widget _buildFooterButtons(AppLocalizations l10n, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CtNinePatchButton(
          onPressed: widget.onCancel,
          child: Text(l10n.common_cancel),
        ),
        const SizedBox(width: CtSpacing.m),
        CtNinePatchButton(
          onPressed: _startEnabled ? () => _handleStartPressed(context) : null,
          enabled: _startEnabled,
          child: Text(l10n.common_start),
        ),
      ],
    );
  }

  void _handleStartPressed(BuildContext context) {
    final seed = NewGameLeaderSelectionDialog.parseSeedInput(
      _seedController.text,
    );
    Navigator.of(context).pop();
    widget.onConfirmed(
      List<String>.from(_orderedGpIdsBySlot),
      Map<String, String>.from(_leaderByGpId),
      seed,
      _infiniteMode,
      _terrainVariation,
      _aiProfileByGpIdForCallback(),
      _advancedStartEnabled ? _advancedStart : AdvancedStartType.none,
    );
  }

  Map<String, String?> _aiProfileByGpIdForCallback() {
    final out = <String, String?>{};
    for (var slot = 1; slot < _kNumSlots; slot++) {
      final gpId = _orderedGpIdsBySlot[slot];
      final profileName = _profileBySlot[slot];
      if (profileName != null && profileName.isNotEmpty) {
        out[gpId] = profileName;
      }
    }
    return out;
  }
}
