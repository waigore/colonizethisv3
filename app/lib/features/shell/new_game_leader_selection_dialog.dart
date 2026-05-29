// New game setup: six slots with nation + leader pickers. Opened via
// OpenDialogEvent id `new_game_leader_selection`. SPEC/ui/game-setup.md § Shell new game dialog.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'package:colonizethis_app/widgets/gp_default_map_color_swatch.dart';

const int _kNumSlots = 6;

/// Shown when the shell emits `OpenDialogEvent('new_game_leader_selection')`.
class NewGameLeaderSelectionDialog extends StatefulWidget {
  const NewGameLeaderSelectionDialog({
    super.key,
    required this.baseConfig,
    required this.naming,
    required this.initialLeaderByGpId,
    required this.onCancel,
    required this.onConfirmed,
  });

  /// SPEC/ui/new-game-leader-selection-dialog.md — [UiScreenIds.newGameLeaderSelectionDialog].
  static const screenId = UiScreenIds.newGameLeaderSelectionDialog;

  /// Template for non-GP fields; [GameSetupConfig.selectedGreatPowerIds] supplies initial six nations.
  final GameSetupConfig baseConfig;
  final ResolvedNamingConfig naming;
  final Map<String, String> initialLeaderByGpId;
  final VoidCallback onCancel;
  final void Function(
    List<String> orderedGreatPowerIds,
    Map<String, String> leaderVariantByGpId,
    int seed,
    bool infiniteMode,
    double terrainVariation,
  )
  onConfirmed;

  /// Default terrain-variation slider value (matches `GameSetupConfig.terrainVariation` default).
  static const double defaultTerrainVariation = 0.5;

  /// Parses seed field text for [GameSetupConfig.seed]: empty or invalid → 42; negative → 42.
  static int parseSeedInput(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return 42;
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < 0) {
      return 42;
    }
    return parsed;
  }

  @override
  State<NewGameLeaderSelectionDialog> createState() =>
      _NewGameLeaderSelectionDialogState();
}

