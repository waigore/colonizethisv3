import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/ct_nine_patch_button.dart';
import '../../screens/game/game_screen_shared.dart'
    show kGameMapNextTurnButtonKey, kNextTurnDisabledOpacity;
import 'game_top_bar.dart';
import 'game_top_bar_hamburger.dart';
import 'game_top_bar_pause_button.dart';

extension GameTopBarLayout on GameTopBar {
  Widget buildObserveBanner(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle observeStyle =
        (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
          color: EditorialMonoclePalette.muted,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        );
    return Text(
      observeBannerLabel!,
      key: GameTopBar.observeBannerKey,
      style: observeStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget buildTurnDisplay(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle turnStyle =
        (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
          color: EditorialMonoclePalette.fg,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.04 * 13,
        );
    return Text(
      turnDisplayText,
      key: GameTopBar.turnDisplayKey,
      style: turnStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }

  Widget buildNextTurnButton({required bool compactHorizontalPadding}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: GameTopBar.nextTurnMinHeight,
        maxHeight: GameTopBar.nextTurnMinHeight,
      ),
      child: CtNinePatchButton(
        key: kGameMapNextTurnButtonKey,
        enabled: nextTurnEnabled,
        onPressed: nextTurnEnabled ? () => onNextTurn() : null,
        disabledOpacityOverride: kNextTurnDisabledOpacity,
        minHeight: GameTopBar.nextTurnMinHeight,
        padding: EdgeInsets.symmetric(
          horizontal: compactHorizontalPadding ? 8 : 12,
          vertical: 4,
        ),
        child: Text(
          nextTurnText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  List<Widget> buildNarrowRowChildren({required bool isMinViewport}) {
    return <Widget>[
      GameTopBarHamburger(onPressed: onToggleSideMenu, tooltip: menuTooltip),
      const SizedBox(width: GameTopBar.leadingGap),
      GameTopBarPauseButton(onPressed: onPausePressed, tooltip: pauseTooltip),
      SizedBox(width: GameTopBar.trailingGap),
      Expanded(
        child: Align(
          alignment: Alignment.centerRight,
          child: buildNextTurnButton(compactHorizontalPadding: isMinViewport),
        ),
      ),
    ];
  }

  List<Widget> buildWideRowChildren(BuildContext context) {
    return <Widget>[
      GameTopBarHamburger(onPressed: onToggleSideMenu, tooltip: menuTooltip),
      const SizedBox(width: GameTopBar.leadingGap),
      if (observeBannerLabel != null) ...<Widget>[
        buildObserveBanner(context),
        const SizedBox(width: GameTopBar.leadingGap),
      ],
      Expanded(child: Center(child: buildTurnDisplay(context))),
      const SizedBox(width: GameTopBar.trailingGap),
      GameTopBarPauseButton(onPressed: onPausePressed, tooltip: pauseTooltip),
      const SizedBox(width: GameTopBar.trailingGap),
      buildNextTurnButton(compactHorizontalPadding: false),
    ];
  }
}
