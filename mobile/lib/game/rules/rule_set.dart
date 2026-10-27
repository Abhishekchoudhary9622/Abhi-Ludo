import '../board/board_state.dart';
import 'capture_rules.dart';
import 'movement_rules.dart';
import 'turn_rules.dart';
import 'win_rules.dart';

/// Game modes matching Ludo King mechanics:
/// - [classic]: Traditional rules, all 4 tokens start in base, 4 tokens to win, normal home entry.
/// - [quick]: Fast-paced match, 2 tokens start deployed on track, 1 token to win, kill required to enter home.
enum GameMode { classic, quick }

/// Bundles the rule modules and configuration a [GameEngine] instance needs.
class RuleSet {
  final GameMode mode;
  final int tokensToWin;
  final bool killRequiredToEnterHome;
  final int initialDeployedTokens;
  final MovementRules movement;
  final CaptureRules capture;
  final WinRules win;
  final TurnRules turn;

  const RuleSet._({
    required this.mode,
    required this.tokensToWin,
    required this.killRequiredToEnterHome,
    required this.initialDeployedTokens,
    required this.movement,
    required this.capture,
    required this.win,
    required this.turn,
  });

  /// Classic Mode (Ludo King): 4 tokens in base, 4 tokens to win, free home entry.
  factory RuleSet.classic(BoardState board) {
    return RuleSet._(
      mode: GameMode.classic,
      tokensToWin: 4,
      killRequiredToEnterHome: false,
      initialDeployedTokens: 0,
      movement: const MovementRules(),
      capture: CaptureRules(board),
      win: const WinRules(tokensToWin: 4),
      turn: const TurnRules(),
    );
  }

  /// Quick Mode (Ludo King): 2 tokens start on track, 1 token to win, kill required to enter home corridor.
  factory RuleSet.quick(BoardState board) {
    return RuleSet._(
      mode: GameMode.quick,
      tokensToWin: 1,
      killRequiredToEnterHome: true,
      initialDeployedTokens: 2,
      movement: const MovementRules(),
      capture: CaptureRules(board),
      win: const WinRules(tokensToWin: 1),
      turn: const TurnRules(),
    );
  }
}
