import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../core/audio/audio_service.dart';
import '../../core/stats/stats_repository.dart';
import '../online/online_lobby_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import 'bot_setup_screen.dart';
import 'mode_select_screen.dart';

const List<String> _avatars = ['🎲', '👑', '🦁', '🚀', '⭐', '🔥', '⚡', '🏆'];

/// Authentic Ludo King Main Menu Screen.
/// Features top VIP profile & currency bar, 3D glossy game mode cards,
/// daily fortune reward banner, and bottom navigation.
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final StatsRepository _stats = StatsRepository.instance;
  int _coins = 15000;
  int _gems = 50;

  void _claimDailyReward() {
    AudioService.instance.playCoinCollect();
    setState(() {
      _coins += 2500;
      _gems += 10;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF00A651),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Row(
          children: [
            Icon(Icons.stars, color: AppColors.gold),
            SizedBox(width: 10),
            Text(
              '🎉 Claimed +2,500 Coins & +10 Gems!',
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _avatars[_stats.avatarIndex % _avatars.length];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==========================================
              // 1. TOP VIP PROFILE & CURRENCY BAR
              // ==========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Profile Card
                  GestureDetector(
                    onTap: () {
                      AudioService.instance.playButtonPress();
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const ProfileScreen()))
                          .then((_) => setState(() {}));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.gold, width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [AppColors.goldLight, AppColors.goldDark]),
                            ),
                            child: Text(avatar, style: const TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _stats.playerName,
                                style: const TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                '⭐ VIP Level 5',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 10,
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Coins & Gems Badges
                  Row(
                    children: [
                      _CurrencyBadge(
                        icon: '🪙',
                        value: '$_coins',
                        color: const Color(0xFFFFA502),
                      ),
                      const SizedBox(width: 8),
                      _CurrencyBadge(
                        icon: '💎',
                        value: '$_gems',
                        color: const Color(0xFFFF4757),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.settings, color: AppColors.gold, size: 28),
                        onPressed: () {
                          AudioService.instance.playButtonPress();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==========================================
              // 2. HERO BRANDING & GAME TITLE
              // ==========================================
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        const Icon(Icons.military_tech, color: AppColors.gold, size: 36),
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text(
                            'ABHI LUDO',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontSize: 38,
                                  color: AppColors.goldLight,
                                  letterSpacing: 2.0,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'KING OF CLASSIC DICE BOARD GAMES',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==========================================
              // 3. DAILY FORTUNE REWARD BANNER
              // ==========================================
              GestureDetector(
                onTap: _claimDailyReward,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C194D), Color(0xFF5D24A6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                        ),
                        child: const Text('🎁', style: TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAILY LUCKY BONUS',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Tap to collect +2,500 Coins & 10 Gems!',
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA502)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'CLAIM',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            color: Color(0xFF2D1B00),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==========================================
              // 4. FOUR GLOSSY 3D GAME MODE CARDS
              // ==========================================
              // Mode 1: Play Online Multiplayer
              _GameMode3DCard(
                icon: Icons.public,
                emoji: '🌐',
                title: 'PLAY ONLINE',
                subtitle: 'Custom Rooms & Live Multiplayer',
                gradientColors: const [Color(0xFF6A11CB), Color(0xFF2575FC)],
                badgeText: 'HOT',
                badgeColor: const Color(0xFFFF4757),
                onTap: () {
                  AudioService.instance.playButtonPress();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OnlineLobbyScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Mode 2: Play Vs Computer
              _GameMode3DCard(
                icon: Icons.smart_toy,
                emoji: '🤖',
                title: 'VS COMPUTER',
                subtitle: 'Practice offline against smart AI bots',
                gradientColors: const [Color(0xFF00B09B), Color(0xFF96C93D)],
                badgeText: 'SOLO',
                badgeColor: const Color(0xFF00A651),
                onTap: () {
                  AudioService.instance.playButtonPress();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BotSetupScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Mode 3: Pass & Play
              _GameMode3DCard(
                icon: Icons.groups,
                emoji: '👥',
                title: 'PASS & PLAY',
                subtitle: '2–4 Players local on single device',
                gradientColors: const [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                badgeText: 'LOCAL',
                badgeColor: const Color(0xFFE52521),
                onTap: () {
                  AudioService.instance.playButtonPress();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ModeSelectScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Mode 4: Quick Rush Mode
              _GameMode3DCard(
                icon: Icons.bolt,
                emoji: '⚡',
                title: 'QUICK RUSH',
                subtitle: 'First pawn to reach home wins!',
                gradientColors: const [Color(0xFFF7971E), Color(0xFFFFD200)],
                badgeText: 'FAST',
                badgeColor: const Color(0xFFFFA502),
                onTap: () {
                  AudioService.instance.playButtonPress();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ModeSelectScreen()),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyBadge extends StatelessWidget {
  const _CurrencyBadge({
    required this.icon,
    required this.value,
    required this.color,
  });

  final String icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Fredoka',
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameMode3DCard extends StatelessWidget {
  const _GameMode3DCard({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.badgeText,
    required this.badgeColor,
    required this.onTap,
  });

  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final String badgeText;
  final Color badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(
              children: [
                // 3D Mode Icon Box
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 16),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                fontFamily: 'Fredoka',
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
