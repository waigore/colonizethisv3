import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/editorial_monocle_palette.dart';
import '../config/ui_screen_ids.dart';
import '../l10n/l10n.dart';
import 'ct_back_button.dart';
import 'ct_brass_divider.dart';
import 'ct_dropdown.dart';
import 'ct_gradients.dart';
import 'ct_loading_indicator.dart';
import 'ct_nine_patch_button.dart';
import 'gp_default_map_color_swatch.dart';

/// Visual variant of the Game Setup screen. SPEC/ui/game-setup.md; UXD 03b.
enum GameSetupVariant {
  /// Standard Flutter widgets with colonial theme.
  plain,

  /// Same layout with pixel-art button assets from main menu (reused).
  pixelArt,
}

/// Content state of the Game Setup screen. SPEC/ui/game-setup.md; UXD 03b.
enum GameSetupState {
  /// Start Game and dropdowns enabled.
  default_,

  /// Start disabled, loading indicator; Back remains enabled.
  loading,
}

/// Number of player slots. Slot 0 = human, 1..5 = AI. SPEC/ui/game-setup.md.
const int _kNumSlots = 6;

/// Game Setup screen. Six player slots; slot 0 = human, 1–5 = AI.
/// Per slot: nation (GP) dropdown, then leader dropdown for that nation.
/// Nations/leaders chosen in one slot are excluded from others. Min 44 dp touch targets.
class CtGameSetup extends StatefulWidget {
  const CtGameSetup({
    super.key,
    required this.variant,
    required this.state,
    required this.naming,
    required this.initialOrderedGpIds,
    required this.initialLeaderVariantByGpId,
    required this.onStartGame,
    required this.onBack,
  });

  /// SPEC/ui/game-setup.md — [UiScreenIds.gameSetup].
  static const screenId = UiScreenIds.gameSetup;

  final GameSetupVariant variant;
  final GameSetupState state;
  final ResolvedNamingConfig naming;
  final List<String> initialOrderedGpIds;
  final Map<String, String> initialLeaderVariantByGpId;
  final void Function(
    List<String> orderedGpIdsForSlots,
    Map<String, String> leaderVariantByGpId,
  )
  onStartGame;
  final VoidCallback onBack;

  @override
  State<CtGameSetup> createState() => _CtGameSetupState();
}

class _CtGameSetupState extends State<CtGameSetup> {
  late List<String> _orderedGpIdsBySlot;
  late Map<String, String> _leaderVariantByGpId;

  List<String> get _allGpIds =>
      widget.naming.greatPowers.map((g) => g.id).toList();

  @override
  void initState() {
    super.initState();
    final all = widget.naming.greatPowers.map((g) => g.id).toList();
    _orderedGpIdsBySlot = List<String>.from(widget.initialOrderedGpIds);
    if (_orderedGpIdsBySlot.length != _kNumSlots) {
      _orderedGpIdsBySlot = _padOrTrimToSlots(_orderedGpIdsBySlot, all);
    } else if (_orderedGpIdsBySlot.every((id) => id.isEmpty)) {
      _orderedGpIdsBySlot = List.filled(_kNumSlots, '');
    }
    _leaderVariantByGpId = Map<String, String>.from(
      widget.initialLeaderVariantByGpId,
    );
  }

