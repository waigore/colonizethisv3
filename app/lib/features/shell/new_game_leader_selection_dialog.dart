// New game setup: six slots with nation + leader pickers. Opened via
// OpenDialogEvent id `new_game_leader_selection`. SPEC/ui/game-setup.md § Shell new game dialog.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app/widgets/gp_default_map_color_swatch.dart';

const int _kNumSlots = 6;

/// Shown when the shell emits `OpenDialogEvent('new_game_leader_selection')`.
class NewGameLeaderSelectionDialog extends StatefulWidget {
  const NewGameLeaderSelectionDialog({
    super.key,
    required this.baseConfig,
    required this.naming,
    required this.initialLeaderByGpId,
    required this.blessedProfileNames,
    required this.onCancel,
    required this.onConfirmed,
  });

  /// SPEC/ui/new-game-leader-selection-dialog.md — [UiScreenIds.newGameLeaderSelectionDialog].
  static const screenId = UiScreenIds.newGameLeaderSelectionDialog;

  /// Template for non-GP fields; [GameSetupConfig.selectedGreatPowerIds] supplies initial six nations.
  final GameSetupConfig baseConfig;
  final ResolvedNamingConfig naming;
  final Map<String, String> initialLeaderByGpId;

  /// Blessed tuned profile names from the asset manifest (sorted).
  final List<String> blessedProfileNames;

  final VoidCallback onCancel;
  final void Function(
    List<String> orderedGreatPowerIds,
    Map<String, String> leaderVariantByGpId,
    int seed,
    bool infiniteMode,
    double terrainVariation,
    Map<String, String?> aiProfileByGpId,
  )
  onConfirmed;

  /// Default terrain-variation slider value (matches `GameSetupConfig.terrainVariation` default).
  static const double defaultTerrainVariation = 0.5;

  /// Width of the danger border painted around a slot's nation dropdown when
  /// the slot's currently-selected Great Power id also appears in another
  /// slot. Pinned to 1 dp so the visual cue does not shift slot layout.
  /// SPEC: `SPEC/ui/new-game-leader-selection-dialog.md` § Duplicate slot
  /// validation feedback (Refs #2867 R19).
  static const double duplicateSlotBorderWidth = 1.0;

  /// Stable key prefix for the danger-border wrapper rendered around the
  /// nation dropdown of slot `slotIndex` when that slot is part of a
  /// duplicate group. Tests pin the per-slot key
  /// `'newGameLeaderDialogSlotDuplicateBorder_<slotIndex>'` so the positive
  /// AC can assert that exactly the duplicate slots carry the danger
  /// border without depending on widget tree order. The wrapper is only
  /// mounted when the slot is detected as a duplicate; non-duplicate
  /// slots render the nation dropdown directly without this key.
  static String duplicateSlotBorderKey(int slotIndex) =>
      'newGameLeaderDialogSlotDuplicateBorder_$slotIndex';

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
  final Map<int, String?> _profileBySlot = <int, String?>{};

  /// Dropdown sentinel for the default hardcoded AI personality.
  static const String normalProfileChoiceId = '';

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

