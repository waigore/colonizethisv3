// Per–Great-Power chip widget for [GameMapPlayersBar].
//
// De-parted wave-9 cluster (Refs #4117).

import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

class GameMapPlayersBarChip extends StatelessWidget {
  const GameMapPlayersBarChip({
    super.key,
    required this.name,
    required this.score,
    required this.swatchColor,
    required this.minWidth,
    required this.nameStyle,
    required this.scoreStyle,
  });

  final String name;
  final String score;
  final Color swatchColor;
  final double minWidth;
  final TextStyle nameStyle;
  final TextStyle scoreStyle;

  @override
  Widget build(BuildContext context) {
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
        border: Border.all(
          color: EditorialMonoclePalette.border,
          width: 1,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: swatchColor,
                  border: Border.all(
                    color: EditorialMonoclePalette.border,
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  name,
                  style: nameStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                score,
                style: scoreStyle,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