  @override
  void didUpdateWidget(covariant CtGameSetup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialOrderedGpIds != widget.initialOrderedGpIds ||
        oldWidget.initialLeaderVariantByGpId !=
            widget.initialLeaderVariantByGpId) {
      final all = widget.naming.greatPowers.map((g) => g.id).toList();
      _orderedGpIdsBySlot = List<String>.from(widget.initialOrderedGpIds);
      if (_orderedGpIdsBySlot.length != _kNumSlots) {
        _orderedGpIdsBySlot = _padOrTrimToSlots(_orderedGpIdsBySlot, all);
      } else if (_orderedGpIdsBySlot.every((id) => id.isEmpty)) {
        _orderedGpIdsBySlot = List.filled(_kNumSlots, '');
      }
      _leaderVariantByGpId = Map<String, String>.from(
        widget.initialLeaderVariantByGpId,
      );
    }
  }

  /// GP ids available for this slot: empty string (unselected) plus nations not selected in other slots, or current.
  List<String> _availableGpIdsForSlot(int slotIndex) {
    final others = _allGpIds.where((id) {
      final indexOf = _orderedGpIdsBySlot.indexOf(id);
      return indexOf == -1 || indexOf == slotIndex;
    }).toList();
    return ['', ...others];
  }

  bool get _isLoading => widget.state == GameSetupState.loading;
  bool get _startEnabled =>
      !_isLoading && _orderedGpIdsBySlot.every((id) => id.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final bool narrow =
        MediaQuery.sizeOf(context).width < kGameSetupNarrowBreakpoint;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    _GameSetupLoadingRegion(
                      isLoading: _isLoading,
                      loadingLabel: l10n.gameSetup_loadingGeneratingWorld,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _GameSetupHeader(variant: widget.variant),
                          const SizedBox(height: 24),
                          _buildSlots(context, narrow: narrow),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _GameSetupActionsAndBackRegion(
                      variant: widget.variant,
                      startEnabled: _startEnabled,
                      onStart: _startEnabled ? _onStartGame : null,
                      onBack: widget.onBack,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlots(BuildContext context, {required bool narrow}) {
    final l10n = appL10n(context);
    final rows = <Widget>[];
    for (var i = 0; i < _kNumSlots; i++) {
      final label = i == 0
          ? l10n.gameSetup_player1You
          : l10n.gameSetup_playerAiSlot(i + 1);
      rows.add(_buildSlotRow(context, i, label, narrow: narrow));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  Widget _buildSlotRow(
    BuildContext context,
    int slotIndex,
    String slotLabel, {
    required bool narrow,
  }) {
    final gpId = _orderedGpIdsBySlot[slotIndex];
    final gp = gpId.isEmpty ? null : widget.naming.gpById(gpId);
    final availableGpIds = _availableGpIdsForSlot(slotIndex);
    final variants = gp?.leaderVariants ?? <LeaderVariant>[];
    final currentVariantId = gp != null
        ? (_leaderVariantByGpId[gpId] ?? gp.defaultLeaderVariantId)
        : '';

    final Widget labelWidget = Text(
      slotLabel,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: slotIndex == 0 ? FontWeight.w600 : null,
      ),
    );

    final l10n = appL10n(context);
    final Widget nationDropdown = CtDropdown<String>(
      value: availableGpIds.contains(gpId)
          ? gpId
          : (availableGpIds.isNotEmpty ? availableGpIds.first : null),
      items: availableGpIds,
      hint: l10n.gameSetup_selectNation,
      itemLabel: (id) => id.isEmpty
          ? l10n.gameSetup_selectNation
          : (widget.naming.gpById(id)?.countryName ?? id),
      itemLeading: (ctx, id) => id.isEmpty
          ? null
          : GpDefaultMapColorSwatch(greatPowerId: id),
      onChanged: _isLoading
          ? (_) {}
          : (value) {
              if (value != null) {
                if (value.isEmpty) {
                  setState(() {
                    _orderedGpIdsBySlot[slotIndex] = '';
                  });
                  return;
                }
                final newGp = widget.naming.gpById(value);
                if (newGp != null) {
                  setState(() {
                    _orderedGpIdsBySlot[slotIndex] = value;
                    _leaderVariantByGpId[value] = newGp.defaultLeaderVariantId;
                  });
                }
              }
            },
    );

    final Widget leaderDropdown = gpId.isEmpty
        ? _buildDisabledLeaderDropdown(l10n.gameSetup_selectLeader)
        : CtDropdown<String>(
            value: variants.any((v) => v.id == currentVariantId)
                ? currentVariantId
                : (variants.isNotEmpty ? variants.first.id : null),
            items: variants.map((v) => v.id).toList(),
            hint: l10n.gameSetup_selectLeader,
            itemLabel: (id) => variants.firstWhere((v) => v.id == id).name,
            onChanged: _isLoading
                ? (_) {}
                : (value) {
                    if (value != null) {
                      setState(() => _leaderVariantByGpId[gpId] = value);
                    }
                  },
          );

    return _SlotRowChrome(
      variant: widget.variant,
      child: narrow
          ? _buildNarrowSlotBody(
              labelWidget: labelWidget,
              nationDropdown: nationDropdown,
              leaderDropdown: leaderDropdown,
            )
          : _buildWideSlotBody(
              labelWidget: labelWidget,
              nationDropdown: nationDropdown,
              leaderDropdown: leaderDropdown,
            ),
    );
  }

  /// Leader picker rendered at [_SlotRowChrome.disabledLeaderOpacity] when no
  /// nation has been selected for the slot, per #2868 R10 ("Leader dropdown
  /// disabled until nation selected; 0.4 opacity when no nation"). The
  /// disabled widget is still the same `CtDropdown<String>` shape so the
  /// surrounding layout (row/column widths, gap spacing) is unchanged when
  /// the nation becomes selected.
  Widget _buildDisabledLeaderDropdown(String hint) {
    return Opacity(
      opacity: _SlotRowChrome.disabledLeaderOpacity,
      child: IgnorePointer(
        ignoring: true,
        child: CtDropdown<String>(
          value: '',
          items: const [''],
          hint: hint,
          itemLabel: (_) => hint,
          onChanged: (_) {},
        ),
      ),
    );
  }

  Widget _buildNarrowSlotBody({
    required Widget labelWidget,
    required Widget nationDropdown,
    required Widget leaderDropdown,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        labelWidget,
        const SizedBox(height: 4),
        nationDropdown,
        const SizedBox(height: 4),
        leaderDropdown,
      ],
    );
  }

  Widget _buildWideSlotBody({
    required Widget labelWidget,
    required Widget nationDropdown,
    required Widget leaderDropdown,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 100, child: labelWidget),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: nationDropdown),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: leaderDropdown),
      ],
    );
  }

  void _onStartGame() {
    final leaderMap = <String, String>{};
    for (final gpId in _orderedGpIdsBySlot) {
      final variantId = _leaderVariantByGpId[gpId];
      if (variantId != null && variantId.isNotEmpty) {
        leaderMap[gpId] = variantId;
      } else {
        final gp = widget.naming.gpById(gpId);
        if (gp != null && gp.leaderVariants.isNotEmpty) {
          leaderMap[gpId] = gp.defaultLeaderVariantId;
        }
      }
    }
    widget.onStartGame(List<String>.from(_orderedGpIdsBySlot), leaderMap);
  }
}

