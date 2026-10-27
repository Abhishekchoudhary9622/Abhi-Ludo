import '../board/board_state.dart';
import '../board/cell_id.dart';
import '../state/player_state.dart';
import '../state/token_state.dart';

/// Result of checking whether a just-landed token triggers a capture.
sealed class CaptureOutcome {
  const CaptureOutcome();
}

/// No capture happened (empty cell, own tokens only, safe cell, or blocked by a stack).
class NoCapture extends CaptureOutcome {
  const NoCapture();
}

/// Exactly one opponent token was captured and must return to base.
class Captured extends CaptureOutcome {
  final TokenState capturedToken;
  const Captured(this.capturedToken);
}

/// Opponent detection, safe-cell exemption, and capture resolution.
///
/// Multi-token-per-cell handling (Ludo King standard):
///  - A player's own tokens may freely stack on the same cell (no self-capture).
///  - Landing on a non-safe cell with exactly one opponent token captures it.
///  - Landing on a non-safe cell where two or more opponent tokens from the
///    *same* opponent are already stacked together is a "block": the
///    landing token does not capture and the move is disallowed.
///  - Safe cells (stars and player entry arrows) prevent any capture.
class CaptureRules {
  final BoardState board;

  const CaptureRules(this.board);

  /// Whether moving to [cell] is blocked because two or more of the same
  /// opponent's tokens already occupy that non-safe cell.
  bool isBlocked({
    required CellId cell,
    required int movingSeat,
    required List<PlayerState> players,
  }) {
    if (cell is! RingCell) return false; // home-lane cells are never shared
    if (board.config.isSafeRingIndex(cell.index)) return false;

    final opponents = board.opponentsOnCell(
      cell: cell,
      excludingSeat: movingSeat,
      players: players,
    );
    if (opponents.length < 2) return false;

    final firstOwner = opponents.first.ownerSeat;
    return opponents.every((t) => t.ownerSeat == firstOwner);
  }

  /// Resolves what happens when a token (owned by [movingSeat]) lands
  /// on [cell]. Call [isBlocked] first — this method assumes the move was
  /// already confirmed not to be blocked.
  CaptureOutcome resolve({
    required CellId cell,
    required int movingSeat,
    required List<PlayerState> players,
  }) {
    if (cell is! RingCell) return const NoCapture(); // home lanes are private
    if (board.config.isSafeRingIndex(cell.index)) return const NoCapture();

    final opponents = board.opponentsOnCell(
      cell: cell,
      excludingSeat: movingSeat,
      players: players,
    );
    if (opponents.isEmpty) return const NoCapture();

    final target = opponents.first;
    return Captured(target);
  }

  /// Whether [ringIndex] is a safe cell.
  bool isSafe(int ringIndex) => board.config.isSafeRingIndex(ringIndex);
}