class _NewGameLeaderSelectionDialogState
    extends State<NewGameLeaderSelectionDialog> {
  late List<String> _orderedGpIdsBySlot;
  late Map<String, String> _leaderByGpId;
  late final TextEditingController _seedController;
  bool _infiniteMode = false;
  double _terrainVariation =
      NewGameLeaderSelectionDialog.defaultTerrainVariation;

  List<String> get _allGpIds =>
      widget.naming.greatPowers.map((g) => g.id).toList();

  @override
  void initState() {
    super.initState();
    _seedController = TextEditingController(
      text: widget.baseConfig.seed.toString(),
    );
    final initial = widget.baseConfig.selectedGreatPowerIds;
    _orderedGpIdsBySlot = initial.length == _kNumSlots
        ? List<String>.from(initial)
        : List<String>.from(
            GameSetupConfig.defaultConfig.selectedGreatPowerIds,
          );
    _leaderByGpId = Map<String, String>.from(widget.initialLeaderByGpId);
    for (final id in _orderedGpIdsBySlot) {
      final gp = widget.naming.gpById(id);
      if (gp != null &&
          gp.leaderVariants.isNotEmpty &&
          !_leaderByGpId.containsKey(id)) {
        _leaderByGpId[id] = gp.defaultLeaderVariantId;
      }
    }
  }

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  List<String> _availableGpIdsForSlot(int slotIndex) {
    final current = _orderedGpIdsBySlot[slotIndex];
    final takenElsewhere = <String>{};
    for (var j = 0; j < _kNumSlots; j++) {
      if (j != slotIndex) {
        final id = _orderedGpIdsBySlot[j];
        if (id.isNotEmpty) {
          takenElsewhere.add(id);
        }
      }
    }
    final out = <String>[];
    for (final id in _allGpIds) {
      if (!takenElsewhere.contains(id) || id == current) {
        out.add(id);
      }
    }
    return out;
  }

  bool get _startEnabled {
    final seen = <String>{};
    for (var i = 0; i < _kNumSlots; i++) {
      final id = _orderedGpIdsBySlot[i];
      if (id.isEmpty) {
        return false;
      }
      if (seen.contains(id)) {
        return false;
      }
      seen.add(id);
      final gp = widget.naming.gpById(id);
      if (gp == null || gp.leaderVariants.isEmpty) {
        return false;
      }
      final vid = _leaderByGpId[id] ?? gp.defaultLeaderVariantId;
      if (!gp.leaderVariants.any((v) => v.id == vid)) {
        return false;
      }
    }
    return true;
  }

  String _slotLabel(AppLocalizations l10n, int slotIndex) {
    final slotNumber = slotIndex + 1;
    return slotIndex == 0
        ? l10n.shell_newGame_playerYou(slotNumber)
        : l10n.shell_newGame_playerAi(slotNumber);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final ThemeData theme = Theme.of(context);
    final _LeaderDialogTextStyles styles = _resolveTextStyles(theme);
    final slotWidgets = <Widget>[
      for (var i = 0; i < _kNumSlots; i++) _buildSlotRow(context, i, l10n),
    ];
    return CtDialogShell(
      maxWidth: 480,
      maxHeight: 720,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(l10n, styles),
          const SizedBox(height: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: slotWidgets,
          ),
          const SizedBox(height: 12),
          _buildSeedField(theme, l10n, styles),
          const SizedBox(height: 12),
          _buildInfiniteModeTile(theme, l10n, styles),
          const SizedBox(height: 12),
          _buildTerrainVariationField(
            context,
            l10n,
            fieldLabelStyle: styles.fieldLabel,
            helperStyle: styles.helper,
          ),
          const SizedBox(height: 16),
          _buildFooterButtons(l10n, context),
        ],
      ),
    );
  }

  _LeaderDialogTextStyles _resolveTextStyles(ThemeData theme) {
    return _LeaderDialogTextStyles(
      title: (theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16))
          .copyWith(
            color: EditorialMonoclePalette.accent,
            letterSpacing:
                (theme.textTheme.titleMedium?.fontSize ?? 16) * 0.05,
            fontWeight: FontWeight.w600,
          ),
      intro: (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14))
          .copyWith(
            color: EditorialMonoclePalette.muted,
            fontStyle: FontStyle.italic,
          ),
      fieldLabel: (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12))
          .copyWith(
            color: EditorialMonoclePalette.accentDim,
            fontWeight: FontWeight.w600,
          ),
      helper: (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12))
          .copyWith(
            color: EditorialMonoclePalette.muted,
            fontSize: 12,
          ),
    );
  }

  Widget _buildHeader(
    AppLocalizations l10n,
    _LeaderDialogTextStyles styles,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.shell_leaderDialog_title,
          key: const ValueKey<String>('leaderSelectionDialogTitle'),
          style: styles.title,
        ),
        const SizedBox(height: 8),
        const CtBrassDivider(
          key: ValueKey<String>('leaderSelectionDialogBrassDivider'),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.shell_leaderDialog_intro,
          key: const ValueKey<String>('leaderSelectionDialogIntro'),
          style: styles.intro,
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
        const SizedBox(height: 4),
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
        const SizedBox(height: 6),
        Text(l10n.shell_leaderDialog_seedHelper, style: styles.helper),
      ],
    );
  }

  Widget _buildInfiniteModeTile(
    ThemeData theme,
    AppLocalizations l10n,
    _LeaderDialogTextStyles styles,
  ) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: _infiniteMode,
      activeColor: EditorialMonoclePalette.accent,
      checkColor: EditorialMonoclePalette.bgDeep,
      side: BorderSide(color: EditorialMonoclePalette.border),
      onChanged: (value) {
        setState(() => _infiniteMode = value ?? false);
      },
      title: Text(
        l10n.shell_leaderDialog_infiniteModeLabel,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: EditorialMonoclePalette.fg,
        ),
      ),
      subtitle: Text(
        l10n.shell_leaderDialog_infiniteModeHelper,
        style: styles.helper,
      ),
    );
  }

  Widget _buildFooterButtons(
    AppLocalizations l10n,
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CtNinePatchButton(
          onPressed: widget.onCancel,
          child: Text(l10n.common_cancel),
        ),
        const SizedBox(width: 8),
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
    );
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
        Text(
          l10n.shell_leaderDialog_terrainVariationLabel(percent),
          style: fieldLabelStyle,
        ),
        const SizedBox(height: 6),
        CtSlider(
          value: _terrainVariation,
          min: 0.0,
          max: 1.0,
          divisions: 20,
          onChanged: (value) {
            setState(() => _terrainVariation = value);
          },
        ),
        const SizedBox(height: 6),
        Text(
          l10n.shell_leaderDialog_terrainVariationHelper,
          style: helperStyle,
        ),
      ],
    );
  }

  Widget _buildSlotRow(
    BuildContext context,
    int slotIndex,
    AppLocalizations l10n,
  ) {
    final gpId = _orderedGpIdsBySlot[slotIndex];
    final available = _availableGpIdsForSlot(slotIndex);
    final effectiveGpId = available.contains(gpId) ? gpId : available.first;
    final gp = widget.naming.gpById(effectiveGpId);
    if (gp == null || gp.leaderVariants.isEmpty) {
      return const SizedBox.shrink();
    }
    final variants = gp.leaderVariants;
    final currentVariantId =
        _leaderByGpId[effectiveGpId] ?? gp.defaultLeaderVariantId;

    final nationDropdown = CtDropdown<String>(
      value: effectiveGpId,
      items: available,
      hint: l10n.shell_newGame_selectNation,
      itemLabel: (id) => widget.naming.gpById(id)?.countryName ?? id,
      itemLeading: (ctx, id) => GpDefaultMapColorSwatch(greatPowerId: id),
      onChanged: (value) {
        if (value == null) {
          return;
        }
        final newGp = widget.naming.gpById(value);
        if (newGp == null) {
          return;
        }
        setState(() {
          _orderedGpIdsBySlot[slotIndex] = value;
          _leaderByGpId[value] = newGp.defaultLeaderVariantId;
        });
      },
    );

    final leaderDropdown = CtDropdown<String>(
      value: variants.any((v) => v.id == currentVariantId)
          ? currentVariantId
          : variants.first.id,
      items: variants.map((v) => v.id).toList(),
      hint: l10n.shell_leaderDialog_selectLeaderHint,
      itemLabel: (id) => variants.firstWhere((v) => v.id == id).name,
      onChanged: (value) {
        if (value != null) {
          setState(() => _leaderByGpId[effectiveGpId] = value);
        }
      },
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _slotLabel(l10n, slotIndex),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: slotIndex == 0
                  ? EditorialMonoclePalette.accentDim
                  : EditorialMonoclePalette.muted,
              fontWeight: slotIndex == 0 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: nationDropdown),
              const SizedBox(width: 8),
              Expanded(child: leaderDropdown),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderDialogTextStyles {
  const _LeaderDialogTextStyles({
    required this.title,
    required this.intro,
    required this.fieldLabel,
    required this.helper,
  });

  final TextStyle title;
  final TextStyle intro;
  final TextStyle fieldLabel;
  final TextStyle helper;
}
