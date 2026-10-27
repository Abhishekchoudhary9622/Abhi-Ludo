import '../state/player_state.dart';

/// Win detection based on mode-configured [tokensToWin].
///
/// - Classic Mode: 4 tokens in final home.
/// - Quick Mode: 1 token in final home.
class WinRules {
  final int tokensToWin;

  const WinRules({this.tokensToWin = 4});

  /// The seat of the first active player in [players] who has reached [tokensToWin],
  /// or `null` if no one has won yet.
  int? checkWinner(List<PlayerState> players) {
    for (final player in players) {
      if (player.isActive && player.finishedTokensCount >= tokensToWin) {
        return player.seat;
      }
    }
    return null;
  }
}