/// Pads or trims [list] to 6 slots using [allGpIds] for fill; no duplicates.
List<String> _padOrTrimToSlots(List<String> list, List<String> allGpIds) {
  const kNumSlots = 6;
  final result = <String>[];
  final used = <String>{};
  for (var i = 0; i < kNumSlots; i++) {
    final candidate = i < list.length ? list[i] : '';
    if (candidate.isNotEmpty && !used.contains(candidate)) {
      result.add(candidate);
      used.add(candidate);
      continue;
    }
    final nextUnused = _firstUnusedGpId(allGpIds, used);
    if (nextUnused == null) {
      continue;
    }
    result.add(nextUnused);
    used.add(nextUnused);
  }
  return result.length == kNumSlots
      ? result
      : allGpIds.take(kNumSlots).toList();
}

String? _firstUnusedGpId(List<String> allGpIds, Set<String> used) {
  for (final id in allGpIds) {
    if (!used.contains(id)) {
      return id;
    }
  }
  return null;
}

class _GameSetupMenuButton extends StatelessWidget {
  const _GameSetupMenuButton({
    required this.label,
    required this.variant,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final GameSetupVariant variant;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CtNinePatchButton(
        onPressed: onPressed,
        enabled: enabled && onPressed != null,
        child: Text(label),
      ),
    );
  }
}

