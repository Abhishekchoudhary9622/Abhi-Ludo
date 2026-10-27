import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/audio/audio_service.dart';
import '../../game/ai/bot_controller.dart';
import '../../game/engine/game_event.dart';
import '../../game/engine/game_providers.dart';
import '../../game/engine/game_state.dart';
import '../../game/rules/rule_set.dart';
import '../../game/rules/turn_rules.dart';
import '../../game/state/player_state.dart';
import '../../game/state/token_state.dart';
import '../../game/state/turn_state.dart';
import 'board/board_layout.dart';
import 'board/board_widget.dart';
import 'board/token_widget.dart';
import 'pause_dialog.dart';
import 'widgets/dice_widget.dart';
import 'winner_screen.dart';

/// Authentic Ludo King In-Game Screen.
/// Features 4-corner player panels with animated 40s turn timer rings,
/// integrated corner dice boxes, bonus roll fanfare banners, and interactive emoji chat.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  static const _layout = BoardLayout();
  static const _bot = BotController();

  Timer? _autoMoveTimer;
  Timer? _botTimer;
  Timer? _turnTimer;
  int _turnSecondsLeft = 40;
  static const int _turnTimeLimit = 40;

  String? _bonusBannerText;
  Timer? _bannerTimer;

  // Floating Emoji Reaction state
  String? _activeEmoji;
  int? _emojiSeat;
  Timer? _emojiTimer;

  @override
  void initState() {
    super.initState();
    _startTurnTimer();
  }

  @override
  void dispose() {
    _autoMoveTimer?.cancel();
    _botTimer?.cancel();
    _turnTimer?.cancel();
    _bannerTimer?.cancel();
    _emojiTimer?.cancel();
    super.dispose();
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    setState(() => _turnSecondsLeft = _turnTimeLimit);

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final state = ref.read(gameProvider);
      if (state.status != GameStatus.inProgress) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_turnSecondsLeft > 0) {
          _turnSecondsLeft--;
          // Warning tick under 10 seconds
          if (_turnSecondsLeft <= 8 && _turnSecondsLeft > 0) {
            AudioService.instance.playTimerTick();
          }
        } else {
          // Timeout auto-action
          _handleTurnTimeout();
        }
      });
    });
  }

  void _handleTurnTimeout() {
    final notifier = ref.read(gameProvider.notifier);
    final state = notifier.engine.state;
    if (state.status != GameStatus.inProgress) return;

    if (state.turn.phase == TurnPhase.awaitingRoll) {
      AudioService.instance.playDiceRoll();
      notifier.rollDice();
    } else if (state.turn.phase == TurnPhase.awaitingMove) {
      final legal = notifier.engine.legalMovesForCurrentPlayer();
      if (legal.isNotEmpty) {
        AudioService.instance.playTokenStep();
        notifier.moveToken(legal.first);
      }
    }
  }

  void _showBonusBanner(String text) {
    _bannerTimer?.cancel();
    setState(() => _bonusBannerText = text);
    _bannerTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _bonusBannerText = null);
    });
  }

  void _triggerEmoji(int seat, String emoji) {
    _emojiTimer?.cancel();
    setState(() {
      _emojiSeat = seat;
      _activeEmoji = emoji;
    });
    AudioService.instance.playButtonPress();
    _emojiTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _activeEmoji = null);
    });
  }

  void _scheduleAutoMove(int tokenId) {
    _autoMoveTimer?.cancel();
    _autoMoveTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        final notifier = ref.read(gameProvider.notifier);
        final legalMoves = notifier.engine.legalMovesForCurrentPlayer();
        if (legalMoves.contains(tokenId)) {
          AudioService.instance.playTokenStep();
          notifier.moveToken(tokenId);
        }
      }
    });
  }

  void _handleBotTurn(GameState state) {
    if (state.status != GameStatus.inProgress) return;
    final currentPlayer = state.playerAt(state.turn.currentSeat);
    if (!currentPlayer.isBot) return;

    _botTimer?.cancel();

    if (state.turn.phase == TurnPhase.awaitingRoll) {
      _botTimer = Timer(const Duration(milliseconds: 750), () {
        if (mounted) {
          final notifier = ref.read(gameProvider.notifier);
          final current = notifier.engine.state;
          if (current.turn.phase == TurnPhase.awaitingRoll &&
              current.playerAt(current.turn.currentSeat).isBot) {
            AudioService.instance.playDiceRoll();
            notifier.rollDice();
          }
        }
      });
    } else if (state.turn.phase == TurnPhase.awaitingMove) {
      _botTimer = Timer(const Duration(milliseconds: 850), () {
        if (mounted) {
          final notifier = ref.read(gameProvider.notifier);
          final current = notifier.engine.state;
          if (current.turn.phase == TurnPhase.awaitingMove &&
              current.playerAt(current.turn.currentSeat).isBot) {
            final legalMoves = notifier.engine.legalMovesForCurrentPlayer();
            final bestMove = _bot.selectBestMove(
              state: current,
              engine: notifier.engine,
              botPlayer: currentPlayer,
              legalTokenIds: legalMoves,
              diceValue: current.dice.lastValue ?? 1,
            );

            if (bestMove >= 0) {
              AudioService.instance.playTokenStep();
              notifier.moveToken(bestMove);
            }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final legalMoves = notifier.engine.legalMovesForCurrentPlayer();
    final currentPlayer = gameState.playerAt(gameState.turn.currentSeat);

    ref.listen<GameState>(gameProvider, (previous, next) {
      // Reset turn timer on seat change or phase roll
      if (previous?.turn.currentSeat != next.turn.currentSeat ||
          (previous?.turn.phase != TurnPhase.awaitingRoll && next.turn.phase == TurnPhase.awaitingRoll)) {
        _startTurnTimer();
      }

      if (next.status == GameStatus.won && next.winnerSeat != null) {
        AudioService.instance.playWin();
        Future.microtask(() {
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => WinnerScreen(winnerSeat: next.winnerSeat!),
              ),
            );
          }
        });
      }

      // Last event sound & banner triggers
      final lastEvent = notifier.lastEvent;
      if (lastEvent is ExtraTurnGranted) {
        switch (lastEvent.reason) {
          case BonusRollReason.capturedOpponent:
            _showBonusBanner('⚔️ BONUS ROLL! Opponent Captured!');
            AudioService.instance.playTokenCapture();
            break;
          case BonusRollReason.reachedHome:
            _showBonusBanner('🏠 BONUS ROLL! Token Reached Home!');
            AudioService.instance.playTokenHome();
            break;
          case BonusRollReason.rolledSix:
            _showBonusBanner('🎲 BONUS ROLL! Rolled a 6!');
            AudioService.instance.playDiceSix();
            break;
          case BonusRollReason.none:
            break;
        }
      } else if (lastEvent is TokenCaptured) {
        AudioService.instance.playTokenCapture();
      }

      // Auto-move for single legal token
      if (!currentPlayer.isBot &&
          next.turn.phase == TurnPhase.awaitingMove &&
          legalMoves.length == 1) {
        _scheduleAutoMove(legalMoves.first);
      }

      _handleBotTurn(next);
    });

    // Compute cell clusters
    final Map<String, List<TokenState>> cellOccupancy = {};
    for (final player in gameState.players) {
      if (!player.isActive) continue;
      for (final token in player.tokens) {
        if (token.position is OnPath) {
          final progress = (token.position as OnPath).progress;
          final cell = gameState.board.pathForSeat(player.seat).cellAt(progress);
          final pos = _layout.positionOf(cell);
          final key = '${pos.row.toInt()}_${pos.col.toInt()}';
          cellOccupancy.putIfAbsent(key, () => []).add(token);
        }
      }
    }

    // Player positions at 4 corners:
    // Top-Left: Seat 0 (Red)
    // Top-Right: Seat 1 (Green)
    // Bottom-Left: Seat 3 (Blue)
    // Bottom-Right: Seat 2 (Yellow)
    final p0 = gameState.players.firstWhere((p) => p.seat == 0, orElse: () => gameState.players[0]);
    final p1 = gameState.players.length > 1 ? gameState.players.firstWhere((p) => p.seat == 1, orElse: () => gameState.players[0]) : null;
    final p2 = gameState.players.length > 2 ? gameState.players.firstWhere((p) => p.seat == 2, orElse: () => gameState.players[0]) : null;
    final p3 = gameState.players.length > 3 ? gameState.players.firstWhere((p) => p.seat == 3, orElse: () => gameState.players[0]) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // TOP HEADER BAR (Game title, Mode, Settings, Audio)
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back / Pause Button
                  IconButton(
                    icon: const Icon(Icons.pause_circle_filled, color: AppColors.gold, size: 30),
                    tooltip: 'Pause',
                    onPressed: () {
                      AudioService.instance.playButtonPress();
                      showPauseDialog(context, ref);
                    },
                  ),
                  // Title & Mode Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.goldDark, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events, color: AppColors.gold, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          gameState.mode == GameMode.quick ? 'ABHI LUDO • QUICK' : 'ABHI LUDO • CLASSIC',
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mute / Sound Toggle
                  IconButton(
                    icon: Icon(
                      AudioService.instance.isMuted ? Icons.volume_off : Icons.volume_up,
                      color: AppColors.gold,
                      size: 26,
                    ),
                    onPressed: () {
                      setState(() {
                        AudioService.instance.isMuted = !AudioService.instance.isMuted;
                      });
                      AudioService.instance.playButtonPress();
                    },
                  ),
                ],
              ),
            ),

            // Bonus Roll Fanfare Banner
            if (_bonusBannerText != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB800), Color(0xFFFF4757)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  _bonusBannerText!,
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // ==========================================
            // TOP PLAYERS ROW (Seat 0: Red, Seat 1: Green)
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top-Left Player (Seat 0: Red)
                  _PlayerCornerBox(
                    player: p0,
                    isCurrentTurn: gameState.turn.currentSeat == 0,
                    secondsLeft: _turnSecondsLeft,
                    totalSeconds: _turnTimeLimit,
                    showDice: gameState.turn.currentSeat == 0,
                    diceValue: gameState.dice.lastValue,
                    canRoll: !currentPlayer.isBot &&
                        gameState.turn.currentSeat == 0 &&
                        gameState.status == GameStatus.inProgress &&
                        gameState.turn.phase == TurnPhase.awaitingRoll,
                    onDiceTap: () {
                      _autoMoveTimer?.cancel();
                      notifier.rollDice();
                    },
                    onEmojiTap: () => _showEmojiPicker(0),
                    activeEmoji: _emojiSeat == 0 ? _activeEmoji : null,
                  ),

                  // Top-Right Player (Seat 1: Green)
                  if (p1 != null && p1.isActive)
                    _PlayerCornerBox(
                      player: p1,
                      isCurrentTurn: gameState.turn.currentSeat == 1,
                      secondsLeft: _turnSecondsLeft,
                      totalSeconds: _turnTimeLimit,
                      showDice: gameState.turn.currentSeat == 1,
                      diceValue: gameState.dice.lastValue,
                      canRoll: !currentPlayer.isBot &&
                          gameState.turn.currentSeat == 1 &&
                          gameState.status == GameStatus.inProgress &&
                          gameState.turn.phase == TurnPhase.awaitingRoll,
                      onDiceTap: () {
                        _autoMoveTimer?.cancel();
                        notifier.rollDice();
                      },
                      onEmojiTap: () => _showEmojiPicker(1),
                      activeEmoji: _emojiSeat == 1 ? _activeEmoji : null,
                    )
                  else
                    const SizedBox(width: 140),
                ],
              ),
            ),

            // ==========================================
            // CENTER LUDO BOARD
            // ==========================================
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  child: BoardWidget(
                    tokenBuilder: (cellSize) => Stack(
                      children: [
                        for (final player in gameState.players)
                          if (player.isActive)
                            for (final token in player.tokens)
                              _buildToken(
                                gameState: gameState,
                                player: player,
                                token: token,
                                cellSize: cellSize,
                                cellOccupancy: cellOccupancy,
                                legalMoves: legalMoves,
                                onMove: (tokenId) {
                                  if (!currentPlayer.isBot) {
                                    _autoMoveTimer?.cancel();
                                    AudioService.instance.playTokenStep();
                                    notifier.moveToken(tokenId);
                                  }
                                },
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ==========================================
            // BOTTOM PLAYERS ROW (Seat 3: Blue, Seat 2: Yellow)
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bottom-Left Player (Seat 3: Blue)
                  if (p3 != null && p3.isActive)
                    _PlayerCornerBox(
                      player: p3,
                      isCurrentTurn: gameState.turn.currentSeat == 3,
                      secondsLeft: _turnSecondsLeft,
                      totalSeconds: _turnTimeLimit,
                      showDice: gameState.turn.currentSeat == 3,
                      diceValue: gameState.dice.lastValue,
                      canRoll: !currentPlayer.isBot &&
                          gameState.turn.currentSeat == 3 &&
                          gameState.status == GameStatus.inProgress &&
                          gameState.turn.phase == TurnPhase.awaitingRoll,
                      onDiceTap: () {
                        _autoMoveTimer?.cancel();
                        notifier.rollDice();
                      },
                      onEmojiTap: () => _showEmojiPicker(3),
                      activeEmoji: _emojiSeat == 3 ? _activeEmoji : null,
                    )
                  else
                    const SizedBox(width: 140),

                  // Bottom-Right Player (Seat 2: Yellow)
                  if (p2 != null && p2.isActive)
                    _PlayerCornerBox(
                      player: p2,
                      isCurrentTurn: gameState.turn.currentSeat == 2,
                      secondsLeft: _turnSecondsLeft,
                      totalSeconds: _turnTimeLimit,
                      showDice: gameState.turn.currentSeat == 2,
                      diceValue: gameState.dice.lastValue,
                      canRoll: !currentPlayer.isBot &&
                          gameState.turn.currentSeat == 2 &&
                          gameState.status == GameStatus.inProgress &&
                          gameState.turn.phase == TurnPhase.awaitingRoll,
                      onDiceTap: () {
                        _autoMoveTimer?.cancel();
                        notifier.rollDice();
                      },
                      onEmojiTap: () => _showEmojiPicker(2),
                      activeEmoji: _emojiSeat == 2 ? _activeEmoji : null,
                    )
                  else
                    const SizedBox(width: 140),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker(int seat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final emojis = ['😂', '🔥', '👑', '👍', '😎', '😡', '🎲', '🏆', '⚡', '🎉'];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Send Reaction',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 14,
                children: emojis.map((e) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _triggerEmoji(seat, e);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToken({
    required GameState gameState,
    required PlayerState player,
    required TokenState token,
    required double cellSize,
    required Map<String, List<TokenState>> cellOccupancy,
    required List<int> legalMoves,
    required void Function(int tokenId) onMove,
  }) {
    final isCurrentSeat = player.seat == gameState.turn.currentSeat;
    final isSelectable = !player.isBot && isCurrentSeat && legalMoves.contains(token.tokenId);

    final GridPos gridPos;
    int clusterIndex = 0;
    int clusterCount = 1;

    if (token.position is InBase) {
      gridPos = _layout.baseSlot(player.seat, token.tokenId);
    } else {
      final progress = (token.position as OnPath).progress;
      final cell = gameState.board.pathForSeat(player.seat).cellAt(progress);
      gridPos = _layout.positionOf(cell);

      final key = '${gridPos.row.toInt()}_${gridPos.col.toInt()}';
      final cluster = cellOccupancy[key];
      if (cluster != null && cluster.length > 1) {
        clusterCount = cluster.length;
        clusterIndex = cluster.indexOf(token);
        if (clusterIndex < 0) clusterIndex = 0;
      }
    }

    return TokenWidget(
      key: ValueKey('token-${player.seat}-${token.tokenId}'),
      seat: player.seat,
      gridPos: gridPos,
      cellSize: cellSize,
      selectable: isSelectable,
      clusterIndex: clusterIndex,
      clusterCount: clusterCount,
      onTap: isSelectable ? () => onMove(token.tokenId) : null,
    );
  }
}

/// Authentic Ludo King Player Corner Box with Circular Countdown Ring,
/// Player Avatar, Home Status, and Integrated Interactive Dice Box.
class _PlayerCornerBox extends StatelessWidget {
  const _PlayerCornerBox({
    required this.player,
    required this.isCurrentTurn,
    required this.secondsLeft,
    required this.totalSeconds,
    required this.showDice,
    required this.diceValue,
    required this.canRoll,
    required this.onDiceTap,
    required this.onEmojiTap,
    this.activeEmoji,
  });

  final PlayerState player;
  final bool isCurrentTurn;
  final int secondsLeft;
  final int totalSeconds;
  final bool showDice;
  final int? diceValue;
  final bool canRoll;
  final VoidCallback onDiceTap;
  final VoidCallback onEmojiTap;
  final String? activeEmoji;

  @override
  Widget build(BuildContext context) {
    final seatColor = AppColors.playerColors[player.seat % 4];
    final finishedTokens = player.tokens.where((t) => t.isFinished).length;
    final progress = (secondsLeft / totalSeconds).clamp(0.0, 1.0);

    // Timer color changes from green -> yellow -> red
    final timerColor = progress > 0.5
        ? const Color(0xFF2ED573)
        : (progress > 0.25 ? const Color(0xFFFFA502) : const Color(0xFFFF4757));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentTurn
                ? AppColors.surfaceLight
                : AppColors.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCurrentTurn ? const Color(0xFFFFD700) : seatColor.withValues(alpha: 0.6),
              width: isCurrentTurn ? 2.5 : 1.5,
            ),
            boxShadow: [
              if (isCurrentTurn)
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Circular Avatar with 40s Countdown Ring
              Stack(
                alignment: Alignment.center,
                children: [
                  if (isCurrentTurn)
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3.5,
                        valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: seatColor,
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 4),
                      ],
                    ),
                    child: Center(
                      child: player.isBot
                          ? const Icon(Icons.smart_toy, size: 20, color: Colors.white)
                          : const Icon(Icons.person, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // 2. Player Info & Finished count
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    player.displayName,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      color: Colors.white,
                      fontWeight: isCurrentTurn ? FontWeight.bold : FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: seatColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🏠 $finishedTokens/4',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            color: AppColors.playerColorsLight[player.seat % 4],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // 3. Integrated 3D Dice Box
              DiceWidget(
                value: showDice ? diceValue : null,
                enabled: canRoll,
                onTap: onDiceTap,
                playerSeat: player.seat,
              ),
            ],
          ),
        ),

        // Floating Emoji Reaction Bubble
        if (activeEmoji != null)
          Positioned(
            top: -30,
            left: 10,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (context, val, child) => Transform.scale(scale: val, child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
                  ],
                ),
                child: Text(activeEmoji!, style: const TextStyle(fontSize: 22)),
              ),
            ),
          ),
      ],
    );
  }
}
