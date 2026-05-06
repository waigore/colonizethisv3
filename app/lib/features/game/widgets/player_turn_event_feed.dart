import 'package:flutter/material.dart';

import '../flame/game_screen_shared.dart'
    show kGameMapWideProvinceSidePanelWidth, kPlayerTurnFeedToggleButtonKey;

class PlayerTurnEventFeedEntry {
  const PlayerTurnEventFeedEntry({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;
}

/// Newspaper toggle for the human-player turn event feed; lives in the map controls band.
/// SPEC/ui/player-turn-event-feed.md.
class PlayerTurnEventsFeedToggleButton extends StatelessWidget {
  const PlayerTurnEventsFeedToggleButton({
    super.key,
    required this.eventCount,
    required this.tooltip,
    required this.showFeed,
    required this.onPressed,
  });

  final int eventCount;
  final String tooltip;
  final bool showFeed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final badgeLabel = eventCount > 99 ? '99+' : '$eventCount';
    return Tooltip(
      message: tooltip,
      child: IconButton(
        key: kPlayerTurnFeedToggleButtonKey,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.62),
          foregroundColor: Colors.white,
        ),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(showFeed ? Icons.newspaper : Icons.newspaper_outlined),
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                constraints: const BoxConstraints(minHeight: 16, minWidth: 16),
                child: Text(
                  badgeLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerTurnEventFeedCard extends StatelessWidget {
  const PlayerTurnEventFeedCard({
    super.key,
    required this.entries,
    required this.emptyLabel,
  });

  final List<PlayerTurnEventFeedEntry> entries;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: kGameMapWideProvinceSidePanelWidth,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: entries.isEmpty
                    ? Text(
                        emptyLabel,
                        style: const TextStyle(color: Colors.white70),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final text = Text(
                            entry.text,
                            style: const TextStyle(color: Colors.white),
                          );
                          if (entry.onTap == null) {
                            return text;
                          }
                          return InkWell(
                            onTap: entry.onTap,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: text,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
