import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/audio/audio_service.dart';
import '../../game/engine/game_providers.dart';

/// Authentic Ludo King Pause Dialog.
void showPauseDialog(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.gold, width: 2),
      ),
      title: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pause_circle_filled, color: AppColors.gold, size: 28),
          SizedBox(width: 8),
          Text(
            'Game Paused',
            style: TextStyle(
              fontFamily: 'Fredoka',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: const Text(
        'Take a breather! Ready to get back in the action?',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.inkMuted, fontSize: 14),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowButtonSpacing: 10,
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A651),
            minimumSize: const Size(200, 44),
          ),
          onPressed: () {
            AudioService.instance.playButtonPress();
            Navigator.of(dialogContext).pop();
          },
          child: const Text('RESUME GAME', style: TextStyle(color: Colors.white)),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(200, 44),
            side: const BorderSide(color: AppColors.gold),
          ),
          onPressed: () {
            AudioService.instance.playButtonPress();
            ref.read(gameProvider.notifier).reset();
            Navigator.of(dialogContext).pop();
          },
          child: const Text('RESTART MATCH', style: TextStyle(color: AppColors.gold)),
        ),
        TextButton(
          onPressed: () {
            AudioService.instance.playButtonPress();
            Navigator.of(dialogContext).pop();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: const Text('QUIT TO MAIN MENU', style: TextStyle(color: Color(0xFFFF4757))),
        ),
      ],
    ),
  );
}
