const GameRoom = require('./game_room');

class RoomManager {
  constructor() {
    this.rooms = new Map(); // code -> GameRoom
    this.socketToRoom = new Map(); // socketId -> code

    // Auto-cleanup empty rooms every 30 seconds
    this._cleanupInterval = setInterval(() => this._cleanupEmptyRooms(), 30000);
  }

  generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let code = '';
    do {
      code = '';
      for (let i = 0; i < 6; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
      }
    } while (this.rooms.has(code));
    return code;
  }

  createRoom(hostSocketId, hostName, mode, maxPlayers) {
    // If the socket is already in a room, leave it first
    const existingCode = this.socketToRoom.get(hostSocketId);
    if (existingCode) {
      this.handleDisconnect(hostSocketId);
    }

    const code = this.generateRoomCode();
    const room = new GameRoom(code, hostSocketId, hostName, mode, maxPlayers);
    this.rooms.set(code, room);
    this.socketToRoom.set(hostSocketId, code);
    return room;
  }

  getRoom(code) {
    if (!code || typeof code !== 'string') return null;
    return this.rooms.get(code.trim().toUpperCase());
  }

  getRoomBySocket(socketId) {
    const code = this.socketToRoom.get(socketId);
    return code ? this.rooms.get(code) : null;
  }

  joinRoom(code, socketId, playerName) {
    // Prevent duplicate: if this socket is already in a room, leave first
    const existingCode = this.socketToRoom.get(socketId);
    if (existingCode) {
      const existingRoom = this.rooms.get(existingCode);
      if (existingRoom) {
        // If trying to join the same room they're already in, return current state
        const normalizedCode = code.trim().toUpperCase();
        if (existingRoom.code === normalizedCode) {
          return { success: true, room: existingRoom, alreadyJoined: true };
        }
        // Otherwise leave the old room first
        this.handleDisconnect(socketId);
      }
    }

    const room = this.getRoom(code);
    if (!room) return { error: 'Room not found' };

    // Check if a player with this socket ID already exists in the room
    const existingPlayer = room.players.find((p) => p.id === socketId);
    if (existingPlayer) {
      existingPlayer.connected = true;
      this.socketToRoom.set(socketId, room.code);
      return { success: true, room, reconnected: true };
    }

    const result = room.addPlayer(socketId, playerName);
    if (result.success) {
      this.socketToRoom.set(socketId, room.code);
    }
    return result;
  }

  handleDisconnect(socketId) {
    const room = this.getRoomBySocket(socketId);
    if (!room) return null;

    this.socketToRoom.delete(socketId);
    const result = room.removePlayer(socketId);

    if (result?.roomDeleted) {
      this.rooms.delete(room.code);
    }

    return { room, result };
  }

  getActiveRoomCount() {
    return this.rooms.size;
  }

  /** Remove rooms where all players have disconnected or room is empty */
  _cleanupEmptyRooms() {
    for (const [code, room] of this.rooms.entries()) {
      if (room.players.length === 0) {
        console.log(`[Cleanup] Removing empty room ${code}`);
        this.rooms.delete(code);
        continue;
      }

      // If all players are disconnected and game is NOT in progress, clean up
      if (room.status === 'waiting') {
        const allDisconnected = room.players.every((p) => !p.connected);
        if (allDisconnected) {
          console.log(`[Cleanup] Removing room ${code} - all players disconnected`);
          // Clean up socketToRoom mappings
          for (const p of room.players) {
            this.socketToRoom.delete(p.id);
          }
          this.rooms.delete(code);
        }
      }
    }
  }
}

module.exports = new RoomManager();
