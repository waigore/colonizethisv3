// Full-screen World Market Trade screen. SPEC/ui/trade-screen.md.
//
// **Scope of this slice (Refs #2993 E1+E2+E3 scaffolding):** route + screen
// ID + dark editorial-monocle chrome + observe-mode guard + placeholder body.
// The interactive Market and Deal Book tabs, including data binding to the
// `WorldMarketState` / `TradeOrder` types from #2989, are intentionally
// deferred to follow-up slices (`#2993` E4+ once the data API lands).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../widgets/ct_panel.dart';
import '../../../widgets/ct_top_bar.dart';
import '../../../widgets/strict_asset_icon.dart';
import '../shell_player_context.dart';
import '../widgets/observe_mode_not_defined_panel.dart';

/// Full-screen World Market trade screen.
///
/// Dark editorial-monocle chrome per `SPEC/ui/trade-screen.md` § Top bar: a
/// `CtTopBar` carrying the `Map` back affordance, the 18 × 18 pixel-art
/// trade icon, and the literal title `Trade`. The body is a scaffold
/// placeholder until the World Market core data types land via #2989; once
/// available the body switches to the Market tab + Deal Book tab layout
/// described in `SPEC/ui/trade-screen.md` § Layout / wireframe.
class TradeScreen extends ConsumerWidget {
  const TradeScreen({super.key, required this.game, required this.player});

  /// SPEC/ui/trade-screen.md — [UiScreenIds.tradeScreen].
  static const screenId = UiScreenIds.tradeScreen;

  /// Localized back-button label rendered immediately after the chevron on
  /// the dark-theme `CtTopBar`. SPEC requires the literal `"Map"` so the
  /// affordance reads `"← Map"`.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarBackLabel = 'Map';

  /// Title text shown in the dark-theme `CtTopBar`. SPEC mandates the
  /// literal `"Trade"` (Cinzel display font is configured at the theme
  /// level).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarTitle = 'Trade';

  /// Pixel-art icon asset rendered between the back affordance and the
  /// title (SPEC § Top bar — 18 × 18 px trade icon).
  static const String topBarIconAsset =
      '${kAppIconAssetPrefix}ui_icon_trade.png';

  /// Stable widget key for the trade top bar — lets widget tests pin the
  /// dark-theme chrome without coupling to localized strings.
  static const Key topBarKey = ValueKey<String>('tradeScreenTopBar');

  /// Stable widget key for the scaffold placeholder body. The interactive
  /// Market / Deal Book tabs (E4–E6) will replace this widget in follow-up
  /// slices; the key remains useful for E2/E3 scaffolding tests that verify
  /// the screen mounts correctly under the route.
  static const Key placeholderBodyKey =
      ValueKey<String>('tradeScreenScaffoldPlaceholder');

  final Game game;
  final Player player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CtGameFeatureScreenShell(
      game: game,
      topBar: const CtTopBar(
        key: topBarKey,
        title: topBarTitle,
        backButtonLabel: topBarBackLabel,
        icon: StrictAssetIcon(
          assetPath: topBarIconAsset,
          width: 18,
          height: 18,
        ),
      ),
      bodyBuilder: (context, shellRef, displayGame) {
        if (shellPanelsNotDefined(shellRef)) {
          // ignore: avoid_hardcoded_strings_in_widgets
          return const ObserveModeNotDefinedPanel(title: 'Trade');
        }
        return const _TradeScreenScaffoldPlaceholder(
          key: placeholderBodyKey,
        );
      },
    );
  }
}

/// Dark editorial-monocle placeholder body rendered before the Market /
/// Deal Book tabs land (`#2993` E4+). Mirrors the pattern used by other
/// draft surfaces (see `SPEC/ui/observe-mode.md` § Sentinel panel): a
/// single `CtPanel` carrying the screen title and a muted explanatory
/// line referencing the parent issue.
class _TradeScreenScaffoldPlaceholder extends StatelessWidget {
  const _TradeScreenScaffoldPlaceholder({super.key});

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String _titleText = 'World Market';

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String _bodyText =
      'The trade screen is under construction. The full Market and Deal '
      'Book tabs land alongside the World Market data types (Refs #2989, '
      '#2993).';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle titleStyle =
        (theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16))
            .copyWith(color: EditorialMonoclePalette.accent);
    final TextStyle bodyStyle =
        (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14))
            .copyWith(color: EditorialMonoclePalette.muted);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: CtPanel(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_titleText, style: titleStyle),
            const SizedBox(height: 12),
            Text(_bodyText, style: bodyStyle),
          ],
        ),
      ),
    );
  }
}
