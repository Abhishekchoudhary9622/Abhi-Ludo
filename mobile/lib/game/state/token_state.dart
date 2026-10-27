import '../board/board_config.dart';

/// Where a token currently is, in purely logical terms.
///
/// A token is either still in its base (hasn't rolled the six needed to
/// leave yet) or somewhere along its own path, expressed as a progress
/// integer (see `PlayerPath` for how progress maps to a `CellId`).
sealed class TokenPosition {
  const TokenPosition();
}

/// The token has not yet left base.
final class InBase extends TokenPosition {
  const InBase();

  @override
  bool operator ==(Object other) => other is InBase;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'InBase';
}

/// The token is on the board (ring or home lane) or has finished, at the
/// given [progress] (0..57 — see `BoardConfig.finishProgress`).
final class OnPath extends TokenPosition {
  final int progress;

  const OnPath(this.progress) : assert(progress >= 0);

  @override
  bool operator ==(Object other) =>
      other is OnPath && other.progress == progress;

  @override
  int get hashCode => Object.hash(OnPath, progress);

  @override
  String toString() => 'OnPath($progress)';
}

/// Immutable snapshot of a single token's state.
///
/// Per docs/game-engine.md: `shieldAvailable`/`shieldActive` always exist on
/// the model, but only ever become true / get consulted when the active
/// rule set is the Power Mode rule set — under Classic Mode they stay
/// permanently false, which is how Power Mode stays additive rather than
/// forked.
class TokenState {
  final int tokenId;
  final int ownerSeat;
  final TokenPosition position;

  const TokenState({
    required this.tokenId,
    required this.ownerSeat,
    this.position = const InBase(),
  });

  bool get isInBase => position is InBase;

  bool get isFinished =>
      position is OnPath &&
      (position as OnPath).progress == BoardConfig.finishProgress;

  TokenState copyWith({
    TokenPosition? position,
  }) {
    return TokenState(
      tokenId: tokenId,
      ownerSeat: ownerSeat,
      position: position ?? this.position,
    );
  }


  @override
  String toString() =>
      'TokenState(id: $tokenId, seat: $ownerSeat, pos: $position)';
}
