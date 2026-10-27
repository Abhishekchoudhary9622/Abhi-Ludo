import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/audio/audio_service.dart';
import '../../core/stats/stats_repository.dart';
import '../../game/engine/game_providers.dart';
import '../../game/rules/rule_set.dart';

/// Authentic Ludo King Victory Screen with Confetti particles,
/// Victory Fanfare audio, and Gold Coin Rewards.
class WinnerScreen extends ConsumerStatefulWidget {
  const WinnerScreen({super.key, required this.winnerSeat});

  final int winnerSeat;

  @override
  ConsumerState<WinnerScreen> createState() => _WinnerScreenState();
}

class _WinnerScreenState extends ConsumerState<WinnerScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(duration: const Duration(seconds: 6));
    _confettiController.play();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 10.0, end: 36.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService.instance.playWin();
      final gameState = ref.read(gameProvider);
      final humanPlayer = gameState.players.firstWhere(
        (p) => !p.isBot && p.isActive,
        orElse: () => gameState.players.first,
      );

      final won = humanPlayer.seat == widget.winnerSeat;
      StatsRepository.instance.recordMatch(
        won: won,
        killsInMatch: humanPlayer.kills,
      );
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final winnerPlayer = gameState.playerAt(widget.winnerSeat);
    final color = AppColors.playerColors[widget.winnerSeat % 4];

    final winDescription = gameState.mode == GameMode.quick
        ? 'First pawn reached home and won the rush!'
        : 'All 4 pawns conquered the board!';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Confetti Explosion
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: true,
                emissionFrequency: 0.06,
                numberOfParticles: 25,
                maxBlastForce: 40,
                minBlastForce: 15,
                gravity: 0.18,
                colors: const [
                  Color(0xFFFFD700),
                  Color(0xFFE52521),
                  Color(0xFF00A651),
                  Color(0xFF0072CE),
                  Color(0xFFFFB800),
                ],
              ),
            ),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing Victory Trophy
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) => Transform.scale(scale: value, child: child),
                      child: AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) => Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [color, color.withValues(alpha: 0.6)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                                blurRadius: _glowAnimation.value,
                                spreadRadius: _glowAnimation.value * 0.4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: Color(0xFFFFD700),
                            size: 84,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Winner Title
                    Text(
                      'VICTORY!',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 42,
                            letterSpacing: 2.5,
                            color: const Color(0xFFFFD700),
                          ),
                    ),

                    const SizedBox(height: 8),

                    // Player Name Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Text(
                        '👑 ${winnerPlayer.displayName} 👑',
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      winDescription,
                      style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
                    ),

                    const SizedBox(height: 24),

                    // Match Rewards Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold, width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🪙 +5,000 Coins', style: TextStyle(fontFamily: 'Fredoka', color: Color(0xFFFFA502), fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(width: 20),
                          Text('💎 +20 Gems', style: TextStyle(fontFamily: 'Fredoka', color: Color(0xFFFF4757), fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A651),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                          icon: const Icon(Icons.replay, color: Colors.white),
                          label: const Text('PLAY AGAIN', style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            AudioService.instance.playButtonPress();
                            ref.read(gameProvider.notifier).reset();
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.gold, width: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          icon: const Icon(Icons.home, color: AppColors.gold),
                          label: const Text('MAIN MENU', style: TextStyle(color: AppColors.gold)),
                          onPressed: () {
                            AudioService.instance.playButtonPress();
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
