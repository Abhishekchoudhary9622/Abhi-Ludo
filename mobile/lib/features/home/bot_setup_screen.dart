import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../game/engine/game_providers.dart';
import '../../game/rules/rule_set.dart';
import '../game/game_screen.dart';

/// Configuration screen for single-player Vs Computer matches.
class BotSetupScreen extends ConsumerStatefulWidget {
  const BotSetupScreen({super.key});

  @override
  ConsumerState<BotSetupScreen> createState() => _BotSetupScreenState();
}

class _BotSetupScreenState extends ConsumerState<BotSetupScreen> {
  int _botCount = 3;
  GameMode _mode = GameMode.classic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Play Vs Computer'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Configure your AI practice match',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Text(
                'Select Game Mode',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SelectableCard(
                      title: 'Classic Mode',
                      subtitle: '4 tokens to win',
                      isSelected: _mode == GameMode.classic,
                      onTap: () => setState(() => _mode = GameMode.classic),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SelectableCard(
                      title: 'Quick Mode',
                      subtitle: '1 token + kill lock',
                      isSelected: _mode == GameMode.quick,
                      onTap: () => setState(() => _mode = GameMode.quick),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Number of AI Opponents',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (int bots = 1; bots <= 3; bots++) ...[
                    Expanded(
                      child: _SelectableCard(
                        title: '$bots Bot${bots > 1 ? 's' : ''}',
                        subtitle: '${bots + 1} Players total',
                        isSelected: _botCount == bots,
                        onTap: () => setState(() => _botCount = bots),
                      ),
                    ),
                    if (bots < 3) const SizedBox(width: 10),
                  ],
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _startBotMatch,
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text('Start Match vs AI'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _startBotMatch() {
    final totalPlayers = _botCount + 1;
    final isBotBySeat = List.generate(4, (seat) => seat > 0 && seat < totalPlayers);

    ref.read(matchConfigProvider.notifier).set(
          MatchConfig(
            mode: _mode,
            playerCount: totalPlayers,
            vsComputer: true,
            isBotBySeat: isBotBySeat,
          ),
        );

    ref.read(gameProvider.notifier).reset();

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.accent.withValues(alpha: 0.14)
          : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.accent : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSelected ? AppColors.accent : AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.ink.withValues(alpha: 0.65),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
