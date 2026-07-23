part of 'game_tab_bar.dart';

class _TreasuryIndicator extends StatelessWidget {
  const _TreasuryIndicator({
    required this.treasuryLabel,
    required this.deltaLabel,
    required this.deltaColor,
    required this.labelStyle,
    required this.deltaStyle,
  });

  final String treasuryLabel;
  final String? deltaLabel;
  final Color? deltaColor;
  final TextStyle labelStyle;
  final TextStyle deltaStyle;

  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CtSpacing.m),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StrictAssetIcon(
            assetPath: '${kAppIconAssetPrefix}ui_icon_treasury_coin.png',
            width: _iconSize,
            height: _iconSize,
          ),
          const SizedBox(width: 4),
          Text(treasuryLabel, style: labelStyle),
          if (deltaLabel != null) ...[
            const SizedBox(width: 4),
            Text(deltaLabel!, style: deltaStyle),
          ],
        ],
      ),
    );
  }
}

class _CargoHoldIndicator extends StatelessWidget {
  const _CargoHoldIndicator({
    required this.cargoHoldLabel,
    required this.labelStyle,
  });

  final String cargoHoldLabel;
  final TextStyle labelStyle;

  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: kCargoHoldIndicatorKey,
      padding: const EdgeInsets.symmetric(horizontal: CtSpacing.m),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: EditorialMonoclePalette.border,
            width: 1,
          ),
        ),
      ),
      margin: const EdgeInsets.only(left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StrictAssetIcon(
            assetPath: '${kAppIconAssetPrefix}ui_icon_cargo_hold.png',
            width: _iconSize,
            height: _iconSize,
          ),
          const SizedBox(width: 4),
          Text(cargoHoldLabel, style: labelStyle),
        ],
      ),
    );
  }
}
