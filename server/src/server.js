const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const roomManager = require('./room_manager');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

// Health check endpoint for cloud deployment (e.g. Render)
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'abhi-ludo-multiplayer',
    activeRooms: roomManager.getActiveRoomCount(),
    timestamp: Date.now(),
  });
});

io.on('connection', (socket) => {
  console.log(`[Socket Connected] ID: ${socket.id}`);

  // Create Room
  socket.on('create_room', ({ playerName, mode, maxPlayers }, callback) => {
    try {
      const room = roomManager.createRoom(socket.id, playerName, mode, maxPlayers);
      socket.join(room.code);

      // Set turn timeout callback for this room
      room._onTurnTimeout = (r) => {
        io.to(r.code).emit('turn_timeout', r.getStateSummary());
      };

      console.log(`[Room Created] Code: ${room.code} by ${playerName}`);
      callback({ success: true, room: room.getStateSummary() });
    } catch (e) {
      callback({ error: e.message });
    }
  });

  // Join Room
  socket.on('join_room', ({ roomCode, playerName }, callback) => {
    try {
      const result = roomManager.joinRoom(roomCode, socket.id, playerName);
      if (result.error) {
        return callback({ error: result.error });
      }

      const room = roomManager.getRoom(roomCode);
      socket.join(room.code);

      // Set turn timeout callback for this room
      room._onTurnTimeout = (r) => {
        io.to(r.code).emit('turn_timeout', r.getStateSummary());
      };

      console.log(`[Player Joined] ${playerName} joined room ${room.code}`);

      // Broadcast room update to all occupants
      io.to(room.code).emit('room_updated', room.getStateSummary());
      callback({ success: true, room: room.getStateSummary() });
    } catch (e) {
      callback({ error: e.message });
    }
  });

  // Start Game (Host only)
  socket.on('start_game', (callback) => {
    const room = roomManager.getRoomBySocket(socket.id);
    if (!room) return callback?.({ error: 'Room not found' });

    const result = room.startGame(socket.id);
    if (result.error) return callback?.({ error: result.error });

    console.log(`[Game Started] Room: ${room.code}`);
    io.to(room.code).emit('game_started', room.getStateSummary());
    callback?.({ success: true });
  });

  // Roll Dice
  socket.on('roll_dice', (callback) => {
    const room = roomManager.getRoomBySocket(socket.id);
    if (!room) return callback?.({ error: 'Room not found' });

    const result = room.rollDice(socket.id);
    if (result.error) return callback?.({ error: result.error });

    io.to(room.code).emit('dice_rolled', {
      roll: result.roll,
      legalTokenIds: result.legalTokenIds,
      hasLegalMove: result.hasLegalMove,
      room: room.getStateSummary(),
    });
    callback?.({ success: true, roll: result.roll });
  });

  // Move Token
  socket.on('move_token', ({ tokenId }, callback) => {
    const room = roomManager.getRoomBySocket(socket.id);
    if (!room) return callback?.({ error: 'Room not found' });

    const result = room.moveToken(socket.id, tokenId);
    if (result.error) return callback?.({ error: result.error });

    io.to(room.code).emit('token_moved', {
      move: result.move,
      isBonus: result.isBonus,
      bonusReason: result.bonusReason,
      gameWon: result.gameWon,
      winnerSeat: result.winnerSeat,
      room: room.getStateSummary(),
    });
    callback?.({ success: true });
  });

  // Chat / Emoji reaction
  socket.on('send_reaction', ({ emoji }) => {
    const room = roomManager.getRoomBySocket(socket.id);
    if (room) {
      io.to(room.code).emit('reaction_received', {
        socketId: socket.id,
        emoji,
      });
    }
  });

  // Disconnect
  socket.on('disconnect', () => {
    console.log(`[Socket Disconnected] ID: ${socket.id}`);
    const info = roomManager.handleDisconnect(socket.id);
    if (info?.room) {
      io.to(info.room.code).emit('room_updated', info.room.getStateSummary());
    }
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Abhi Ludo Multiplayer Server running on port ${PORT}`);
});
