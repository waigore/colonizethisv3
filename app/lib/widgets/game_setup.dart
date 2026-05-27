import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/editorial_monocle_palette.dart';
import '../config/ui_screen_ids.dart';
import '../l10n/l10n.dart';
import 'ct_brass_divider.dart';
import 'ct_dropdown.dart';
import 'ct_loading_indicator.dart';
import 'ct_nine_patch_button.dart';

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
                    _GameSetupHeader(variant: widget.variant),
                    const SizedBox(height: 24),
                    _buildSlots(context, narrow: narrow),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CtLoadingIndicator(
                              size: 20,
                              strokeWidth: 2,
                              center: false,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.gameSetup_starting,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    _GameSetupMenuButton(
                      label: l10n.gameSetup_startGame,
                      variant: widget.variant,
                      enabled: _startEnabled,
                      onPressed: _startEnabled ? _onStartGame : null,
                    ),
                    const SizedBox(height: 12),
                    _GameSetupMenuButton(
                      label: l10n.gameSetup_back,
                      variant: widget.variant,
                      enabled: true,
                      onPressed: widget.onBack,
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
        ? CtDropdown<String>(
            value: '',
            items: const [''],
            hint: l10n.gameSetup_selectLeader,
            itemLabel: (_) => l10n.gameSetup_selectLeader,
            onChanged: (_) {},
          )
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

    if (narrow) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            labelWidget,
            const SizedBox(height: 4),
            nationDropdown,
            const SizedBox(height: 4),
            leaderDropdown,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 100, child: labelWidget),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: nationDropdown),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: leaderDropdown),
        ],
      ),
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
