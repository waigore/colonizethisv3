part of 'new_game_leader_selection_dialog.dart';

/// Seed, advanced-start, infinite-mode, terrain, and footer fields for
/// [NewGameLeaderSelectionDialog] (Refs #3878 shell modularization).
mixin _NewGameLeaderSelectionDialogSetupFields
    on State<NewGameLeaderSelectionDialog>, _NewGameLeaderSelectionDialogStateBase {
  Widget _buildHeader(AppLocalizations l10n, _LeaderDialogTextStyles styles) {
    // Mockup header order (DLG10001 `.dialog-body`): centered title, centered
    // italic intro, then the brass divider beneath both.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n.shell_leaderDialog_title,
          key: const ValueKey<String>('leaderSelectionDialogTitle'),
          style: styles.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: CtSpacing.xs),
        Text(
          l10n.shell_leaderDialog_intro,
          key: const ValueKey<String>('leaderSelectionDialogIntro'),
          style: styles.intro,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: CtSpacing.ml),
        const CtBrassDivider(
          key: ValueKey<String>('leaderSelectionDialogBrassDivider'),
        ),
      ],
    );
  }

  Widget _buildSeedField(
    ThemeData theme,
    AppLocalizations l10n,
    _LeaderDialogTextStyles styles,
  ) {
    final OutlineInputBorder idleBorder = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: EditorialMonoclePalette.border),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.shell_leaderDialog_seedLabel, style: styles.fieldLabel),
        const SizedBox(height: CtSpacing.m / 2),
        TextField(
          controller: _seedController,
          keyboardType: TextInputType.number,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: EditorialMonoclePalette.fg,
          ),
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
        ),
        const SizedBox(height: CtSpacing.s),
        Text(l10n.shell_leaderDialog_seedHelper, style: styles.helper),
      ],
    );
  }

  bool get _advancedStartEnabled => widget.baseConfig.isLockedFullInitProfile;

  String _advancedStartLabel(AppLocalizations l10n, AdvancedStartType type) {
    return switch (type) {
      AdvancedStartType.none => l10n.shell_leaderDialog_advancedStartNone,
      AdvancedStartType.turns50 => l10n.shell_leaderDialog_advancedStart50,
      AdvancedStartType.turns100 => l10n.shell_leaderDialog_advancedStart100,
    };
  }

  Widget _buildAdvancedStartField(
    ThemeData theme,
    AppLocalizations l10n,
    _LeaderDialogTextStyles styles,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.shell_leaderDialog_advancedStartLabel,
          style: styles.fieldLabel,
        ),
        const SizedBox(height: CtSpacing.m / 2),
        AbsorbPointer(
          absorbing: !_advancedStartEnabled,
          child: Opacity(
            opacity: _advancedStartEnabled ? 1 : 0.5,
            child: CtDropdown<AdvancedStartType>(
              value: _advancedStart,
              items: AdvancedStartType.values,
              itemLabel: (type) => _advancedStartLabel(l10n, type),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _advancedStart = value);
              },
            ),
          ),
        ),
        if (!_advancedStartEnabled) ...[
          const SizedBox(height: CtSpacing.s),
          Text(
            l10n.shell_leaderDialog_advancedStartDisabledHelper,
            style: styles.helper,
          ),
        ],
      ],
    );
  }

  Widget _buildInfiniteModeTile(
    ThemeData theme,
    AppLocalizations l10n,
    _LeaderDialogTextStyles styles,
  ) {
    // Mockup `.toggle-row`: CtToggleSwitch beside the label, helper text
    // indented beneath (no Material `CheckboxListTile` chrome per
    // `pixel-art-ui-catalog.md`).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: CtToggleSwitch(
                value: _infiniteMode,
                onChanged: (value) {
                  setState(() => _infiniteMode = value);
                },
              ),
            ),
            const SizedBox(width: _kToggleLabelGap),
            Expanded(
              child: Text(
                l10n.shell_leaderDialog_infiniteModeLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: EditorialMonoclePalette.fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: CtSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(
            left: CtToggleSwitch.trackWidth + _kToggleLabelGap,
          ),
          child: Text(
            l10n.shell_leaderDialog_infiniteModeHelper,
            style: styles.helper,
          ),
        ),
      ],
    );
  }

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

  Widget _buildTerrainVariationField(
    BuildContext context,
    AppLocalizations l10n, {
    required TextStyle fieldLabelStyle,
    required TextStyle helperStyle,
  }) {
    final percent = (_terrainVariation * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mockup `.slider-row`: static label on the left, live mono percent
        // value beside it, slider below. The label flexes so it wraps rather
        // than overflowing at the 320 dp minimum viewport.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                l10n.shell_leaderDialog_terrainVariationLabel,
                style: fieldLabelStyle,
              ),
            ),
            const SizedBox(width: CtSpacing.m),
            Text(
              l10n.shell_leaderDialog_terrainVariationValue(percent),
              key: const ValueKey<String>(
                'leaderSelectionDialogTerrainVariationValue',
              ),
              style: fieldLabelStyle.copyWith(
                color: EditorialMonoclePalette.accentDim,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: CtSpacing.s),
        CtSlider(
          value: _terrainVariation,
          min: 0.0,
          max: 1.0,
          divisions: 20,
          onChanged: (value) {
            setState(() => _terrainVariation = value);
          },
        ),
        const SizedBox(height: CtSpacing.s),
        Text(
          l10n.shell_leaderDialog_terrainVariationHelper,
          style: helperStyle,
        ),
      ],
    );
  }
}
