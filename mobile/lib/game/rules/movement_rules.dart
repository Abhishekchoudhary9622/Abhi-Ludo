import '../board/board_config.dart';
import '../state/player_state.dart';
import '../state/token_state.dart';

/// Movement legality and resulting-position calculation.
///
/// Implements Ludo King movement rules:
/// - A finished token can never move again.
/// - Base exit requires exactly a 6 (lands on entry cell, progress 0).
/// - Overshooting final home (progress 57) is disallowed.
/// - In modes where [killRequiredToEnterHome] is true (Quick Mode), a player with
///   0 kills cannot advance a token past progress 50 into the home corridor (51..57).
class MovementRules {
  const MovementRules();

  /// Whether [token] belonging to [player] can legally move by [diceValue] steps.
  bool canMove(
    TokenState token,
    int diceValue, {
    required PlayerState player,
    required bool killRequiredToEnterHome,
  }) {
    if (token.isFinished) return false;
    if (token.isInBase) return diceValue == 6;

    final currentProgress = (token.position as OnPath).progress;
    final destinationProgress = currentProgress + diceValue;

    // Cannot overshoot final home
    if (destinationProgress > BoardConfig.finishProgress) return false;

    // In Quick Mode, kill is required to enter home lane (progress > 50)
    if (killRequiredToEnterHome && !player.hasKilled && destinationProgress > 50) {
      return false;
    }

    return true;
  }

  /// The progress [token] will have after moving by [diceValue] steps.
  int resultingProgress(TokenState token, int diceValue) {
    if (token.isInBase) return 0;
    return (token.position as OnPath).progress + diceValue;
  }

  /// IDs of every token belonging to [player] that can legally move by [diceValue] steps.
  List<int> legalTokenIds(
    PlayerState player,
    int diceValue, {
    required bool killRequiredToEnterHome,
  }) {
    return [
      for (final token in player.tokens)
        if (canMove(
          token,
          diceValue,
          player: player,
          killRequiredToEnterHome: killRequiredToEnterHome,
        ))
          token.tokenId,
    ];
  }
}
