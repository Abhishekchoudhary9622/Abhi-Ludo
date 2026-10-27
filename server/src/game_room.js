const crypto = require('crypto');

const RING_CELL_COUNT = 52;
const FINISH_PROGRESS = 57;
const TURN_TIMEOUT_MS = 40000; // 40 seconds

class GameRoom {
  constructor(code, hostSocketId, hostName, mode = 'classic', maxPlayers = 4) {
    this.code = code;
    this.mode = mode; // 'classic' | 'quick'
    this.maxPlayers = maxPlayers;
    this.status = 'waiting'; // 'waiting' | 'in_progress' | 'won'
    this.winnerSeat = null;

    this.players = [
      {
        id: hostSocketId,
        name: hostName || 'Host',
        seat: 0,
        isHost: true,
        connected: true,
        kills: 0,
        tokens: this._createInitialTokens(0, mode),
      },
    ];

    this.turn = {
      currentSeat: 0,
      phase: 'awaiting_roll',
      consecutiveSixes: 0,
    };

    this.dice = {
      lastValue: null,
      rollsThisTurn: 0,
    };

    this.turnTimer = null;
    this.turnSecondsLeft = 40;
    this._onTurnTimeout = null; // Callback set by server.js
  }

  _createInitialTokens(seat, mode) {
    return Array.from({ length: 4 }, (_, i) => ({
      tokenId: i,
      ownerSeat: seat,
      progress: mode === 'quick' && i < 2 ? 0 : -1, // -1 means InBase, 0..57 means OnPath
    }));
  }

  addPlayer(socketId, name) {
    if (this.status !== 'waiting') return { error: 'Game already in progress' };
    if (this.players.length >= this.maxPlayers) return { error: 'Room is full' };

    // Prevent duplicate socket IDs
    const existing = this.players.find((p) => p.id === socketId);
    if (existing) {
      existing.connected = true;
      return { success: true, player: existing, reconnected: true };
    }

    const seat = this.players.length;
    const newPlayer = {
      id: socketId,
      name: name || `Player ${seat + 1}`,
      seat,
      isHost: false,
      connected: true,
      kills: 0,
      tokens: this._createInitialTokens(seat, this.mode),
    };

    this.players.push(newPlayer);
    return { success: true, player: newPlayer };
  }

  removePlayer(socketId) {
    const player = this.players.find((p) => p.id === socketId);
    if (!player) return null;

    if (this.status === 'waiting') {
      this.players = this.players.filter((p) => p.id !== socketId);
      // Re-index seats
      this.players.forEach((p, idx) => {
        p.seat = idx;
        if (idx === 0) p.isHost = true;
      });
      return { roomDeleted: this.players.length === 0 };
    } else {
      player.connected = false;
      // If it was this player's turn, auto-skip
      if (this.turn.currentSeat === player.seat) {
        this._clearTurnTimer();
        this._advanceTurn();
      }
      return { playerDisconnected: player };
    }
  }

  startGame(socketId) {
    const host = this.players.find((p) => p.isHost);
    if (!host || host.id !== socketId) return { error: 'Only the host can start the game' };
    if (this.players.length < 2) return { error: 'At least 2 players are required' };

    this.status = 'in_progress';
    this.turn.currentSeat = 0;
    this.turn.phase = 'awaiting_roll';
    this.turn.consecutiveSixes = 0;

    this._startTurnTimer();

    return { success: true };
  }

  rollDice(socketId) {
    if (this.status !== 'in_progress') return { error: 'Game not in progress' };
    const currentSeat = this.turn.currentSeat;
    const player = this.players[currentSeat];
    if (!player || player.id !== socketId) return { error: 'Not your turn' };
    if (this.turn.phase !== 'awaiting_roll') return { error: 'Not awaiting roll' };

    // 3rd consecutive 6 is capped to 1..5
    const allowSix = this.turn.consecutiveSixes < 2;
    const max = allowSix ? 6 : 5;
    const roll = (crypto.randomBytes(1)[0] % max) + 1;

    this.dice.lastValue = roll;
    this.dice.rollsThisTurn++;

    const legalTokenIds = this.getLegalMoves(currentSeat, roll);
    const hasLegalMove = legalTokenIds.length > 0;

    if (hasLegalMove) {
      this.turn.phase = 'awaiting_move';
      if (roll === 6) {
        this.turn.consecutiveSixes++;
      }
      // Reset turn timer for move phase
      this._startTurnTimer();
    } else {
      // Turn ends immediately if no moves available
      this._clearTurnTimer();
      this._advanceTurn();
      this._startTurnTimer();
    }

    return {
      success: true,
      roll,
      legalTokenIds,
      hasLegalMove,
      turn: this.turn,
    };
  }

