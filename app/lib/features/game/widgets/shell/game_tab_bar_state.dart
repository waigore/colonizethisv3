part of 'game_tab_bar.dart';

class _GameTabBarState extends State<GameTabBar> {
  static final NumberFormat _exactTreasuryFormat =
      NumberFormat.decimalPattern();
  static final NumberFormat _abbrevTreasuryFormat = NumberFormat.compact(
    locale: 'en_US',
  );
  bool _showExactTreasury = true;

  String _formatTreasury(int value) {
    if (_showExactTreasury) {
      return _exactTreasuryFormat.format(value);
    }
    final compactRaw = _abbrevTreasuryFormat.format(value);
    final compact = compactRaw.replaceAll('K', 'k');
    if (compact.contains('.') || !compact.endsWith('k')) {
      return compact;
    }
    return compact.replaceFirst('k', '.0k');
  }

  Color? _treasuryDeltaColor(int? delta) {
    if (delta == null || delta == 0) {
      return null;
    }
    return delta > 0
        ? EditorialMonoclePalette.success
        : EditorialMonoclePalette.danger;
  }

  String? _treasuryDeltaLabel(int? delta) {
    if (delta == null || delta == 0) {
      return null;
    }
    if (delta > 0) {
      return '+$delta';
    }
    return '$delta';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle monoBody = (theme.textTheme.bodySmall ?? const TextStyle())
        .copyWith(
          fontFamily: 'monospace',
          fontSize: 11,
          height: 1.0,
        );
    final treasuryLabel = widget.treasuryNotDefined
        ? (widget.treasuryObserveLabel ?? '—')
        : _formatTreasury(widget.treasury);
    final deltaLabel = widget.treasuryNotDefined
        ? null
        : _treasuryDeltaLabel(widget.treasuryDelta);
    final deltaColor =
        _treasuryDeltaColor(deltaLabel == null ? null : widget.treasuryDelta);

    return SizedBox(
      key: GameTabBar.surfaceKey,
      height: GameTabBar.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorialMonoclePalette.surface,
          border: Border(
            bottom: BorderSide(
              color: EditorialMonoclePalette.border,
              width: GameTabBar.borderWidth,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GameTabBar.horizontalPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Region tabs are start-aligned (left in LTR); the scroll view
              // lets them shrink on narrow viewports without overflowing
              // (mockup `.region-tab` group, issue #2861 M1).
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _GameRegionTab(
                        label: widget.oldWorldLabel,
                        selected: widget.regionIndex == 0,
                        onTap: () => widget.onRegionIndexChanged(0),
                      ),
                      const SizedBox(width: GameTabBar.regionTabGap),
                      if (kCtE2EEnabled)
                        KeyedSubtree(
                          key: kCtE2ERegionTabNewWorldKey,
                          child: _GameRegionTab(
                            label: widget.newWorldLabel,
                            selected: widget.regionIndex == 1,
                            onTap: () => widget.onRegionIndexChanged(1),
                          ),
                        )
                      else
                        _GameRegionTab(
                          label: widget.newWorldLabel,
                          selected: widget.regionIndex == 1,
                          onTap: () => widget.onRegionIndexChanged(1),
                        ),
                    ],
                  ),
                ),
              ),
              // Trailing indicator group, end-aligned in mockup order:
              // treasury -> cargo -> news toggle (mockup `.tabbar-spacer`
              // separates the tabs from this group; issue #2861 M1).
              GestureDetector(
                key: kTreasuryIndicatorKey,
                onTap: widget.treasuryNotDefined
                    ? null
                    : () => setState(
                          () => _showExactTreasury = !_showExactTreasury,
                        ),
                child: _TreasuryIndicator(
                  treasuryLabel: treasuryLabel,
                  deltaLabel: deltaLabel,
                  deltaColor: deltaColor,
                  labelStyle: monoBody.copyWith(
                    color: EditorialMonoclePalette.accentDim,
                  ),
                  deltaStyle: monoBody.copyWith(
                    fontSize: 10,
                    color: deltaColor,
                  ),
                ),
              ),
              _CargoHoldIndicator(
                cargoHoldLabel: widget.cargoHoldLabel,
                labelStyle: monoBody.copyWith(
                  color: EditorialMonoclePalette.muted,
                ),
              ),
              const SizedBox(width: GameTabBar.clusterTrailingGap),
              widget.trailing,
            ],
          ),
        ),
      ),
    );
  }
}
