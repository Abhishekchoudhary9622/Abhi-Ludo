import 'token_state.dart';

/// Immutable snapshot of a single player/seat's state.
///
/// Per docs/game-engine.md, each player always has exactly 4 tokens
/// (section 1's "4 tokens per player" requirement).
class PlayerState {
  final int seat;
  final String displayName;
  final List<TokenState> tokens;

  final bool isActive;
  final bool isBot;
  final int kills;

  PlayerState({
    required this.seat,
    required this.displayName,
    this.isActive = true,
    this.isBot = false,
    this.kills = 0,
    List<TokenState>? tokens,
  }) : tokens =
           tokens ??
           List.generate(
             4,
             (i) => TokenState(tokenId: i, ownerSeat: seat),
           );

  /// Whether this player has captured at least one opponent pawn (used in Quick Mode).
  bool get hasKilled => kills > 0;

  /// Count of tokens that have reached final home (progress 57).
  int get finishedTokensCount => tokens.where((t) => t.isFinished).length;

  /// A player has finished once all 4 of their tokens have reached final home.
  bool get hasFinished => tokens.every((t) => t.isFinished);

  PlayerState copyWith({
    List<TokenState>? tokens,
    bool? isActive,
    bool? isBot,
    int? kills,
  }) {
    return PlayerState(
      seat: seat,
      displayName: displayName,
      isActive: isActive ?? this.isActive,
      isBot: isBot ?? this.isBot,
      kills: kills ?? this.kills,
      tokens: tokens ?? this.tokens,
    );
  }



  @override
  String toString() =>
      'PlayerState(seat: $seat, name: $displayName, tokens: $tokens)';
}
