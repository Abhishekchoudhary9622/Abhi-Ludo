import 'board_config.dart';
import 'cell_id.dart';

/// A single player's full logical path, derived from [BoardConfig].
///
/// A token's position is a single integer "progress" value:
///  - `0 .. ringStepsPerPlayer - 1` (0..50): standing on a ring cell.
///  - `ringStepsPerPlayer .. finishProgress - 1` (51..56): standing in the
///    player's private home lane.
///  - `finishProgress` (57): the token has reached final home.
///
/// There is exactly one implementation of "how a path is built" here,
/// reused for all 4 seats by varying [seat] — see docs/board-system.md.
class PlayerPath {
  final int seat;
  final BoardConfig config;

  const PlayerPath({required this.seat, required this.config});

  /// The [CellId] a token from this path occupies at [progress] steps
  /// travelled (`0..BoardConfig.finishProgress`).
  ///
  /// Progress `0` means "just left base" and stands on the seat's entry
  /// ring cell — a token still in base has no [CellId] at all (see
  /// `TokenPosition`).
  CellId cellAt(int progress) {
    assert(
      progress >= 0 && progress <= BoardConfig.finishProgress,
      'progress must be 0..${BoardConfig.finishProgress}',
    );

    if (progress == BoardConfig.finishProgress) {
      return FinalHomeCell(seat);
    }

    if (progress < BoardConfig.ringStepsPerPlayer) {
      final absoluteIndex =
          (config.entryIndex(seat) + progress) % BoardConfig.ringSize;
      return RingCell(absoluteIndex);
    }

    final laneIndex = progress - BoardConfig.ringStepsPerPlayer;
    return HomeLaneCell(seat, laneIndex);
  }

  /// Whether [progress] places the token in its own home lane (not on the
  /// shared ring anymore).
  bool isInHomeLane(int progress) =>
      progress >= BoardConfig.ringStepsPerPlayer &&
      progress < BoardConfig.finishProgress;

  /// Whether [progress] represents a token that has reached final home.
  bool isFinished(int progress) => progress == BoardConfig.finishProgress;

  /// Whether moving from [progress] by [steps] is a legal *destination*
  /// purely from a path-bounds perspective (exact-into-home; no overshoot).
  /// This does not check base-exit-needs-six or other turn-level rules —
  /// see `MovementRules` (added in Phase 3) for full move legality.
  bool isValidDestination(int progress, int steps) {
    final destination = progress + steps;
    return destination <= BoardConfig.finishProgress;
  }
}