/// Action affordance region for Game Setup: Cancel + Start Game row plus the
/// "Back to Main Menu" link below (Refs #2868 S3 / R12–R14).
///
/// Splits behaviour by variant per `SPEC/ui/game-setup.md`:
///
/// - `pixelArt` mirrors the canonical action layout in
///   `SPEC/ui/mockups/SHEL20001-game-setup.html`: a single horizontal `Row`
///   placing the bespoke [_GameSetupCancelButton] on the left and the
///   `CtNinePatchButton`-backed Start Game on the right at equal flex, with
///   a `_GameSetupBackLink` (CtBackButton glyph + label) rendered beneath.
/// - `plain` preserves the pre-#2868 single-column stack: full-width Start
///   Game above a full-width Back button, both rendered via the existing
///   [_GameSetupMenuButton]. The dual back affordance (Cancel + Back link)
///   is gated to the `pixelArt` chrome per the SPEC AC block.
///
/// Both the Cancel button and the back-link region invoke [onBack]; the
/// SPEC pins this shared destination because the mockup wires both
/// `.cancel-btn` and the `.back-link` text to `handleCancel()`.
class _GameSetupActionsAndBackRegion extends StatelessWidget {
  const _GameSetupActionsAndBackRegion({
    required this.variant,
    required this.startEnabled,
    required this.onStart,
    required this.onBack,
  });

  final GameSetupVariant variant;
  final bool startEnabled;
  final VoidCallback? onStart;
  final VoidCallback onBack;

  /// Horizontal gap between Cancel and Start Game in the pixelArt action row.
  /// Matches `SPEC/ui/mockups/SHEL20001-game-setup.html` § `.actions`
  /// `gap:clamp(8px,1.5vw,12px)` normalised at 12 dp for the Flutter scale.
  static const double actionRowGap = 12;

  /// Vertical gap between the action row and the back-link region below.
  /// Mirrors the mockup's `.back-link` `margin-top:clamp(10px,2vh,16px)`
  /// normalised at the centre of that range.
  static const double actionRowToBackLinkGap = 12;

  /// Vertical gap between Start Game and Back in the plain-variant stack.
  /// Preserves the pre-#2868 spacing so existing plain-variant tests are
  /// unaffected by the pixelArt-only action-row introduction.
  static const double plainVariantStackGap = 12;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = appL10n(context);
    if (variant != GameSetupVariant.pixelArt) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _GameSetupMenuButton(
            label: l10n.gameSetup_startGame,
            variant: variant,
            enabled: startEnabled,
            onPressed: onStart,
          ),
          const SizedBox(height: plainVariantStackGap),
          _GameSetupMenuButton(
            label: l10n.gameSetup_back,
            variant: variant,
            enabled: true,
            onPressed: onBack,
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _GameSetupCancelButton(
                  label: l10n.gameSetup_cancel,
                  onPressed: onBack,
                ),
              ),
              const SizedBox(width: actionRowGap),
              Expanded(
                child: CtNinePatchButton(
                  onPressed: onStart,
                  enabled: startEnabled && onStart != null,
                  child: Text(l10n.gameSetup_startGame),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: actionRowToBackLinkGap),
        _GameSetupBackLink(
          label: l10n.gameSetup_backToMainMenu,
          onPressed: onBack,
        ),
      ],
    );
  }
}

