// Shared mutable tap counter for widget-test fixtures (#4344 Slice C
// densify). Held outside the harness widgets so the `must_be_immutable`
// lint stays satisfied on `StatelessWidget` fixtures — a `StatefulWidget`
// -only fixture would otherwise need to leak counter state up through a
// `GlobalKey`, which is more brittle than a plain holder.
library;

class E2eTapCounter {
  int value = 0;
}
