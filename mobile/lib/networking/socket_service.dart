import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Singleton service managing real-time Socket.IO communication with the backend.
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  String serverUrl = 'http://192.168.1.9:3000'; // Network IP for physical device

  final _roomUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _gameStartedController = StreamController<Map<String, dynamic>>.broadcast();
  final _diceRolledController = StreamController<Map<String, dynamic>>.broadcast();
  final _tokenMovedController = StreamController<Map<String, dynamic>>.broadcast();
  final _reactionController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onRoomUpdated => _roomUpdateController.stream;
  Stream<Map<String, dynamic>> get onGameStarted => _gameStartedController.stream;
  Stream<Map<String, dynamic>> get onDiceRolled => _diceRolledController.stream;
  Stream<Map<String, dynamic>> get onTokenMoved => _tokenMovedController.stream;
  Stream<Map<String, dynamic>> get onReaction => _reactionController.stream;

  bool get isConnected => _socket?.connected ?? false;
  String? get socketId => _socket?.id;

  void connect([String? customUrl]) {
    if (customUrl != null && customUrl.isNotEmpty) {
      serverUrl = customUrl;
    }

    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[Socket Connected] Connected to $serverUrl');
    });

    _socket!.on('room_updated', (data) {
      if (data is Map<String, dynamic>) _roomUpdateController.add(data);
    });

    _socket!.on('game_started', (data) {
      if (data is Map<String, dynamic>) _gameStartedController.add(data);
    });

    _socket!.on('dice_rolled', (data) {
      if (data is Map<String, dynamic>) _diceRolledController.add(data);
    });

    _socket!.on('token_moved', (data) {
      if (data is Map<String, dynamic>) _tokenMovedController.add(data);
    });

    _socket!.on('reaction_received', (data) {
      if (data is Map<String, dynamic>) _reactionController.add(data);
    });

    _socket!.connect();
  }

  Future<Map<String, dynamic>> createRoom({
    required String playerName,
    required String mode,
    required int maxPlayers,
  }) {
    final completer = Completer<Map<String, dynamic>>();
    connect();

    _socket!.emitWithAck(
      'create_room',
      {'playerName': playerName, 'mode': mode, 'maxPlayers': maxPlayers},
      ack: (data) {
        if (data is Map<String, dynamic>) {
          completer.complete(data);
        } else {
          completer.complete({'error': 'Invalid response from server'});
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => {'error': 'Connection timed out'},
    );
  }

  Future<Map<String, dynamic>> joinRoom({
    required String roomCode,
    required String playerName,
  }) {
    final completer = Completer<Map<String, dynamic>>();
    connect();

    _socket!.emitWithAck(
      'join_room',
      {'roomCode': roomCode.trim().toUpperCase(), 'playerName': playerName},
      ack: (data) {
        if (data is Map<String, dynamic>) {
          completer.complete(data);
        } else {
          completer.complete({'error': 'Invalid response from server'});
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => {'error': 'Connection timed out'},
    );
  }

  void startGame() {
    _socket?.emit('start_game');
  }

  void rollDice() {
    _socket?.emit('roll_dice');
  }

  void moveToken(int tokenId) {
    _socket?.emit('move_token', {'tokenId': tokenId});
  }

  void sendReaction(String emoji) {
    _socket?.emit('send_reaction', {'emoji': emoji});
  }

  void disconnect() {
    _socket?.disconnect();
  }
}
