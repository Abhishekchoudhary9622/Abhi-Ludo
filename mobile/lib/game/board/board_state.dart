import '../state/player_state.dart';
import '../state/token_state.dart';
import 'board_config.dart';
import 'cell_id.dart';
import 'player_path.dart';

/// The logical board: configuration plus each seat's derived path, plus a
/// live cell-occupancy index built from the current players' tokens.
///
/// Per docs/board-system.md, this answers "which opponents are on this
/// cell?" via a `Map<CellId, List<TokenState>>` rebuilt from current token
/// positions — no pixel/screen knowledge anywhere in this class.
class BoardState {
  final BoardConfig config;
  final List<PlayerPath> paths;

  BoardState({BoardConfig? config})
    : config = config ?? const BoardConfig(),
      paths = List.generate(
        BoardConfig.seatCount,
        (seat) => PlayerPath(seat: seat, config: config ?? const BoardConfig()),
      );

  PlayerPath pathForSeat(int seat) => paths[seat];

  /// Resolves a token's current [CellId], or `null` if it's still in base.
  CellId? cellFor(TokenState token) {
    final position = token.position;
    if (position is InBase) return null;
    if (position is OnPath) {
      return pathForSeat(token.ownerSeat).cellAt(position.progress);
    }
    return null;
  }

  /// Builds a map from occupied [CellId]s to the list of tokens sitting on
  /// that cell, across every player supplied. Cells with no tokens are
  /// simply absent from the map (not present with an empty list).
  Map<CellId, List<TokenState>> occupancyIndex(List<PlayerState> players) {
    final index = <CellId, List<TokenState>>{};
    for (final player in players) {
      for (final token in player.tokens) {
        final cell = cellFor(token);
        if (cell == null) continue;
        index.putIfAbsent(cell, () => []).add(token);
      }
    }
    return index;
  }

  /// Tokens belonging to *other* players currently sharing [cell] with
  /// [excludingSeat]. Used by capture-rule checks (Phase 4) to find which
  /// opponents are on a given cell.
  List<TokenState> opponentsOnCell({
    required CellId cell,
    required int excludingSeat,
    required List<PlayerState> players,
  }) {
    final onCell = occupancyIndex(players)[cell] ?? const [];
    return onCell.where((t) => t.ownerSeat != excludingSeat).toList();
  }
}