  moveToken(socketId, tokenId) {
    if (this.status !== 'in_progress') return { error: 'Game not in progress' };
    const currentSeat = this.turn.currentSeat;
    const player = this.players[currentSeat];
    if (!player || player.id !== socketId) return { error: 'Not your turn' };
    if (this.turn.phase !== 'awaiting_move' || this.dice.lastValue === null) {
      return { error: 'Not awaiting move' };
    }

    const token = player.tokens.find((t) => t.tokenId === tokenId);
    if (!token) return { error: 'Token not found' };

    const roll = this.dice.lastValue;
    const legalMoves = this.getLegalMoves(currentSeat, roll);
    if (!legalMoves.includes(tokenId)) return { error: 'Illegal move' };

    // Apply move
    const wasInBase = token.progress === -1;
    const fromProgress = token.progress;
    const toProgress = wasInBase ? 0 : token.progress + roll;
    token.progress = toProgress;

    const reachedHome = toProgress === FINISH_PROGRESS;
    let capturedToken = null;

    // Resolve capture on non-safe ring cells
    if (toProgress <= 50) {
      const destinationRingIndex = this._getRingIndex(currentSeat, toProgress);
      if (!this._isSafeRingIndex(destinationRingIndex)) {
        for (const opp of this.players) {
          if (opp.seat === currentSeat) continue;
          for (const oppToken of opp.tokens) {
            if (oppToken.progress >= 0 && oppToken.progress <= 50) {
              const oppRingIndex = this._getRingIndex(opp.seat, oppToken.progress);
              if (oppRingIndex === destinationRingIndex) {
                // Captured!
                oppToken.progress = -1; // Send back to base
                player.kills++;
                capturedToken = {
                  ownerSeat: opp.seat,
                  tokenId: oppToken.tokenId,
                };
                break;
              }
            }
          }
          if (capturedToken) break;
        }
      }
    }

    // Check winner
    const tokensToWin = this.mode === 'quick' ? 1 : 4;
    const finishedCount = player.tokens.filter((t) => t.progress === FINISH_PROGRESS).length;
    if (finishedCount >= tokensToWin) {
      this.status = 'won';
      this.winnerSeat = currentSeat;
      this._clearTurnTimer();
      return {
        success: true,
        gameWon: true,
        winnerSeat: currentSeat,
        move: { seat: currentSeat, tokenId, fromProgress, toProgress, capturedToken },
      };
    }

    // Determine bonus roll
    let isBonus = false;
    let bonusReason = 'none';

    this._clearTurnTimer();

    if (reachedHome) {
      isBonus = true;
      bonusReason = 'reachedHome';
      this.turn.consecutiveSixes = 0;
      this.turn.phase = 'awaiting_roll';
    } else if (capturedToken) {
      isBonus = true;
      bonusReason = 'capturedOpponent';
      this.turn.consecutiveSixes = 0;
      this.turn.phase = 'awaiting_roll';
    } else if (roll === 6) {
      isBonus = true;
      bonusReason = 'rolledSix';
      this.turn.phase = 'awaiting_roll';
    } else {
      this._advanceTurn();
    }

    this._startTurnTimer();

    return {
      success: true,
      move: { seat: currentSeat, tokenId, fromProgress, toProgress, capturedToken },
      isBonus,
      bonusReason,
      turn: this.turn,
    };
  }

  getLegalMoves(seat, diceValue) {
    const player = this.players[seat];
    if (!player) return [];

    const killRequired = this.mode === 'quick';
    const hasKilled = player.kills > 0;
    const legal = [];

    for (const token of player.tokens) {
      if (token.progress === FINISH_PROGRESS) continue;
      if (token.progress === -1) {
        if (diceValue === 6) legal.push(token.tokenId);
        continue;
      }

      const dest = token.progress + diceValue;
      if (dest > FINISH_PROGRESS) continue;
      if (killRequired && !hasKilled && dest > 50) continue;

      legal.push(token.tokenId);
    }

    return legal;
  }

  _advanceTurn() {
    // Skip disconnected players
    let nextSeat = (this.turn.currentSeat + 1) % this.players.length;
    let attempts = 0;
    while (!this.players[nextSeat]?.connected && attempts < this.players.length) {
      nextSeat = (nextSeat + 1) % this.players.length;
      attempts++;
    }

    this.turn.currentSeat = nextSeat;
    this.turn.phase = 'awaiting_roll';
    this.turn.consecutiveSixes = 0;
    this.dice.lastValue = null;
    this.dice.rollsThisTurn = 0;
  }

  _startTurnTimer() {
    this._clearTurnTimer();
    this.turnSecondsLeft = 40;

    this.turnTimer = setTimeout(() => {
      // Auto-skip turn on timeout
      if (this.status === 'in_progress') {
        console.log(`[Turn Timeout] Room ${this.code}, seat ${this.turn.currentSeat} timed out`);
        this._advanceTurn();
        this._startTurnTimer();

        // Notify via callback (set by server.js)
        if (this._onTurnTimeout) {
          this._onTurnTimeout(this);
        }
      }
    }, TURN_TIMEOUT_MS);
  }

  _clearTurnTimer() {
    if (this.turnTimer) {
      clearTimeout(this.turnTimer);
      this.turnTimer = null;
    }
  }

  _getRingIndex(seat, progress) {
    const entryIndex = (seat * 13) % RING_CELL_COUNT;
    return (entryIndex + progress) % RING_CELL_COUNT;
  }

  _isSafeRingIndex(ringIndex) {
    // 4 starting cells (0, 13, 26, 39) + 4 star cells (8, 21, 34, 47)
    const safeCells = [0, 8, 13, 21, 26, 34, 39, 47];
    return safeCells.includes(ringIndex);
  }

  getStateSummary() {
    return {
      code: this.code,
      mode: this.mode,
      maxPlayers: this.maxPlayers,
      status: this.status,
      winnerSeat: this.winnerSeat,
      turnTimeoutMs: TURN_TIMEOUT_MS,
      players: this.players.map((p) => ({
        id: p.id,
        name: p.name,
        seat: p.seat,
        isHost: p.isHost,
        connected: p.connected,
        kills: p.kills,
        tokens: p.tokens,
      })),
      turn: this.turn,
      dice: this.dice,
    };
  }
}

module.exports = GameRoom;
