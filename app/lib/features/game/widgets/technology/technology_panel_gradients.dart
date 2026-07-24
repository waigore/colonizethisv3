import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

// Vertical `--bg-deep` → `--surface` gradient shared by the researched
// tech chip body and the slot card chrome. Mirrors the mockup
// `linear-gradient(180deg,var(--bg-deep),var(--surface))` and is the
// single source so future palette tweaks stay aligned across both
// surfaces (SPEC/ui/technology-panel.md § Layout / wireframe + mockup
// `.tech-chip` and `.slot-card`). Refs #2864 S2/S3.
LinearGradient technologyDarkSurfaceGradient() {
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      EditorialMonoclePalette.bgDeep,
      EditorialMonoclePalette.surface,
    ],
  );
}
