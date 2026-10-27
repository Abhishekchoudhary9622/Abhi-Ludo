import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Production-grade audio service for Abhi Ludo with player pooling,
/// low latency, and comprehensive game sound effects.
class AudioService {
  AudioService._() {
    _init();
  }

  static final AudioService instance = AudioService._();

  final List<AudioPlayer> _sfxPlayers = [];
  int _playerIndex = 0;
  static const int _poolSize = 5;

  bool isMuted = false;
  bool isSfxEnabled = true;

  void _init() {
    for (int i = 0; i < _poolSize; i++) {
      final player = AudioPlayer();
      player.setReleaseMode(ReleaseMode.stop);
      _sfxPlayers.add(player);
    }
  }

  AudioPlayer _getNextPlayer() {
    final player = _sfxPlayers[_playerIndex];
    _playerIndex = (_playerIndex + 1) % _poolSize;
    return player;
  }

  Future<void> _play(String assetPath, {double volume = 1.0}) async {
    if (isMuted || !isSfxEnabled) return;
    try {
      final player = _getNextPlayer();
      await player.stop();
      await player.setVolume(volume);
      await player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('AudioService error playing $assetPath: $e');
    }
  }

  /// Tactile button press on any menu, card, or modal button
  Future<void> playButtonPress() => _play('audio/button_press.wav', volume: 0.7);

  /// Realistic tumbling dice roll sound
  Future<void> playDiceRoll() => _play('audio/dice_roll.wav', volume: 1.0);

  /// Special joyful fanfare for rolling a 6 or jackpot
  Future<void> playDiceSix() => _play('audio/dice_six.wav', volume: 0.9);

  /// Tactile marimba hop per tile stepped
  Future<void> playTokenStep() => _play('audio/token_step.wav', volume: 0.75);

  /// Legacy alias
  Future<void> playTokenMove() => playTokenStep();

  /// Dramatic crash impact when capturing an opponent pawn
  Future<void> playTokenCapture() => _play('audio/token_capture.wav', volume: 1.0);

  /// Victory chime when a pawn safely enters the center home
  Future<void> playTokenHome() => _play('audio/token_home.wav', volume: 0.95);

  /// Warning clock tick when turn timer is running out (< 10s)
  Future<void> playTimerTick() => _play('audio/timer_tick.wav', volume: 0.6);

  /// Big victory fanfare when match is won
  Future<void> playWin() => _play('audio/win.wav', volume: 1.0);

  /// Coin reward / collect audio
  Future<void> playCoinCollect() => _play('audio/coin_collect.wav', volume: 0.85);

  /// Turn transition audio
  Future<void> playTurnChange() => _play('audio/turn_change.wav', volume: 0.5);

  void dispose() {
    for (final p in _sfxPlayers) {
      p.dispose();
    }
    _sfxPlayers.clear();
  }
}
