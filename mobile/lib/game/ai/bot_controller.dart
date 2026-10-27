import '../board/board_config.dart';
import '../board/cell_id.dart';
import '../engine/game_engine.dart';
import '../engine/game_state.dart';
import '../rules/capture_rules.dart';
import '../state/player_state.dart';
import '../state/token_state.dart';

/// Heuristic AI decision engine for offline computer players.
class BotController {
  const BotController();

  /// Evaluates and selects the best token to move among [legalTokenIds]
  /// for [botPlayer] based on tactical scoring heuristics.
  int selectBestMove({
    required GameState state,
    required GameEngine engine,
    required PlayerState botPlayer,
    required List<int> legalTokenIds,
    required int diceValue,
  }) {
    if (legalTokenIds.isEmpty) return -1;
    if (legalTokenIds.length == 1) return legalTokenIds.first;

    int bestTokenId = legalTokenIds.first;
    int bestScore = -999999;

    for (final tokenId in legalTokenIds) {
      final token = botPlayer.tokens.firstWhere((t) => t.tokenId == tokenId);
      final score = _evaluateMoveScore(
        state: state,
        engine: engine,
        botPlayer: botPlayer,
        token: token,
        diceValue: diceValue,
      );

      if (score > bestScore) {
        bestScore = score;
        bestTokenId = tokenId;
      }
    }

    return bestTokenId;
  }

  int _evaluateMoveScore({
    required GameState state,
    required GameEngine engine,
    required PlayerState botPlayer,
    required TokenState token,
    required int diceValue,
  }) {
    int score = 0;
    final movementRules = engine.rules.movement;
    final captureRules = engine.rules.capture;
    final path = state.board.pathForSeat(botPlayer.seat);

    // 1. Exiting Base on 6
    if (token.isInBase) {
      // Prioritize having at least 2 pawns active on board
      final activeOnBoard = botPlayer.tokens.where((t) => !t.isInBase && !t.isFinished).length;
      if (activeOnBoard == 0) {
        return 90;
      } else if (activeOnBoard == 1) {
        return 75;
      }
      return 55;
    }

    final currentProgress = (token.position as OnPath).progress;
    final destinationProgress = movementRules.resultingProgress(token, diceValue);
    final destinationCell = path.cellAt(destinationProgress);

    // 2. Reaching Final Home (Progress 57)
    if (destinationProgress == BoardConfig.finishProgress) {
      return 150; // Highest priority: finishes pawn & awards bonus roll
    }

    // 3. Entering Home Lane (Safe Corridor: Progress 51..56)
    if (currentProgress <= 50 && destinationProgress > 50) {
      score += 65; // Safe corridor protects pawn permanently
    }

    // 4. Capture Opportunity (Kill)
    final captureOutcome = captureRules.resolve(
      cell: destinationCell,
      movingSeat: botPlayer.seat,
      players: state.players,
    );

    if (captureOutcome is Captured) {
      score += 120; // Massive advantage: eliminates opponent + awards bonus roll
    }

    // 5. Landing on Safe Star or Starting Cell
    if (destinationCell is RingCell && captureRules.isSafe(destinationCell.index)) {
      score += 45;
    }

    // 6. Escape Danger from Behind
    if (currentProgress <= 50) {
      final currentCell = path.cellAt(currentProgress);
      if (currentCell is RingCell && !captureRules.isSafe(currentCell.index)) {
        if (_isThreatenedAt(ringIndex: currentCell.index, state: state, mySeat: botPlayer.seat)) {
          score += 40; // Escape vulnerable square
        }
      }
    }

    // 7. Avoid Stepping into Immediate Danger
    if (destinationCell is RingCell && !captureRules.isSafe(destinationCell.index)) {
      if (_isThreatenedAt(ringIndex: destinationCell.index, state: state, mySeat: botPlayer.seat)) {
        score -= 30; // Risky move
      }
    }

    // 8. General Forward Progress
    score += (destinationProgress ~/ 3);

    return score;
  }

  /// Checks if any opponent is within 1–6 steps behind [ringIndex] on the 52-cell ring.
  bool _isThreatenedAt({
    required int ringIndex,
    required GameState state,
    required int mySeat,
  }) {
    for (final player in state.players) {
      if (!player.isActive || player.seat == mySeat) continue;

      for (final token in player.tokens) {
        if (token.position is! OnPath) continue;
        final progress = (token.position as OnPath).progress;
        if (progress > 50) continue; // In private home lane, cannot capture

        final opponentCell = state.board.pathForSeat(player.seat).cellAt(progress);
        if (opponentCell is RingCell) {
          final distance = (ringIndex - opponentCell.index + BoardConfig.ringSize) % BoardConfig.ringSize;
          if (distance >= 1 && distance <= 6) {
            return true;
          }
        }

      }
    }
    return false;
  }
}