/// Bespoke Cancel affordance for the Game Setup pixelArt action row
/// (Refs #2868 R12).
///
/// Painted as a tappable [Container] with the dark-theme "cancel-btn" surface
/// described in `SPEC/ui/mockups/SHEL20001-game-setup.html` § `.cancel-btn`:
/// a top-to-bottom gradient (`--surface` → `--bg-deep`), a 1 px
/// `EditorialMonoclePalette.border` outline on every side, a localized label
/// painted in `EditorialMonoclePalette.muted`, and a 48 dp minimum tap-target
/// height. Hover lifts the gradient (`--surface-lite` → `--surface`) and
/// recolours the label to `EditorialMonoclePalette.accentBright` per the
/// mockup's `.cancel-btn:hover` rule.
///
/// All colours resolve from [EditorialMonoclePalette] tokens; no hard-coded
/// hex literals. Reusing `CtNinePatchButton` is not appropriate here because
/// the Cancel chrome must visually subordinate to the Start Game primary
/// surface (no brass corner brackets, no engraved accent text); a bespoke
/// widget keeps the visual hierarchy from the mockup intact.
class _GameSetupCancelButton extends StatefulWidget {
  const _GameSetupCancelButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  /// Minimum tap-target height (Flutter `>= 44 dp` accessibility floor; the
  /// mockup `.setup-btn` rule pins `min-height:44px`, lifted here to 48 dp
  /// to match `CtNinePatchButton.minHeight` so the Cancel surface sits flush
  /// against Start Game in the action row).
  static const double minHeight = 48;

  /// 1 px neutral outline thickness mirroring the mockup's
  /// `.cancel-btn { border-top:1px solid var(--border); border-bottom:1px solid var(--border); }`
  /// rule. The bespoke widget paints all four sides for visual parity with
  /// the surrounding pixelArt slot-row chrome.
  static const double borderThickness = 1;

  /// Hover/press fade duration shared with `CtBackButton` and
  /// `CtNinePatchButton` so action-row hovers feel uniform.
  static const Duration animationDuration = Duration(milliseconds: 120);

  @override
  State<_GameSetupCancelButton> createState() => _GameSetupCancelButtonState();
}

class _GameSetupCancelButtonState extends State<_GameSetupCancelButton> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  LinearGradient get _surfaceGradient {
    if (_hovered) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          EditorialMonoclePalette.surfaceLite,
          EditorialMonoclePalette.surface,
        ],
      );
    }
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        EditorialMonoclePalette.surface,
        EditorialMonoclePalette.bgDeep,
      ],
    );
  }

  Color get _labelColor =>
      _hovered
          ? EditorialMonoclePalette.accentBright
          : EditorialMonoclePalette.muted;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle =
        theme.textTheme.titleSmall ??
        theme.textTheme.bodyLarge ??
        const TextStyle();
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: _GameSetupCancelButton.animationDuration,
            curve: Curves.easeOut,
            constraints: const BoxConstraints(
              minHeight: _GameSetupCancelButton.minHeight,
            ),
            decoration: BoxDecoration(
              gradient: _surfaceGradient,
              border: Border.all(
                color: EditorialMonoclePalette.border,
                width: _GameSetupCancelButton.borderThickness,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              key: const ValueKey<String>('gameSetupCancelLabel'),
              style: baseStyle.copyWith(color: _labelColor),
            ),
          ),
        ),
      ),
    );
  }
}

