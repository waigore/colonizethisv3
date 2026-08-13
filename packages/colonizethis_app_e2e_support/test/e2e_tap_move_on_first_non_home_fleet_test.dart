/// Pins the widget-tree contract of [e2eTapMoveOnFirstNonHomeFleet]
/// (`app/integration_test/e2e_test_shared_panels.dart`).
///
/// The fleet-reach loop calls this helper through `_tryNavalMoveSegment`
/// (`new_game_fleet_reaches_new_world_e2e_helpers.dart`) up to
/// `_kMaxNextTurnTapsForNwFleetReach (35)` times per scenario. A silent
/// rename / fail-open here would stall the loop at the 35-turn cap × the
/// per-iteration `Move dialog` wait — Bottleneck 4 in
/// `SPEC/program/e2e-integration-tests.md` § Determinism — and a regression
/// that dropped the New World preference would similarly inflate the
/// wall-clock budget by tapping Move on the wrong (Old World) fleet first.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 4.
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'support/naval_fleet_move_harness.dart';

void main() {
  suppressLogsForTests();

  group('e2eTapMoveOnFirstNonHomeFleet — false / no-tap branches', () {
    testWidgets('no naval panel root key in tree -> false', (tester) async {
      await tester.pumpWidget(wrapNavalScrollBody(const SizedBox.shrink()));
      expect(await e2eTapMoveOnFirstNonHomeFleet(tester), isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('panel mounted but no ExpansionTile -> false (post-poll)', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapNavalScrollBody(navalPanelRoot(children: const [Text('loading')])),
      );
      expect(await e2eTapMoveOnFirstNonHomeFleet(tester), isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('single tile is the home fleet -> false (no tap)', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        wrapNavalScrollBody(
          navalPanelRoot(
            children: [
              ExpansionTile(
                title: const Text('Home Fleet'),
                initiallyExpanded: true,
                children: [
                  FleetMoveButton(
                    buttonKey: kCtE2EFleetMoveActionKey,
                    onPressedSpy: () => taps++,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      expect(await e2eTapMoveOnFirstNonHomeFleet(tester), isFalse);
      expect(taps, 0);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('only tiles without "Fleet " title prefix -> false', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        wrapNavalScrollBody(
          navalPanelRoot(
            children: [
              ExpansionTile(
                title: const Text('Flotilla 7'),
                subtitle: const Text('New World — Outer Sea'),
                initiallyExpanded: true,
                children: [
                  FleetMoveButton(
                    buttonKey: kCtE2EFleetMoveActionKey,
                    onPressedSpy: () => taps++,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      expect(await e2eTapMoveOnFirstNonHomeFleet(tester), isFalse);
      expect(taps, 0);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('e2eTapMoveOnFirstNonHomeFleet — true / tap branches', () {
    testWidgets(
      'single non-home fleet with NW subtitle -> taps Move + dialog',
      (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          wrapNavalScrollBody(
            navalPanelRoot(
              children: [
                fleetMoveTile(
                  title: 'Fleet 2',
                  subtitle: 'New World — Outer Sea',
                  onMovePressed: () => taps++,
                ),
              ],
            ),
          ),
        );
        expect(await e2eTapMoveOnFirstNonHomeFleet(tester), isTrue);
        expect(taps, 1);
        expect(find.byType(AlertDialog), findsOneWidget);
      },
    );

    testWidgets('home fleet skipped; second tile (NW) wins', (tester) async {
      var homeTaps = 0;
      var nwTaps = 0;
      await tester.pumpWidget(
        wrapNavalScrollBody(
          navalPanelRoot(
            children: [
              ExpansionTile(
                title: const Text('Home Fleet'),
                initiallyExpanded: true,
                children: [
                  FleetMoveButton(
                    buttonKey: kCtE2EFleetMoveActionKey,
                    onPressedSpy: () => homeTaps++,
                  ),
                ],
              ),
              fleetMoveTile(
                title: 'Fleet 3',
                subtitle: 'New World — Inner Sea',
                onMovePressed: () => nwTaps++,
              ),
            ],
          ),
        ),
      );
      expect(await e2eTapMoveOnFirstNonHomeFleet(tester), isTrue);
      expect(homeTaps, 0);
      expect(nwTaps, 1);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('NW tile preferred over earlier OW tile (location-line gate)', (
      tester,
    ) async {
      var owTaps = 0;
      var nwTaps = 0;
      await tester.pumpWidget(
        wrapNavalScrollBody(
          navalPanelRoot(
            children: [
              fleetMoveTile(
                title: 'Fleet 1',
                subtitle: 'Old World — Coastal Sea',
                onMovePressed: () => owTaps++,
              ),
              fleetMoveTile(
                title: 'Fleet 2',
                subtitle: 'New World — Outer Sea',
                onMovePressed: () => nwTaps++,
              ),
            ],
          ),
        ),
      );
      expect(await e2eTapMoveOnFirstNonHomeFleet(tester), isTrue);
      expect(
        owTaps,
        0,
        reason:
            'NW preference must skip the earlier OW tile so the '
            'fleet-reach loop progresses toward New World per Bottleneck 4.',
      );
      expect(nwTaps, 1);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets(
      'no NW location available -> first hit-testable non-home Move tapped',
      (tester) async {
        var firstTaps = 0;
        var secondTaps = 0;
        await tester.pumpWidget(
          wrapNavalScrollBody(
            navalPanelRoot(
              children: [
                fleetMoveTile(
                  title: 'Fleet 1',
                  subtitle: 'Old World — Coastal Sea',
                  onMovePressed: () => firstTaps++,
                ),
                fleetMoveTile(
                  title: 'Fleet 2',
                  subtitle: 'Old World — Inner Sea',
                  onMovePressed: () => secondTaps++,
                ),
              ],
            ),
          ),
        );
        expect(await e2eTapMoveOnFirstNonHomeFleet(tester), isTrue);
        expect(
          firstTaps,
          1,
          reason:
              'When no tile has an NW subtitle the first hit-testable '
              'Move must be the fallback; pinning this prevents the loop '
              'silently switching to a later iteration order.',
        );
        expect(secondTaps, 0);
        expect(find.byType(AlertDialog), findsOneWidget);
      },
    );

    testWidgets(
      'icon-only Move button (narrow viewport) tapped via stable key',
      (tester) async {
        // Regression for #2336: production collapses the dense naval action
        // cluster to icon-only at narrow test-host viewports, so no
        // `Text('Move')` renders. The helper must locate the control by
        // [kCtE2EFleetMoveActionKey], not the label.
        var taps = 0;
        await tester.pumpWidget(
          wrapNavalScrollBody(
            navalPanelRoot(
              children: [
                fleetMoveTile(
                  title: 'Fleet 2',
                  subtitle: 'New World — Outer Sea',
                  iconOnly: true,
                  onMovePressed: () => taps++,
                ),
              ],
            ),
          ),
        );
        expect(
          find.text('Move'),
          findsNothing,
          reason:
              'Sanity: the icon-only Move control renders no label, so a '
              'text-based finder would fail — the regression this test pins.',
        );
        expect(
          find.byKey(kCtE2EFleetMoveActionKey),
          findsOneWidget,
          reason: 'The stable key must be present on the icon-only control.',
        );
        expect(await e2eTapMoveOnFirstNonHomeFleet(tester), isTrue);
        expect(taps, 1);
        expect(find.byType(AlertDialog), findsOneWidget);
      },
    );

    testWidgets('collapsed icon-only tile expanded then keyed Move tapped', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        wrapNavalScrollBody(
          navalPanelRoot(
            children: [
              fleetMoveTile(
                title: 'Fleet 5',
                subtitle: 'New World — Inner Sea',
                initiallyExpanded: false,
                iconOnly: true,
                onMovePressed: () => taps++,
              ),
            ],
          ),
        ),
      );
      expect(await e2eTapMoveOnFirstNonHomeFleet(tester), isTrue);
      expect(
        taps,
        1,
        reason:
            'Collapsed tiles must still be expanded and the keyed '
            'icon-only Move tapped (Refs #2336).',
      );
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets(
      'collapsed tile expanded via Icons.expand_more before Move tap',
      (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          wrapNavalScrollBody(
            navalPanelRoot(
              children: [
                fleetMoveTile(
                  title: 'Fleet 4',
                  subtitle: 'New World — Inner Sea',
                  initiallyExpanded: false,
                  onMovePressed: () => taps++,
                ),
              ],
            ),
          ),
        );
        expect(
          find.text('Move'),
          findsNothing,
          reason:
              'Sanity: Move text is not mounted while the tile is '
              'collapsed (children only build after expansion).',
        );
        expect(await e2eTapMoveOnFirstNonHomeFleet(tester), isTrue);
        expect(
          taps,
          1,
          reason:
              'The helper must tap the expand-more icon and wait for '
              'Move text to appear before issuing the Move tap, otherwise '
              'every collapsed tile would silently fall through (Bottleneck 4).',
        );
        expect(find.byType(AlertDialog), findsOneWidget);
      },
    );

    testWidgets(
      'em-dash, en-dash and hyphen NW subtitles all qualify as preferred',
      (tester) async {
        for (final separator in const ['—', '–', '-']) {
          await tester.pumpWidget(
            wrapNavalScrollBody(
              navalPanelRoot(
                children: [
                  fleetMoveTile(
                    title: 'Fleet 9',
                    subtitle: 'New World $separator Outer Sea',
                  ),
                ],
              ),
            ),
          );
          expect(
            await e2eTapMoveOnFirstNonHomeFleet(tester),
            isTrue,
            reason:
                'Move on a non-home fleet should fire for separator '
                '"$separator" (e2eTextLooksLikeNewWorldLocationLine '
                'accepts em / en / hyphen variants).',
          );
          expect(find.byType(AlertDialog), findsOneWidget);
          // Dismiss before the next pumpWidget so showDialog routes do not
          // leak across the loop iterations.
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
