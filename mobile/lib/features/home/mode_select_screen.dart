import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../game/rules/rule_set.dart';
import 'player_select_screen.dart';

/// Mode selection screen: Classic Mode vs Quick Mode (Ludo King Parity).
class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Game Mode'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose how you want to play',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _ModeCard(
                badge: 'TRADITIONAL',
                badgeColor: const Color(0xFF3A6EA5),
                title: 'Classic Mode',
                subtitle: 'Full strategic match with 4 tokens',
                rules: const [
                  'All 4 tokens start in yard',
                  'First to get all 4 tokens home wins',
                  'Free home corridor entrance',
                  'Bonus rolls on 6, captures & home arrivals',
                ],
                onTap: () => _selectMode(context, GameMode.classic),
              ),
              const SizedBox(height: 20),
              _ModeCard(
                badge: 'FAST PACED',
                badgeColor: const Color(0xFFFF5A5F),
                title: 'Quick Mode',
                subtitle: '5-10 minute rapid battle',
                rules: const [
                  '2 tokens start already deployed on track',
                  'First to get 1 token home wins',
                  '⚔️ Capture required to unlock home corridor',
                  'Bonus rolls on 6, captures & home arrivals',
                ],
                onTap: () => _selectMode(context, GameMode.quick),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectMode(BuildContext context, GameMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlayerSelectScreen(mode: mode)),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
    required this.rules,
    required this.onTap,
  });

  final String badge;
  final Color badgeColor;
  final String title;
  final String subtitle;
  final List<String> rules;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 2,
      shadowColor: AppColors.ink.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              for (final rule in rules)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          rule,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
