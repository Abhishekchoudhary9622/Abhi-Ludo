import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../core/stats/stats_repository.dart';
import '../../game/engine/game_providers.dart';
import '../../game/rules/rule_set.dart';
import '../../networking/socket_service.dart';
import '../game/game_screen.dart';

/// Online Lobby Screen for creating or joining real-time multiplayer rooms.
class OnlineLobbyScreen extends ConsumerStatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  ConsumerState<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends ConsumerState<OnlineLobbyScreen> {
  final SocketService _socket = SocketService.instance;
  final StatsRepository _stats = StatsRepository.instance;

  Map<String, dynamic>? _activeRoom;
  StreamSubscription? _roomSub;
  StreamSubscription? _gameStartedSub;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _socket.connect();

    _roomSub = _socket.onRoomUpdated.listen((roomData) {
      if (mounted) {
        setState(() {
          _activeRoom = roomData;
        });
      }
    });

    _gameStartedSub = _socket.onGameStarted.listen((roomData) {
      if (mounted) {
        final modeStr = roomData['mode'] == 'quick' ? GameMode.quick : GameMode.classic;
        final players = roomData['players'] as List<dynamic>? ?? [];

        ref.read(matchConfigProvider.notifier).set(
              MatchConfig(
                mode: modeStr,
                playerCount: players.length,
                vsComputer: false,
              ),
            );

        ref.read(gameProvider.notifier).reset();

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _gameStartedSub?.cancel();
    super.dispose();
  }

  void _showCreateRoomDialog() {
    String selectedMode = 'classic';
    int maxPlayers = 4;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Create Game Room', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Game Mode:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  ChoiceChip(
                    label: const Text('Classic'),
                    selected: selectedMode == 'classic',
                    selectedColor: AppColors.accent,
                    onSelected: (val) => setDialogState(() => selectedMode = 'classic'),
                  ),
                  ChoiceChip(
                    label: const Text('Quick Mode'),
                    selected: selectedMode == 'quick',
                    selectedColor: AppColors.accent,
                    onSelected: (val) => setDialogState(() => selectedMode = 'quick'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Max Players:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  for (int n in [2, 3, 4])
                    ChoiceChip(
                      label: Text('$n Players'),
                      selected: maxPlayers == n,
                      selectedColor: AppColors.accent,
                      onSelected: (val) => setDialogState(() => maxPlayers = n),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() => _isLoading = true);
                final res = await _socket.createRoom(
                  playerName: _stats.playerName,
                  mode: selectedMode,
                  maxPlayers: maxPlayers,
                );
                setState(() => _isLoading = false);

                if (res['success'] == true) {
                  setState(() => _activeRoom = res['room']);
                } else {
                  _showError(res['error'] ?? 'Failed to create room');
                }
              },
              child: const Text('Create Room'),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinRoomDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Join with Room Code', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: 'e.g. 7K9X2B',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.length == 6) {
                Navigator.of(context).pop();
                setState(() => _isLoading = true);
                final res = await _socket.joinRoom(
                  roomCode: code,
                  playerName: _stats.playerName,
                );
                setState(() => _isLoading = false);

                if (res['success'] == true) {
                  setState(() => _activeRoom = res['room']);
                } else {
                  _showError(res['error'] ?? 'Room not found or full');
                }
              }
            },
            child: const Text('Join Room'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activeRoom != null) {
      return _buildWaitingRoom(_activeRoom!);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Online Multiplayer'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.public, size: 54, color: AppColors.accent),
                          const SizedBox(height: 12),
                          Text(
                            'Play with Friends Online',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Create a private room or enter a 6-digit room code to join instantly.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.ink.withValues(alpha: 0.7),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Create Private Room'),
                      onPressed: _showCreateRoomDialog,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.vpn_key_outlined),
                      label: const Text('Join with Code'),
                      onPressed: _showJoinRoomDialog,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildWaitingRoom(Map<String, dynamic> room) {
    final code = room['code'] ?? '';
    final players = (room['players'] as List<dynamic>?) ?? [];
    final isHost = players.any((p) => p['id'] == _socket.socketId && p['isHost'] == true);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Room Lobby'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _activeRoom = null),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ROOM CODE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          code,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy Code',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Room code copied!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Players Joined (${players.length}/${room['maxPlayers'] ?? 4})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final p = players[index];
                    final seat = p['seat'] ?? index;
                    final color = AppColors.playerColors[seat % 4];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      color: AppColors.surface,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          radius: 16,
                        ),
                        title: Text(
                          p['name'] ?? 'Player',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: p['isHost'] == true
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'HOST',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                  ),
                                ),
                              )
                            : const Text('Ready', style: TextStyle(color: Color(0xFF2EC4B6), fontSize: 12)),
                      ),
                    );
                  },
                ),
              ),
              if (isHost) ...[
                ElevatedButton(
                  onPressed: players.length >= 2 ? () => _socket.startGame() : null,
                  child: Text(players.length >= 2 ? 'Start Game' : 'Waiting for players (min 2)...'),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Waiting for the host to start the game...',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
