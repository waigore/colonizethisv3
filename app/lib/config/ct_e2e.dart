import 'package:flutter/material.dart';

/// Compile-time flag for integration / e2e builds only.
/// Pass `--dart-define=CT_E2E=true` when running `flutter test integration_test/ …`.
/// **SPEC:** `SPEC/program/e2e-integration-tests.md`.
const bool kCtE2EEnabled = bool.fromEnvironment('CT_E2E', defaultValue: false);

// ignore: public_member_api_docs — keys are documented in SPEC/program/e2e-integration-tests.md
/// Opens province detail for the human capital tile (same as a map tap) without Flame hit-testing.
const Key kCtE2EOpenCapitalProvinceDetailKey = Key(
  'ct_e2e_open_capital_province_detail',
);

// ignore: public_member_api_docs
/// Root of the wide-layout province side panel subtree (for collecting [Text] in tree order).
const Key kCtE2EProvincePanelRootKey = Key('ct_e2e_province_panel_root');

// ignore: public_member_api_docs
/// Root of the civilian units bottom sheet subtree for e2e [Text] collection.
const Key kCtE2ECivilianPanelRootKey = Key('ct_e2e_civilian_panel_root');

// ignore: public_member_api_docs
/// Root of the naval units bottom sheet subtree for e2e [Text] collection.
const Key kCtE2ENavalPanelRootKey = Key('ct_e2e_naval_panel_root');

// ignore: public_member_api_docs
/// Root of the production screen panel subtree for e2e [Text] collection.
const Key kCtE2EProductionPanelRootKey = Key('ct_e2e_production_panel_root');

// ignore: public_member_api_docs
/// Under [CT_E2E], assigns the lexicographically first valid work-target tile (assign mode).
const Key kCtE2ESelectFirstValidWorkTileKey = Key(
  'ct_e2e_select_first_valid_work_tile',
);

// ignore: public_member_api_docs
/// Under [CT_E2E], opens tile-scoped civilian panel for first marker (sorted by tile key).
const Key kCtE2EOpenFirstCivilianMarkerPanelKey = Key(
  'ct_e2e_open_first_civilian_marker_panel',
);

// ignore: public_member_api_docs
/// Under [CT_E2E], opens tile-scoped naval panel for first fleet marker (sorted by tile key).
const Key kCtE2EOpenFirstFleetMarkerPanelKey = Key(
  'ct_e2e_open_first_fleet_marker_panel',
);
