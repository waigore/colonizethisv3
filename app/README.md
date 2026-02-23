# Colonize This — App

Flutter app shell for the turn-based strategy game.

## Widget catalog

The **widget catalog** lives at `app/widget_catalog.json`. It uses the UXD 07 schema (per UXD 07 UI Mockup Pipeline): each entry has `id`, `name` (Ct-prefixed), `dart_file_path`, `constructor_props`, `category` (atom | molecule | screen), `source` (gdd12 | pipeline), and optional `widgetbook_story_path`. Update the catalog when adding or changing catalog widgets so components remain discoverable and reusable.
