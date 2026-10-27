import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../game/engine/game_providers.dart';
import '../../game/rules/rule_set.dart';
import '../game/game_screen.dart';

/// Player-count selection (section 21, screen 4): 2-4 local players, per
/// section 1's requirement. Selecting a count sets [matchConfigProvider],
/// which `GameNotifier.build` reads when the game screen creates its
/// engine — this screen contains no rules logic itself.
class PlayerSelectScreen extends ConsumerWidget {
  const PlayerSelectScreen({super.key, required this.mode});

  final GameMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Local players')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('How many players (same device, pass-and-play)?'),
              const SizedBox(height: 20),
              for (final count in [2, 3, 4])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton(
                    onPressed: () => _startMatch(context, ref, count),
                    child: Text('$count Players'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _startMatch(BuildContext context, WidgetRef ref, int playerCount) {
    ref.read(matchConfigProvider.notifier).set(
      MatchConfig(mode: mode, playerCount: playerCount),
    );
    ref.invalidate(gameProvider);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }
}
