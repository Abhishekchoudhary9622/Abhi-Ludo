import '../board/board_config.dart';
import '../board/board_state.dart';
import '../dice/dice_engine.dart';
import '../rules/rule_set.dart';
import '../state/dice_state.dart';
import '../state/player_state.dart';
import '../state/token_state.dart';
import '../state/turn_state.dart';
import 'game_engine.dart';
import 'game_state.dart';

const _seatNames = ['Coral', 'Teal', 'Sunflower', 'Cobalt'];

/// Builds a fresh [GameEngine] for a new match.
GameEngine createGameEngine({
  required GameMode mode,
  required DiceEngine dice,
  int playerCount = 4,
  List<bool>? isBotBySeat,
  List<String>? customNames,
}) {
  assert(playerCount >= 2 && playerCount <= 4, 'playerCount must be 2..4');

  final board = BoardState();
  final rules = mode == GameMode.classic
      ? RuleSet.classic(board)
      : RuleSet.quick(board);

  final players = List.generate(
    BoardConfig.seatCount,
    (seat) {
      final isActive = seat < playerCount;
      final isBot = isBotBySeat != null && seat < isBotBySeat.length
          ? isBotBySeat[seat]
          : false;

      final defaultName = isBot ? 'Bot ${_seatNames[seat]}' : _seatNames[seat];
      final name = customNames != null && seat < customNames.length
          ? customNames[seat]
          : defaultName;

      // In Quick Mode, 2 tokens start deployed at progress 0
      final tokens = List.generate(
        4,
        (tokenId) {
          final isInitiallyDeployed = mode == GameMode.quick && tokenId < 2;
          return TokenState(
            tokenId: tokenId,
            ownerSeat: seat,
            position: isInitiallyDeployed ? const OnPath(0) : const InBase(),
          );
        },
      );

      return PlayerState(
        seat: seat,
        displayName: name,
        isActive: isActive,
        isBot: isBot,
        tokens: tokens,
      );
    },
  );

  final initialState = GameState(
    mode: mode,
    board: board,
    players: players,
    dice: const DiceState(),
    turn: const TurnState(currentSeat: 0),
  );

  return GameEngine(initialState, rules, dice);
}
