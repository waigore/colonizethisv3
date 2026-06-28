// New game setup: six slots with nation + leader pickers. Opened via
// OpenDialogEvent id `new_game_leader_selection`. SPEC/ui/new-game-leader-selection-dialog.md.

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
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_app/widgets/gp_default_map_color_swatch.dart';

const int _kNumSlots = 6;

/// Vertical gap between slot rows. Matches the mockup `.slots-list{gap:6px}`.
const double _kSlotListGap = CtSpacing.s;

/// Slot-row inner padding. Matches the mockup `.slot-row{padding:8px 10px}`
/// (vertical 8 dp = [CtSpacing.m]; horizontal 10 dp is a per-component override
/// not on the canonical spacing scale).
const EdgeInsets _kSlotRowPadding = EdgeInsets.symmetric(
  vertical: CtSpacing.m,
  horizontal: 10,
);

/// Horizontal gap between the infinite-mode toggle and its label, also used to
/// indent the helper text. Matches the mockup `.toggle-row{gap:10px}`.
const double _kToggleLabelGap = 10;

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

  /// Slot heading row: `Slot N` plus a `YOU` tag for the human slot (0).
  /// Mirrors the mockup `.slot-label` / `.you-tag`: the literal copy stays
  /// `You` ([AppLocalizations.shell_leaderDialog_slotYouTag]) and uppercasing
  /// is applied here as presentation, matching the mockup's CSS
  /// `text-transform:uppercase`.
  Widget _buildSlotLabel(
    AppLocalizations l10n,
    int slotIndex,
    _LeaderDialogTextStyles styles,
  ) {
    final bool isYou = slotIndex == 0;
    final TextStyle labelStyle = styles.slotLabel.copyWith(
      color: isYou
          ? EditorialMonoclePalette.accentDim
          : EditorialMonoclePalette.muted,
      fontWeight: isYou ? FontWeight.w600 : FontWeight.normal,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n.shell_leaderDialog_slotLabel(slotIndex + 1),
          style: labelStyle,
        ),
        if (isYou) ...[
          const SizedBox(width: CtSpacing.s),
          Text(
            l10n.shell_leaderDialog_slotYouTag.toUpperCase(),
            key: const ValueKey<String>('leaderSelectionDialogSlotYouTag'),
            style: styles.slotYouTag,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final ThemeData theme = Theme.of(context);
    final _LeaderDialogTextStyles styles = _resolveTextStyles(theme);
    final Set<int> duplicateSlots = _duplicateSlotIndices();
    final slotWidgets = <Widget>[
      for (var i = 0; i < _kNumSlots; i++) ...[
        if (i > 0) const SizedBox(height: _kSlotListGap),
        _buildSlotRow(
          context,
          i,
          l10n,
          styles,
          isDuplicate: duplicateSlots.contains(i),
        ),
      ],
    ];
    return CtDialogShell(
      maxWidth: 540,
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
    final TextStyle bodySmall =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
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
      fieldLabel: bodySmall.copyWith(
        color: EditorialMonoclePalette.accentDim,
        fontWeight: FontWeight.w600,
      ),
      helper: bodySmall.copyWith(
        color: EditorialMonoclePalette.muted,
        fontSize: 12,
      ),
      slotLabel: bodySmall.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.48,
      ),
      slotYouTag: bodySmall.copyWith(
        fontSize: 9,
        letterSpacing: 0.54,
        color: EditorialMonoclePalette.accentDim,
        fontWeight: FontWeight.normal,
      ),
      profileInlineLabel: bodySmall.copyWith(
        fontSize: 10,
        letterSpacing: 0.4,
        color: EditorialMonoclePalette.muted,
      ),
    );
  }

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

  Widget _buildSlotRow(
    BuildContext context,
    int slotIndex,
    AppLocalizations l10n,
    _LeaderDialogTextStyles styles, {
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
            hint: l10n.shell_leaderDialog_aiProfileLabel,
            itemLabel: (id) =>
                id.isEmpty ? l10n.shell_leaderDialog_aiProfileNormal : id,
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

    // Mockup `.profile-line`: inline "AI Profile:" label beside the dropdown
    // (AI slots only). The dropdown takes the remaining width.
    final Widget? profileLine = profileDropdown == null
        ? null
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.shell_leaderDialog_aiProfileInlineLabel,
                style: styles.profileInlineLabel,
              ),
              const SizedBox(width: CtSpacing.s),
              Expanded(child: profileDropdown),
            ],
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            EditorialMonoclePalette.surface,
            EditorialMonoclePalette.bgDeep,
          ],
        ),
        border: Border(
          top: BorderSide(color: EditorialMonoclePalette.accentDim),
          bottom: BorderSide(color: EditorialMonoclePalette.accentDim),
        ),
      ),
      child: Padding(
        padding: _kSlotRowPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSlotLabel(l10n, slotIndex, styles),
            const SizedBox(height: CtSpacing.s),
            _SlotPickersBody(
              nationDropdown: nationDropdown,
              leaderDropdown: leaderDropdown,
              profileLine: profileLine,
            ),
          ],
        ),
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
    required this.slotLabel,
    required this.slotYouTag,
    required this.profileInlineLabel,
  });

  final TextStyle title;
  final TextStyle intro;
  final TextStyle fieldLabel;
  final TextStyle helper;
  final TextStyle slotLabel;
  final TextStyle slotYouTag;
  final TextStyle profileInlineLabel;
}

/// Pickers body that switches between a side-by-side `Row` and a vertically
/// stacked `Column` at the [kLeaderSelectionNarrowBreakpoint] (540 dp) viewport
/// width — the DLG10001-dedicated breakpoint matching the mockup
/// `@media (min-width: 540px)` rule.
///
/// SPEC: `SPEC/ui/new-game-leader-selection-dialog.md` § Layout / wireframe
/// + Acceptance Criteria narrow-viewport stacking AC;
/// `SPEC/ui/mobile-adaptation.md` § 4 New game leader selection.
class _SlotPickersBody extends StatelessWidget {
  const _SlotPickersBody({
    required this.nationDropdown,
    required this.leaderDropdown,
    this.profileLine,
  });

  final Widget nationDropdown;
  final Widget leaderDropdown;

  /// Pre-built AI Profile line (inline label + dropdown) for AI slots; `null`
  /// for the human slot (0).
  final Widget? profileLine;

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
        MediaQuery.sizeOf(context).width < kLeaderSelectionNarrowBreakpoint;
    if (narrow) {
      return Column(
        key: stackedColumnKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          nationDropdown,
          const SizedBox(height: stackedGap),
          leaderDropdown,
          if (profileLine != null) ...[
            const SizedBox(height: stackedGap),
            profileLine!,
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
            const SizedBox(width: CtSpacing.s),
            Expanded(child: leaderDropdown),
          ],
        ),
        if (profileLine != null) ...[
          const SizedBox(height: stackedGap),
          profileLine!,
        ],
      ],
    );
  }
}
