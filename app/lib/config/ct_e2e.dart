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

// ignore: public_member_api_docs
/// Map controls: region chip for **New World** (narrow finder surface for e2e).
const Key kCtE2ERegionTabNewWorldKey = Key('ct_e2e_region_tab_new_world');

// ignore: public_member_api_docs
/// [MoveFleetDialog] scroll body root (destinations list) for e2e scroll-until-visible.
const Key kCtE2EMoveFleetDialogScrollRootKey = Key(
  'ct_e2e_move_fleet_dialog_scroll_root',
);

// ignore: public_member_api_docs
/// Stable locator for the fleet-row **Move** action button. The naval action
/// cluster collapses to icon-only at narrow (test-host) viewports, so the
/// rendered button carries no `Text('Move')`; e2e helpers must locate it by
/// this key rather than the conditionally-rendered label (Refs #2336 AC4 and
/// the deterministic-locator rule in `colonizethis-e2e-ui-stability.mdc`).
const Key kCtE2EFleetMoveActionKey = Key('ct_e2e_fleet_move_action');

// ignore: public_member_api_docs
/// Prefix for the per-destination-row keys inside [MoveFleetDialog]. The
/// production dialog renders custom destination rows (`_MoveFleetDestinationRow`,
/// a `CtDialogShell` body) rather than Material `RadioListTile`, so the
/// fleet-reach e2e helpers select the first available sea destination by this
/// key prefix (the warp destination is still located by its label text). The
/// zero-based row index is appended so sibling row keys stay unique
/// (Refs #2336; deterministic-locator rule in `colonizethis-e2e-ui-stability.mdc`).
const String kCtE2EMoveFleetDestinationRowKeyPrefix =
    'ct_e2e_move_fleet_destination_row_';

// ignore: public_member_api_docs
/// Builds the stable key for the destination row at [index] inside
/// [MoveFleetDialog] under [CT_E2E] (Refs #2336).
Key kCtE2EMoveFleetDestinationRowKey(int index) =>
    Key('$kCtE2EMoveFleetDestinationRowKeyPrefix$index');
