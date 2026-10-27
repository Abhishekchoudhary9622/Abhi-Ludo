import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dice/dice_providers.dart';
import '../rules/rule_set.dart';
import 'game_engine.dart';
import 'game_event.dart';
import 'game_factory.dart';
import 'game_state.dart';

/// The mode, player-count, and bot configuration for a match.
class MatchConfig {
  final GameMode mode;
  final int playerCount;
  final bool vsComputer;
  final List<bool>? isBotBySeat;

  const MatchConfig({
    required this.mode,
    required this.playerCount,
    this.vsComputer = false,
    this.isBotBySeat,
  });

  static const defaultConfig = MatchConfig(
    mode: GameMode.classic,
    playerCount: 4,
    vsComputer: false,
  );
}

/// Holds the pending match configuration.
class MatchConfigNotifier extends Notifier<MatchConfig> {
  @override
  MatchConfig build() => MatchConfig.defaultConfig;

  void set(MatchConfig config) => state = config;
}

final matchConfigProvider =
    NotifierProvider<MatchConfigNotifier, MatchConfig>(
      MatchConfigNotifier.new,
    );

/// Riverpod adapter over [GameEngine].
class GameNotifier extends Notifier<GameState> {
  late GameEngine _engine;

  GameEvent? lastEvent;

  GameEngine get engine => _engine;

  @override
  GameState build() {
    final config = ref.watch(matchConfigProvider);
    _engine = createGameEngine(
      mode: config.mode,
      dice: ref.watch(diceEngineProvider),
      playerCount: config.playerCount,
      isBotBySeat: config.isBotBySeat,
    );
    ref.onDispose(_engine.dispose);
    return _engine.state;
  }

  void rollDice() {
    lastEvent = _engine.rollDice();
    state = _engine.state;
  }

  void moveToken(int tokenId) {
    lastEvent = _engine.moveToken(tokenId);
    state = _engine.state;
  }

  /// Discards the current engine/state and starts a fresh match.
  void reset() {
    _engine.dispose();
    final config = ref.read(matchConfigProvider);
    _engine = createGameEngine(
      mode: config.mode,
      dice: ref.read(diceEngineProvider),
      playerCount: config.playerCount,
      isBotBySeat: config.isBotBySeat,
    );
    lastEvent = null;
    state = _engine.state;
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameState>(
  GameNotifier.new,
);
