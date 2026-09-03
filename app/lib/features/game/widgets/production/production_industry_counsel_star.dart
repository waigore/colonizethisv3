import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

/// Single recommendation star on a Production allocation row.
class ProductionIndustryCounselStar extends StatelessWidget {
  const ProductionIndustryCounselStar({
    super.key,
    required this.recipeId,
    required this.briefMessage,
    required this.semanticLabel,
    required this.onOpenCounsel,
  });

  final String recipeId;

  final String briefMessage;
  final String semanticLabel;
  final VoidCallback onOpenCounsel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Tooltip(
        message: briefMessage,
        child: InkWell(
          key: ValueKey<String>('production_industry_counsel_star_$recipeId'),
          onTap: onOpenCounsel,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              '★',
              style: TextStyle(
                fontSize: 14,
                height: 1,
                color: EditorialMonoclePalette.accentBright,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