/// Back-link region rendered below the pixelArt action row (Refs #2868 R14).
///
/// Combines a [CtBackButton] glyph (28 × 28 dp tap target, 16 × 16 dp
/// chevron-left from `Refs #2859` R11) with a localized text label rendered
/// in `EditorialMonoclePalette.muted`. Tapping either the glyph or the text
/// invokes [onPressed] (which Game Setup wires to its `onBack` callback) so
/// the back link mirrors the mockup's `.back-link` affordance — the
/// secondary, non-button back affordance below the primary action row.
///
/// The widget is intentionally not gated on `enabled` because the SPEC AC
/// pins the back affordance as always tappable (including during the
/// `loading` state, where the action row is dimmed by the
/// `_GameSetupLoadingRegion` overlay and the back link sits outside that
/// region so it remains reachable per `SPEC/ui/game-setup.md` Loading AC).
class _GameSetupBackLink extends StatefulWidget {
  const _GameSetupBackLink({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  /// Horizontal gap between the [CtBackButton] glyph and the label text.
  /// Tuned to match the mockup's `.back-link` letter-spacing rhythm so the
  /// glyph reads as part of the link rather than a separate icon button.
  static const double glyphToLabelGap = 6;

  /// Hover fade duration shared with `CtBackButton` and the
  /// `_GameSetupCancelButton` so the back-link label hover feels uniform
  /// alongside the action-row affordances.
  static const Duration animationDuration = Duration(milliseconds: 120);

  @override
  State<_GameSetupBackLink> createState() => _GameSetupBackLinkState();
}

class _GameSetupBackLinkState extends State<_GameSetupBackLink> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle =
        theme.textTheme.labelLarge ??
        theme.textTheme.bodyMedium ??
        const TextStyle();
    final Color labelColor =
        _hovered
            ? EditorialMonoclePalette.accentBright
            : EditorialMonoclePalette.muted;
    return Center(
      child: MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        cursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CtBackButton(
              key: const ValueKey<String>('gameSetupBackLinkGlyph'),
              onPressed: widget.onPressed,
              semanticLabel: widget.label,
            ),
            const SizedBox(width: _GameSetupBackLink.glyphToLabelGap),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onPressed,
              child: AnimatedDefaultTextStyle(
                duration: _GameSetupBackLink.animationDuration,
                curve: Curves.easeOut,
                style: baseStyle.copyWith(color: labelColor),
                child: Text(
                  widget.label,
                  key: const ValueKey<String>('gameSetupBackLinkLabel'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dark editorial-monocle header chrome for Game Setup (Refs #2868 S1).
///
/// Renders, in pixelArt variant, the eyebrow ("NEW CAMPAIGN"), title
/// ("Game Setup") with accent colour + glow shadow, italic muted intro
/// line, and a [CtBrassDivider]. In plain variant, only the existing
/// theme-styled title renders; the eyebrow, intro and brass divider are
/// omitted per `SPEC/ui/game-setup.md` § Layout / wireframe (Variant
/// rendering — header chrome).
class _GameSetupHeader extends StatelessWidget {
  const _GameSetupHeader({required this.variant});

  final GameSetupVariant variant;

  /// Letter-spacing used by the eyebrow text per SPEC (0.22em).
  static const double _eyebrowLetterSpacingEm = 0.22;

  /// Vertical gap between the eyebrow and the title.
  static const double _eyebrowToTitleGap = 4;

  /// Vertical gap between the title and the intro line.
  static const double _titleToIntroGap = 8;

  /// Vertical gap between the intro line and the brass divider.
  static const double _introToDividerGap = 12;

  /// Title shadow offset; soft single-shadow glow drawn directly under
  /// the glyph (no offset) so it reads as a halo on the dark background.
  static const Offset _titleGlowOffset = Offset.zero;

  /// Title shadow blur radius; per `SPEC/ui/pixel-art-ui-catalog.md`
  /// § Editorial-monocle palette the glow is soft and short-range so the
  /// title still reads sharply against the scaffold background.
  static const double _titleGlowBlur = 6;

  /// Glow shadow alpha. Tuned conservatively so the accent-bright halo
  /// sits behind the title text without washing the surrounding chrome.
  static const double _titleGlowAlpha = 0.45;

  @override
  Widget build(BuildContext context) {
    if (variant == GameSetupVariant.pixelArt) {
      return const _GameSetupPixelArtHeader();
    }
    return Text(
      appL10n(context).gameSetup_title,
      key: const ValueKey<String>('gameSetupTitlePlain'),
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}

/// PixelArt-variant header body for [_GameSetupHeader]. Extracted to keep
/// each `build()` body below the repo lint ceiling
/// (`repo.disallowed_ast_patterns` → `widget_build_method_too_long`,
/// 60 physical lines) while preserving the SPEC-authorised header chrome.
class _GameSetupPixelArtHeader extends StatelessWidget {
  const _GameSetupPixelArtHeader();

  TextStyle _titleStyle(ThemeData theme) =>
      (theme.textTheme.headlineMedium ?? const TextStyle()).copyWith(
        color: EditorialMonoclePalette.accent,
        shadows: <Shadow>[
          Shadow(
            color: EditorialMonoclePalette.accentBright.withValues(
              alpha: _GameSetupHeader._titleGlowAlpha,
            ),
            offset: _GameSetupHeader._titleGlowOffset,
            blurRadius: _GameSetupHeader._titleGlowBlur,
          ),
        ],
      );

  TextStyle _eyebrowStyle(ThemeData theme) {
    final TextStyle? base = theme.textTheme.labelSmall;
    final double fontSize = base?.fontSize ?? 11;
    return (base ?? const TextStyle()).copyWith(
      color: EditorialMonoclePalette.muted,
      fontWeight: FontWeight.w500,
      letterSpacing: fontSize * _GameSetupHeader._eyebrowLetterSpacingEm,
    );
  }

  TextStyle _introStyle(ThemeData theme) =>
      (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
        color: EditorialMonoclePalette.muted,
        fontStyle: FontStyle.italic,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          l10n.gameSetup_eyebrow.toUpperCase(),
          key: const ValueKey<String>('gameSetupEyebrow'),
          style: _eyebrowStyle(theme),
        ),
        const SizedBox(height: _GameSetupHeader._eyebrowToTitleGap),
        Text(
          l10n.gameSetup_title,
          key: const ValueKey<String>('gameSetupTitlePixelArt'),
          style: _titleStyle(theme),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: _GameSetupHeader._titleToIntroGap),
        Text(
          l10n.gameSetup_intro,
          key: const ValueKey<String>('gameSetupIntro'),
          style: _introStyle(theme),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: _GameSetupHeader._introToDividerGap),
        const CtBrassDivider(key: ValueKey<String>('gameSetupBrassDivider')),
      ],
    );
  }
}

/// Loading-state dim/scrim overlay for the Game Setup header + slot rows.
///
/// Implements `Refs #2868` R15 — when [isLoading] is `true`, the underlying
/// [child] is wrapped in `Opacity(0.4)` + `IgnorePointer(ignoring: true)`,
/// a [`Positioned.fill`] scrim painted in
/// [EditorialMonoclePalette.dialogScrim] covers the dimmed region, and a
/// centered [`Column`] paints the loading affordance (a 48 px
/// [`CtLoadingIndicator`] above the localized [loadingLabel]) in front of
/// the scrim.
///
/// When [isLoading] is `false`, the widget renders exactly [child] (no
/// `Stack`, no scrim, no `IgnorePointer`), so the default state matches the
/// pre-#2868 S4 layout one-for-one and adds no test-visible chrome.
///
/// The overlay is scoped to the header + slot-rows region only; consumers
/// (see [`CtGameSetup.build`]) keep the Start Game and Back action buttons
/// outside this widget so the Back affordance remains visible, enabled,
/// and tappable during the loading state (per `SPEC/ui/game-setup.md`
/// "Loading" AC that Back remains enabled).
class _GameSetupLoadingRegion extends StatelessWidget {
  const _GameSetupLoadingRegion({
    required this.isLoading,
    required this.loadingLabel,
    required this.child,
  });

  final bool isLoading;
  final String loadingLabel;
  final Widget child;

  /// Dim opacity applied to the underlying content per #2868 R15
  /// ("dimmed content"). Matches the disabled-control opacity convention
  /// shared with `CtNinePatchButton`, `CtBackButton`, and the slot-row
  /// leader-dropdown disabled state (#2868 R10).
  static const double dimmedContentOpacity = 0.4;

  /// Spinner side length painted inside the overlay column.
  static const double spinnerSize = 48;

  /// Vertical gap between the spinner and the "Generating world…" label.
  static const double spinnerToLabelGap = 16;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child;
    }
    final ThemeData theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        IgnorePointer(
          ignoring: true,
          child: Opacity(opacity: dimmedContentOpacity, child: child),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: ColoredBox(color: EditorialMonoclePalette.dialogScrim),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CtLoadingIndicator(
              size: spinnerSize,
              strokeWidth: 2,
              color: EditorialMonoclePalette.accent,
              center: false,
            ),
            const SizedBox(height: spinnerToLabelGap),
            Text(
              loadingLabel,
              key: const ValueKey<String>('gameSetupLoadingLabel'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: EditorialMonoclePalette.fg,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }
}

/// Dark editorial-monocle slot-row chrome for [`CtGameSetup`] player slots.
///
/// Implements `Refs #2868` S2 / R7: each slot row paints
/// [CtGradients.rowGradient] as its surface, draws a 1.5 px brass top and
/// bottom border in `--accent-dim`, and paints 1.5 px brass edge strips on
/// the left and right inside that border. All colors resolve from
/// [EditorialMonoclePalette] tokens (issue #2858); no hard-coded hex.
///
/// The chrome only renders in the [GameSetupVariant.pixelArt] variant
/// (matching the S1 header chrome convention in PR #2887). In the
/// [GameSetupVariant.plain] variant the chrome falls back to a transparent
/// pass-through wrapper that preserves the previous spacing
/// ([rowVerticalGap] below each row) so the slot widget tree shape is
/// stable across variants for existing tests.
class _SlotRowChrome extends StatelessWidget {
  const _SlotRowChrome({required this.variant, required this.child});

  final GameSetupVariant variant;
  final Widget child;

  /// Brass border / edge-strip thickness per #2868 R7 (1.5 px).
  static const double brassStripThickness = 1.5;

  /// Inner horizontal padding clearing the 1.5 px edge strips so dropdown
  /// chrome inside the row never paints over them. Kept at zero so the
  /// dropdown surfaces meet the brass edge strips with no inset; the
  /// dropdowns supply their own internal padding.
  static const double rowHorizontalPadding = 0;

  /// Inner vertical padding clearing the brass top / bottom borders so
  /// dropdown chrome stays clear of them. Kept at zero so the slot row
  /// adds only the 1.5 px brass borders (≈ 3 px per row total) on top of
  /// the previous layout height, preserving widget-test viewport fit.
  static const double rowVerticalPadding = 0;

  /// Vertical gap between consecutive slot rows. Kept equal to the
  /// pre-S2 spacing so the page layout does not shift in existing tests.
  static const double rowVerticalGap = 12;

  /// Disabled leader-dropdown opacity per #2868 R10 ("0.4 opacity when no
  /// nation"). Defined here so [`CtGameSetup`] and tests share one source.
  static const double disabledLeaderOpacity = 0.4;

  @override
  Widget build(BuildContext context) {
    if (variant != GameSetupVariant.pixelArt) {
      return Padding(
        padding: const EdgeInsets.only(bottom: rowVerticalGap),
        child: child,
      );
    }
    final BorderSide brass = BorderSide(
      color: EditorialMonoclePalette.accentDim,
      width: brassStripThickness,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: rowVerticalGap),
      child: Container(
        decoration: BoxDecoration(
          gradient: CtGradients.rowGradient,
          border: Border(
            top: brass,
            bottom: brass,
            left: brass,
            right: brass,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: rowHorizontalPadding,
          vertical: rowVerticalPadding,
        ),
        child: child,
      ),
    );
  }
}
