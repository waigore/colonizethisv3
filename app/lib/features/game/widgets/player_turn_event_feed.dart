import 'package:flutter/material.dart';

class PlayerTurnEventFeedEntry {
  const PlayerTurnEventFeedEntry({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;
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
        width: 320,
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
