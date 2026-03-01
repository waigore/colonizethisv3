import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

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

/// Asset path for pixel-art variant (reuse main menu). SPEC/ui/game-setup.md.
const String _kAssetButton = 'assets/images/ui_main_menu_button.png';

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

  final GameSetupVariant variant;
  final GameSetupState state;
  final ResolvedNamingConfig naming;
  final List<String> initialOrderedGpIds;
  final Map<String, String> initialLeaderVariantByGpId;
  final void Function(List<String> orderedGpIdsForSlots, Map<String, String> leaderVariantByGpId) onStartGame;
  final VoidCallback onBack;

  @override
  State<CtGameSetup> createState() => _CtGameSetupState();
}

class _CtGameSetupState extends State<CtGameSetup> {
  late List<String> _orderedGpIdsBySlot;
  late Map<String, String> _leaderVariantByGpId;

  List<String> get _allGpIds => widget.naming.greatPowers.map((g) => g.id).toList();

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
    _leaderVariantByGpId = Map<String, String>.from(widget.initialLeaderVariantByGpId);
  }

  @override
  void didUpdateWidget(covariant CtGameSetup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialOrderedGpIds != widget.initialOrderedGpIds ||
        oldWidget.initialLeaderVariantByGpId != widget.initialLeaderVariantByGpId) {
      final all = widget.naming.greatPowers.map((g) => g.id).toList();
      _orderedGpIdsBySlot = List<String>.from(widget.initialOrderedGpIds);
      if (_orderedGpIdsBySlot.length != _kNumSlots) {
        _orderedGpIdsBySlot = _padOrTrimToSlots(_orderedGpIdsBySlot, all);
      } else if (_orderedGpIdsBySlot.every((id) => id.isEmpty)) {
        _orderedGpIdsBySlot = List.filled(_kNumSlots, '');
      }
      _leaderVariantByGpId = Map<String, String>.from(widget.initialLeaderVariantByGpId);
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
                    Text(
                      'Game Setup',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    _buildSlots(context),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Starting…',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    _GameSetupMenuButton(
                      label: 'Start Game',
                      variant: widget.variant,
                      enabled: _startEnabled,
                      onPressed: _startEnabled ? _onStartGame : null,
                    ),
                    const SizedBox(height: 12),
                    _GameSetupMenuButton(
                      label: 'Back',
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

  Widget _buildSlots(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < _kNumSlots; i++) {
      final label = i == 0 ? 'Player 1 (You)' : 'Player ${i + 1} (AI)';
      rows.add(_buildSlotRow(context, i, label));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  Widget _buildSlotRow(BuildContext context, int slotIndex, String slotLabel) {
    final gpId = _orderedGpIdsBySlot[slotIndex];
    final gp = gpId.isEmpty ? null : widget.naming.gpById(gpId);
    final availableGpIds = _availableGpIdsForSlot(slotIndex);
    final variants = gp?.leaderVariants ?? <LeaderVariant>[];
    final currentVariantId = gp != null
        ? (_leaderVariantByGpId[gpId] ?? gp.defaultLeaderVariantId)
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              slotLabel,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: slotIndex == 0 ? FontWeight.w600 : null,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: DropdownButton<String>(
              value: availableGpIds.contains(gpId) ? gpId : (availableGpIds.isNotEmpty ? availableGpIds.first : null),
              isExpanded: true,
              items: [
                for (final id in availableGpIds)
                  DropdownMenuItem(
                    value: id,
                    child: Text(
                      id.isEmpty ? 'Select nation' : (widget.naming.gpById(id)?.countryName ?? id),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _isLoading
                  ? null
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
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: gpId.isEmpty
                ? DropdownButton<String>(
                    value: '',
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Select leader')),
                    ],
                    onChanged: null,
                  )
                : DropdownButton<String>(
                    value: variants.any((v) => v.id == currentVariantId) ? currentVariantId : (variants.isNotEmpty ? variants.first.id : null),
                    isExpanded: true,
                    items: [
                      for (final v in variants)
                        DropdownMenuItem(
                          value: v.id,
                          child: Text(v.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _leaderVariantByGpId[gpId] = value);
                            }
                          },
                  ),
          ),
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
    if (i < list.length && list[i].isNotEmpty && !used.contains(list[i])) {
      result.add(list[i]);
      used.add(list[i]);
    } else {
      for (final id in allGpIds) {
        if (!used.contains(id)) {
          result.add(id);
          used.add(id);
          break;
        }
      }
    }
  }
  return result.length == kNumSlots ? result : allGpIds.take(kNumSlots).toList();
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
    if (variant == GameSetupVariant.pixelArt) {
      return _GameSetupPixelArtButton(
        label: label,
        enabled: enabled,
        onPressed: onPressed,
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _GameSetupPixelArtButton extends StatelessWidget {
  const _GameSetupPixelArtButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                _kAssetButton,
                centerSlice: const Rect.fromLTWH(24, 18, 75, 21),
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) {
                  Logger().w('ctdev: game_setup button asset not found, using fallback');
                  return Container(color: const Color(0xFF5D3A1A));
                },
              ),
              Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: enabled ? const Color(0xFFF5F5DC) : Colors.grey,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
