import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../core/audio/audio_service.dart';

/// Settings screen with sound toggles, interactive rulebook, and license information.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sfxEnabled = !AudioService.instance.isMuted;

  void _toggleSfx(bool value) {
    setState(() {
      _sfxEnabled = value;
      AudioService.instance.isMuted = !value;
    });
  }

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'How to Play Abhi Ludo',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _RuleSection(
                title: '🎲 Rolling & Moving',
                points: const [
                  'Roll a 6 to bring a pawn out of the yard onto your starting cell.',
                  'Rolling a 6 awards an extra roll after moving.',
                  'A maximum of 2 consecutive sixes can be rolled in a row (no 3rd six).',
                ],
              ),
              _RuleSection(
                title: '⚔️ Capture (Kill) Tactics',
                points: const [
                  'Landing on an opponent on an ordinary track square captures it, sending it back to base.',
                  'Capturing an opponent grants an IMMEDIATE bonus roll and resets your 6-chain counter!',
                ],
              ),
              _RuleSection(
                title: '⭐ Safe Star Squares',
                points: const [
                  '8 safe squares (4 starting arrows + 4 star squares) give complete capture immunity.',
                  'Multiple pawns can safely share star squares.',
                ],
              ),
              _RuleSection(
                title: '🏆 Game Modes',
                points: const [
                  'Classic Mode: All 4 pawns start in base; 4 pawns needed to win; free home entry.',
                  'Quick Mode: 2 pawns start deployed; 1 pawn to win; you MUST get at least 1 kill to unlock the home corridor!',
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Audio & Preferences',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                title: const Text('Sound Effects (SFX)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Dice rolls, token hops, captures'),
                value: _sfxEnabled,
                activeTrackColor: AppColors.accent,
                onChanged: _toggleSfx,
              ),

            ),
            const SizedBox(height: 28),
            Text(
              'Help & Support',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.menu_book_outlined, color: AppColors.accent),
                    title: const Text('How to Play & Rulebook', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showHowToPlay(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: Color(0xFF3A6EA5)),
                    title: const Text('About Abhi Ludo', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Version 1.0.0 • Pure Vector Ludo'),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Abhi Ludo',
                        applicationVersion: '1.0.0',
                        applicationLegalese: 'Open source under MIT License.\nFonts: Fredoka & Nunito (OFL 1.1)\nAudio: Kenney (CC0)',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleSection extends StatelessWidget {
  const _RuleSection({required this.title, required this.points});

  final String title;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          for (final pt in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      pt,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.ink.withValues(alpha: 0.8),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
