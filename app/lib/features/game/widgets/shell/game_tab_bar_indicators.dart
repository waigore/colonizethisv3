import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../config/app_assets.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/strict_asset_icon.dart';
import '../../screens/game/game_screen_shared.dart'
    show kCargoHoldIndicatorKey, kLabourFeedingIndicatorKey;

class GameTabBarTreasuryIndicator extends StatelessWidget {
  const GameTabBarTreasuryIndicator({
    super.key,
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

class GameTabBarCargoHoldIndicator extends StatelessWidget {
  const GameTabBarCargoHoldIndicator({
    super.key,
    required this.cargoHoldLabel,
    required this.labelStyle,
    required this.numericColor,
    this.tooltip,
    this.semanticsLabel,
    this.onTap,
  });

  final String cargoHoldLabel;
  final TextStyle labelStyle;
  final Color numericColor;
  final String? tooltip;
  final String? semanticsLabel;
  final VoidCallback? onTap;

  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final Widget indicator = Container(
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
          Text(
            cargoHoldLabel,
            style: labelStyle.copyWith(color: numericColor),
          ),
        ],
      ),
    );

    Widget wrapped = indicator;
    if (onTap != null) {
      wrapped = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: wrapped,
      );
    }
    if (tooltip != null) {
      wrapped = Tooltip(message: tooltip, child: wrapped);
    }
    if (semanticsLabel != null) {
      wrapped = Semantics(
        button: onTap != null,
        label: semanticsLabel,
        child: wrapped,
      );
    }
    return wrapped;
  }
}

class GameTabBarLabourFeedingIndicator extends StatelessWidget {
  const GameTabBarLabourFeedingIndicator({
    super.key,
    required this.labourFeedingLabel,
    required this.labelStyle,
    required this.numericColor,
    this.tooltip,
    this.semanticsLabel,
    this.onTap,
  });

  final String labourFeedingLabel;
  final TextStyle labelStyle;
  final Color numericColor;
  final String? tooltip;
  final String? semanticsLabel;
  final VoidCallback? onTap;

  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final Widget indicator = Container(
      key: kLabourFeedingIndicatorKey,
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
            assetPath: '${kAppIconAssetPrefix}ui_icon_worker_peasant.png',
            width: _iconSize,
            height: _iconSize,
          ),
          const SizedBox(width: 4),
          Text(
            labourFeedingLabel,
            style: labelStyle.copyWith(color: numericColor),
          ),
        ],
      ),
    );

    Widget wrapped = indicator;
    if (onTap != null) {
      wrapped = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: wrapped,
      );
    }
    if (tooltip != null) {
      wrapped = Tooltip(message: tooltip, child: wrapped);
    }
    if (semanticsLabel != null) {
      wrapped = Semantics(
        button: onTap != null,
        label: semanticsLabel,
        child: wrapped,
      );
    }
    return wrapped;
  }
}
