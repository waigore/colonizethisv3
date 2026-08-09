/// Discriminator for which [Orders] family a rejected order belonged to.
///
/// Used by [AppOrderRejectedEvent] and logic-layer [OrderRejectedEvent] so UI
/// can route rejections to the owning panel (Refs #4146).
enum OrderKind {
  move,
  armyMove,
  buildUnit,
  work,
  recruitWorker,
  diplomacy,
  research,
  navalMove,
  navalMission,
  trade,
}
