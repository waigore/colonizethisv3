// New game setup: six slots with nation + leader pickers. Opened via
// OpenDialogEvent id `new_game_leader_selection`. SPEC/ui/game-setup.md § Shell new game dialog.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/l10n/l10n.dart';
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
    final slotWidgets = <Widget>[];
    for (var i = 0; i < _kNumSlots; i++) {
      slotWidgets.add(_buildSlotRow(context, i, l10n));
    }

    return CtDialogShell(
      maxWidth: 480,
      maxHeight: 720,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shell_leaderDialog_title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.shell_leaderDialog_intro,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: slotWidgets,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.shell_leaderDialog_seedLabel,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _seedController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.shell_leaderDialog_seedHelper,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _infiniteMode,
            onChanged: (value) {
              setState(() => _infiniteMode = value ?? false);
            },
            title: Text(
              l10n.shell_leaderDialog_infiniteModeLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            subtitle: Text(
              l10n.shell_leaderDialog_infiniteModeHelper,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildTerrainVariationField(context, l10n),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CtNinePatchButton(
                onPressed: widget.onCancel,
                child: Text(l10n.common_cancel),
              ),
              const SizedBox(width: 8),
              CtNinePatchButton(
                onPressed: _startEnabled
                    ? () {
                        final seed =
                            NewGameLeaderSelectionDialog.parseSeedInput(
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
                    : null,
                enabled: _startEnabled,
                child: Text(l10n.common_start),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTerrainVariationField(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final percent = (_terrainVariation * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.shell_leaderDialog_terrainVariationLabel(percent),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
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
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
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
