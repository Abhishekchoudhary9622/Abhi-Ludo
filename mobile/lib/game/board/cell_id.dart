/// Identity of a single logical board cell.
///
/// This module has **no Flutter dependency and no pixel/coordinate
/// knowledge** — see docs/board-system.md. A [CellId] is either:
///  - a [RingCell]: one of the 52 shared cells all players' tokens travel
///    along, identified by an absolute index (0..51).
///  - a [HomeLaneCell]: one of a single player's 6 private "run-in" cells,
///    never shared with other players.
///  - a [FinalHomeCell]: the single cell a token occupies once it has
///    finished (per player).
///
/// A token sitting in its base (not yet on the board) has no [CellId] at
/// all — see `TokenPosition` in `lib/game/state/token_state.dart`.
sealed class CellId {
  const CellId();
}

/// One of the 52 shared ring cells, identified by an absolute ring index.
final class RingCell extends CellId {
  /// Absolute ring index, always in `0..51`.
  final int index;

  const RingCell(this.index)
    : assert(index >= 0 && index < 52, 'RingCell index must be 0..51');

  @override
  bool operator ==(Object other) => other is RingCell && other.index == index;

  @override
  int get hashCode => Object.hash(RingCell, index);

  @override
  String toString() => 'RingCell($index)';
}

/// One of a single player's 6 private home-lane cells.
final class HomeLaneCell extends CellId {
  /// The seat (0..3) that owns this lane. Never shared with other players.
  final int ownerSeat;

  /// Position within the lane, `0..5` (0 = entered from the ring, 5 = just
  /// before final home).
  final int laneIndex;

  const HomeLaneCell(this.ownerSeat, this.laneIndex)
    : assert(ownerSeat >= 0 && ownerSeat < 4, 'ownerSeat must be 0..3'),
      assert(laneIndex >= 0 && laneIndex < 6, 'laneIndex must be 0..5');

  @override
  bool operator ==(Object other) =>
      other is HomeLaneCell &&
      other.ownerSeat == ownerSeat &&
      other.laneIndex == laneIndex;

  @override
  int get hashCode => Object.hash(HomeLaneCell, ownerSeat, laneIndex);

  @override
  String toString() => 'HomeLaneCell(seat: $ownerSeat, lane: $laneIndex)';
}

/// The single cell a token occupies once it has completed its path.
final class FinalHomeCell extends CellId {
  /// The seat (0..3) that owns this final-home cell.
  final int ownerSeat;

  const FinalHomeCell(this.ownerSeat)
    : assert(ownerSeat >= 0 && ownerSeat < 4, 'ownerSeat must be 0..3');

  @override
  bool operator ==(Object other) =>
      other is FinalHomeCell && other.ownerSeat == ownerSeat;

  @override
  int get hashCode => Object.hash(FinalHomeCell, ownerSeat);

  @override
  String toString() => 'FinalHomeCell(seat: $ownerSeat)';
}
