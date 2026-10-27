/// Central, table-driven configuration for the logical board.
///
/// Per docs/board-system.md, every player's path is *derived* from this one
/// configuration rather than hand-written per player — this class is the
/// single source of truth for ring size, per-seat entry points, home-lane
/// length, and which ring cells are safe.
///
/// This is generic board-game geometry (a standard cross-shaped
/// track/home-lane layout), not a copy of any specific existing app's
/// artwork or source.
class BoardConfig {
  /// Number of cells in the shared outer ring all players travel along.
  static const int ringSize = 52;

  /// Number of player seats supported.
  static const int seatCount = 4;

  /// Number of cells in each player's private home lane (run-in to final
  /// home).
  static const int homeLaneLength = 6;

  /// Number of ring cells a token walks through before turning into its own
  /// home lane. Progress values `0..ringStepsPerPlayer - 1` are ring cells.
  static const int ringStepsPerPlayer = 51;

  /// The progress value representing a token that has reached final home.
  /// `51 ring steps + 6 home-lane steps = 57`.
  static const int finishProgress = ringStepsPerPlayer + homeLaneLength;

  /// How many ring cells apart each seat's entry point is (`52 / 4 = 13`).
  static const int _seatSpacing = ringSize ~/ seatCount;

  /// Ring-index offset (relative to a seat's own entry cell) of that seat's
  /// additional "star" safe cell, beyond the entry cell itself. This
  /// mirrors the common Ludo convention of one extra safe cell partway
  /// around each seat's stretch of the ring — the exact offset is a design
  /// choice, not copied artwork/text from any specific existing app.
  static const int _starCellOffset = 8;

  const BoardConfig();

  /// The absolute ring index a token from [seat] lands on when it first
  /// leaves base (progress == 0).
  int entryIndex(int seat) {
    _assertValidSeat(seat);
    return (seat * _seatSpacing) % ringSize;
  }

  /// Whether [ringIndex] is a safe cell (no capture can occur there).
  ///
  /// Safe cells are every seat's entry cell plus one star cell per seat —
  /// 8 safe cells total on a 52-cell ring, consistent with common Ludo
  /// convention. Exact indices are finalized in docs/game-rules.md once
  /// capture rules are implemented (Phase 4).
  bool isSafeRingIndex(int ringIndex) {
    assert(
      ringIndex >= 0 && ringIndex < ringSize,
      'ringIndex must be 0..${ringSize - 1}',
    );
    for (var seat = 0; seat < seatCount; seat++) {
      final entry = entryIndex(seat);
      final star = (entry + _starCellOffset) % ringSize;
      if (ringIndex == entry || ringIndex == star) return true;
    }
    return false;
  }

  void _assertValidSeat(int seat) {
    assert(seat >= 0 && seat < seatCount, 'seat must be 0..${seatCount - 1}');
  }
}
