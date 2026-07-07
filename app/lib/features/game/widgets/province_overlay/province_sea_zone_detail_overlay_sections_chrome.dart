/// Section header chrome shared by province / sea-zone tab bodies.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
part of 'province_sea_zone_detail_overlay.dart';

class _OverlayContent {
  _OverlayContent({
    required this.tabLabels,
    required this.tabViews,
    required this.sections,
  });
  final List<String> tabLabels;
  final List<Widget> tabViews;
  final Widget sections;
}

// Section header band shared by every province / sea-zone tab body and the
// wide-layout `sections` column. Renders the canonical CtSectionLabel
// (Refs #2859 R9) so the title inherits the dark editorial-monocle
// small-caps + `--accent-dim` underline contract; see
// SPEC/ui/province-sea-zone-detail-overlay.md § Dark-theme section labels.
//
// When [title] is empty (e.g. the narrow-layout obfuscated tab body that
// already has its label rendered by `CtTabStrip`), the header band is
// omitted entirely so the obfuscated body does not paint an extra
// underline beneath the tab strip.
Widget _buildSection(String title, Widget child) {
  return Padding(
    padding: const EdgeInsets.only(bottom: CtSpacing.ml),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title.isNotEmpty) ...[
          CtSectionLabel(title),
          SizedBox(height: CtSpacing.m / 2),
        ],
        child,
      ],
    ),
  );
}

class _ObfuscatedSection extends StatelessWidget {
  const _ObfuscatedSection({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _buildSection('', _obfuscatedBodyText(l10n.provinceOverlay_unknown));
  }
}
