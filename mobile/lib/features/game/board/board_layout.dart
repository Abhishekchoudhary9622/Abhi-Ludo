import '../../../game/board/cell_id.dart';

/// A position on the visual 15x15 grid used to render the board.
///
/// Per docs/architecture.md ("LOGICAL BOARD vs VISUAL BOARD"), this class
/// and everything in this file is purely a *rendering* concern — it knows
/// nothing about game rules and is never consulted by anything under
/// `lib/game/`. It only translates a [CellId] (produced by the logical
/// board) into a grid coordinate a widget can draw at. Grid coordinates use
/// doubles so token "base" slots can sit at fractional positions (centered
/// within a 6x6 yard block) without needing a finer overall grid.
class GridPos {
  final double row;
  final double col;
  const GridPos(this.row, this.col);

  @override
  String toString() => 'GridPos($row, $col)';
}

/// Maps logical [CellId]s to positions on a 15x15 grid, using the classic
/// cross-shaped Ludo board topology (four 6x6 corner yards, a 3-cell-wide
/// cross arm, a 52-cell ring, and one home lane per seat leading to a
/// shared center). This is standard, generic board-game geometry — not
/// copied from any specific existing app's artwork or source.
///
/// Seat 0's ring segment and home lane are the only ones written out by
/// hand; every other seat's is derived by rotating seat 0's 90 degrees per
/// seat (matching `BoardConfig`'s fixed 13-cells-per-seat spacing), so
/// there is exactly one seat's worth of geometry to get right — the same
/// "one implementation, reused per seat" principle `PlayerPath` uses
/// logically (docs/board-system.md), applied here purely for rendering.
class BoardLayout {
  static const int gridSize = 15;
  static const double _center = 7;
  static const int _cellsPerSeat = 13;

  const BoardLayout();

  /// Seat 0's 13 ring-cell grid positions, in ring-index order: right
  /// along the bottom edge of the top-left yard, then up the left column
  /// of the vertical arm, then right across the top edge.
  static const List<GridPos> _seat0RingSegment = [
    GridPos(6, 1),
    GridPos(6, 2),
    GridPos(6, 3),
    GridPos(6, 4),
    GridPos(6, 5),
    GridPos(5, 6),
    GridPos(4, 6),
    GridPos(3, 6),
    GridPos(2, 6),
    GridPos(1, 6),
    GridPos(0, 6),
    GridPos(0, 7),
    GridPos(0, 8),
  ];

  /// Seat 0's 6 home-lane cells: row 7, columns 1..6, leading into the
  /// shared center cell at (7,7).
  static const List<GridPos> _seat0HomeLane = [
    GridPos(7, 1),
    GridPos(7, 2),
    GridPos(7, 3),
    GridPos(7, 4),
    GridPos(7, 5),
    GridPos(7, 6),
  ];

  static const GridPos _finalHome = GridPos(_center, _center);

  /// Top-left corner of each seat's 6x6 base yard. Hardcoded per seat
  /// (rather than derived by rotating a single corner point) because
  /// rotating one corner of a 6x6 block does not land on the corresponding
  /// corner of the rotated block — the four corners are simply the four
  /// quadrants of the 15x15 grid, which is simpler and clearer to state
  /// directly.
  static const List<GridPos> _yardOrigins = [
    GridPos(0, 0), // seat 0: top-left
    GridPos(0, 9), // seat 1: top-right
    GridPos(9, 9), // seat 2: bottom-right
    GridPos(9, 0), // seat 3: bottom-left
  ];

  /// Rotates [pos] 90 degrees clockwise around the 15x15 grid's center,
  /// composed [times] times. Verified against the standard board layout:
  /// rotating seat 0's ring segment/home lane by 1/2/3 gives seat 1/2/3's
  /// segment and lane, each correctly adjacent to the previous seat's last
  /// cell, tracing one continuous 52-cell ring.
  static GridPos _rotate(GridPos pos, int times) {
    var row = pos.row;
    var col = pos.col;
    for (var i = 0; i < times; i++) {
      final rotatedRow = col;
      final rotatedCol = (gridSize - 1) - row;
      row = rotatedRow;
      col = rotatedCol;
    }
    return GridPos(row, col);
  }

  /// The grid position of [cell].
  GridPos positionOf(CellId cell) {
    switch (cell) {
      case RingCell(index: final index):
        final seatOwner = index ~/ _cellsPerSeat;
        final withinSegment = index % _cellsPerSeat;
        return _rotate(_seat0RingSegment[withinSegment], seatOwner);
      case HomeLaneCell(ownerSeat: final seat, laneIndex: final laneIndex):
        return _rotate(_seat0HomeLane[laneIndex], seat);
      case FinalHomeCell():
        return _finalHome;
    }
  }

  /// The top-left grid corner of [seat]'s 6x6 base yard.
  GridPos yardOrigin(int seat) => _yardOrigins[seat];

  /// The grid position a token from [seat] should render at while still in
  /// base, based on its [tokenId] (0..3) — arranged in a small 2x2 pattern
  /// centered within that seat's yard.
  GridPos baseSlot(int seat, int tokenId) {
    final origin = yardOrigin(seat);
    const slotOffsets = [
      GridPos(1.5, 1.5),
      GridPos(1.5, 4),
      GridPos(4, 1.5),
      GridPos(4, 4),
    ];
    final offset = slotOffsets[tokenId % 4];
    return GridPos(origin.row + offset.row, origin.col + offset.col);
  }
}
