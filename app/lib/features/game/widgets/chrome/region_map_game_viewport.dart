import 'package:colonizethis_app/features/game/flame/ct_region_map_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Embeds [CtRegionMapGame] in the widget tree so `lib/widgets/` stays free of
/// direct `package:flame` imports.
class RegionMapGameViewport extends StatelessWidget {
  const RegionMapGameViewport({super.key, required this.game});

  final CtRegionMapGame game;

  @override
  Widget build(BuildContext context) {
    return ClipRect(child: GameWidget<CtRegionMapGame>(game: game));
  }
}
