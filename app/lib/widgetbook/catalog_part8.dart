// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
part of 'catalog.dart';

/// Refs #2914 §S8 — preview the [CtIconAction] primitive that replaces the
/// banned Material `IconButton` chrome across the in-game feature tree.
/// Renders the three families of call sites (locate, build improvement,
/// menu) so a reviewer can hover/tap each and see the idle / hover /
/// pressed / disabled colour transitions wired through
/// [EditorialMonoclePalette].
///
/// Lives in its own part fragment (not catalog_part5.dart) so the editorial
/// monocle primitives part stays under the 1000-line `repo.part_unit_size`
/// cap that the repo lint enforces.
class _CtIconActionStory extends StatefulWidget {
  const _CtIconActionStory();

  @override
  State<_CtIconActionStory> createState() => _CtIconActionStoryState();
}

class _CtIconActionStoryState extends State<_CtIconActionStory> {
  int _locateTaps = 0;
  int _buildTaps = 0;
  int _menuTaps = 0;

  @override
  Widget build(BuildContext context) {
    return _CtDarkPrimitiveScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Locate (tooltip + default 18 dp glyph)',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              CtIconAction(
                icon: Icons.my_location,
                // ignore: avoid_hardcoded_strings_in_widgets
                tooltip: 'Locate',
                onPressed: () => setState(() => _locateTaps++),
              ),
              const SizedBox(width: 12),
              const CtIconAction(
                icon: Icons.my_location,
                // ignore: avoid_hardcoded_strings_in_widgets
                tooltip: 'Locate (disabled)',
                onPressed: null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Build / explore / prospect (province overlay tile actions)',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              CtIconAction(
                icon: Icons.handyman,
                // ignore: avoid_hardcoded_strings_in_widgets
                tooltip: 'Build improvement',
                onPressed: () => setState(() => _buildTaps++),
              ),
              const SizedBox(width: 12),
              CtIconAction(
                icon: Icons.explore,
                // ignore: avoid_hardcoded_strings_in_widgets
                tooltip: 'Explore with explorer',
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              CtIconAction(
                icon: Icons.travel_explore,
                // ignore: avoid_hardcoded_strings_in_widgets
                tooltip: 'Prospect with explorer',
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              CtIconAction(
                icon: Icons.handyman,
                enabled: false,
                // ignore: avoid_hardcoded_strings_in_widgets
                tooltip: 'Build improvement (disabled)',
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Menu (game screen top-left, 24 dp glyph)',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          CtIconAction(
            icon: Icons.menu,
            iconSize: 24,
            // ignore: avoid_hardcoded_strings_in_widgets
            tooltip: 'Pause menu',
            onPressed: () => setState(() => _menuTaps++),
          ),
          const SizedBox(height: 16),
          Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'taps — locate: $_locateTaps · build: $_buildTaps · '
            'menu: $_menuTaps',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