  /// Indices of slots whose currently-selected Great Power id also appears
  /// in at least one other slot. Empty when every populated slot holds a
  /// unique GP id. Empty slot ids (`''`) are ignored so unset slots do not
  /// register as duplicates of one another.
  ///
  /// SPEC: `SPEC/ui/new-game-leader-selection-dialog.md` § Duplicate slot
  /// validation feedback (Refs #2867 R19) — drives the danger border
  /// painted around the duplicate slot's nation dropdown.
  Set<int> _duplicateSlotIndices() {
    final counts = <String, int>{};
    for (final id in _orderedGpIdsBySlot) {
      if (id.isEmpty) {
        continue;
      }
      counts[id] = (counts[id] ?? 0) + 1;
    }
    final duplicates = <int>{};
    for (var i = 0; i < _kNumSlots; i++) {
      final id = _orderedGpIdsBySlot[i];
      if (id.isEmpty) {
        continue;
      }
      if ((counts[id] ?? 0) > 1) {
        duplicates.add(i);
      }
    }
    return duplicates;
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
    final Set<int> duplicateSlots = _duplicateSlotIndices();
    final slotWidgets = <Widget>[
      for (var i = 0; i < _kNumSlots; i++)
        _buildSlotRow(
          context,
          i,
          l10n,
          isDuplicate: duplicateSlots.contains(i),
        ),
    ];
    return CtDialogShell(
      maxWidth: 480,
      maxHeight: 720,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(l10n, styles),
          const SizedBox(height: CtSpacing.l),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: slotWidgets,
          ),
          const SizedBox(height: CtSpacing.ml),
          _buildSeedField(theme, l10n, styles),
          const SizedBox(height: CtSpacing.ml),
          _buildInfiniteModeTile(theme, l10n, styles),
          const SizedBox(height: CtSpacing.ml),
          _buildTerrainVariationField(
            context,
            l10n,
            fieldLabelStyle: styles.fieldLabel,
            helperStyle: styles.helper,
          ),
          const SizedBox(height: CtSpacing.l),
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
            letterSpacing: (theme.textTheme.titleMedium?.fontSize ?? 16) * 0.05,
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
          .copyWith(color: EditorialMonoclePalette.muted, fontSize: 12),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, _LeaderDialogTextStyles styles) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.shell_leaderDialog_title,
          key: const ValueKey<String>('leaderSelectionDialogTitle'),
          style: styles.title,
        ),
        const SizedBox(height: CtSpacing.m),
        const CtBrassDivider(
          key: ValueKey<String>('leaderSelectionDialogBrassDivider'),
        ),
        const SizedBox(height: CtSpacing.ml),
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
        Text(
          l10n.shell_leaderDialog_terrainVariationLabel(percent),
          style: fieldLabelStyle,
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

  Widget _buildSlotRow(
    BuildContext context,
    int slotIndex,
    AppLocalizations l10n, {
    bool isDuplicate = false,
  }) {
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

    final Widget nationDropdownCore = CtDropdown<String>(
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

    // Duplicate slot validation feedback (Refs #2867 R19): wrap the nation
    // dropdown in a 1 dp `--danger` border when this slot's GP id also
    // appears in another slot. The wrapper is keyed by slot index so widget
    // tests can assert that exactly the duplicate slots carry the border.
    // Non-duplicate slots render the dropdown directly (no key) so the
    // negative AC has a definite absence to assert.
    final Widget nationDropdown = isDuplicate
        ? DecoratedBox(
            key: ValueKey<String>(
              NewGameLeaderSelectionDialog.duplicateSlotBorderKey(slotIndex),
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: EditorialMonoclePalette.danger,
                width: NewGameLeaderSelectionDialog.duplicateSlotBorderWidth,
              ),
            ),
            child: nationDropdownCore,
          )
        : nationDropdownCore;

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

    final Widget? profileDropdown = slotIndex == 0
        ? null
        : CtDropdown<String>(
            value: _profileBySlot[slotIndex] ?? normalProfileChoiceId,
            items: <String>[
              normalProfileChoiceId,
              ...widget.blessedProfileNames,
            ],
            hint: 'AI Profile',
            itemLabel: (id) => id.isEmpty ? 'Normal' : id,
            onChanged: (value) {
              setState(() {
                if (value == null || value.isEmpty) {
                  _profileBySlot.remove(slotIndex);
                } else {
                  _profileBySlot[slotIndex] = value;
                }
              });
            },
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: CtSpacing.ml),
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
          const SizedBox(height: CtSpacing.m / 2),
          _SlotPickersBody(
            nationDropdown: nationDropdown,
            leaderDropdown: leaderDropdown,
            profileDropdown: profileDropdown,
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

/// Pickers body that switches between a side-by-side `Row` and a vertically
/// stacked `Column` at the [kGameSetupNarrowBreakpoint] (500 dp) viewport
/// width, mirroring the `CtGameSetup` narrow-stacking rule so the shell
/// dialog (DLG10001) honours the same `< 500 dp` rule as the full-screen
/// Game Setup surface (SHEL20001).
///
/// SPEC: `SPEC/ui/new-game-leader-selection-dialog.md` § Layout / wireframe
/// + Acceptance Criteria narrow-viewport stacking AC; `SPEC/ui/game-setup.md`
/// § Shell new game dialog; `SPEC/ui/mobile-adaptation.md` § 4 Game Setup.
class _SlotPickersBody extends StatelessWidget {
  const _SlotPickersBody({
    required this.nationDropdown,
    required this.leaderDropdown,
    this.profileDropdown,
  });

  final Widget nationDropdown;
  final Widget leaderDropdown;
  final Widget? profileDropdown;

  /// Vertical gap between the nation dropdown and the leader dropdown when
  /// the slot body is stacked (matches the slot label ↔ pickers gap of
  /// `CtSpacing.m / 2` = 4 dp).
  static const double stackedGap = CtSpacing.m / 2;

  /// Key applied to the vertically stacked `Column` body (narrow viewport).
  /// Tests pin the narrow-stacking AC by asserting one such column per slot.
  static const Key stackedColumnKey = ValueKey<String>(
    'newGameLeaderDialogSlotPickersColumn',
  );

  /// Key applied to the side-by-side `Row` body (wide viewport).
  /// Tests pin the wide-row AC by asserting one such row per slot.
  static const Key sideBySideRowKey = ValueKey<String>(
    'newGameLeaderDialogSlotPickersRow',
  );

  @override
  Widget build(BuildContext context) {
    final bool narrow =
        MediaQuery.sizeOf(context).width < kGameSetupNarrowBreakpoint;
    if (narrow) {
      return Column(
        key: stackedColumnKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          nationDropdown,
          const SizedBox(height: stackedGap),
          leaderDropdown,
          if (profileDropdown != null) ...[
            const SizedBox(height: stackedGap),
            profileDropdown!,
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          key: sideBySideRowKey,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: nationDropdown),
            const SizedBox(width: CtSpacing.m),
            Expanded(child: leaderDropdown),
          ],
        ),
        if (profileDropdown != null) ...[
          const SizedBox(height: stackedGap),
          profileDropdown!,
        ],
      ],
    );
  }
}
