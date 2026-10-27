# Abhi Ludo — Multiplayer Server 🌐

The real-time online multiplayer game server for **Abhi Ludo**, built with **Node.js**, **Express**, and **Socket.IO**.

---

## ⚡ Features

- **6-Digit Room System:** Collision-free, human-friendly uppercase room codes (`roomManager`).
- **Real-Time WebSockets:** Low-latency bidirectional gameplay synchronization powered by Socket.IO.
- **Turn Timer Enforcement:** Automatic 15-second turn countdown with `turn_timeout` fallback.
- **Cloud Ready:** Native `/health` status endpoint for monitoring, pre-configured `Dockerfile` and `render.yaml`.
- **Match Lifecycle:** Full handling of lobby room creation, player joins, player leaves/disconnects, turn routing, dice rolls, and moves.

---

## 🛠 Quick Start

### Prerequisites
- Node.js 18+ (tested with Node 20 & 24)
- npm 9+

### Installation & Run

```bash
# Navigate to server directory
cd server

# Install dependencies
npm install

# Start production server
npm start

# Or run in development auto-reload mode
npm run dev
```

The server will bind to port `3000` (or `PORT` environment variable).

---

## 📡 REST API & Health Check

### Health Check Endpoint
```http
GET /health
```

#### Response Example
```json
{
  "status": "ok",
  "service": "abhi-ludo-multiplayer",
  "activeRooms": 2,
  "timestamp": 1793208000000
}
```

---

## 🔌 Socket.IO Events Protocol

### Client to Server (Emitters)

| Event | Payload | Description |
|---|---|---|
| `create_room` | `{ playerName, mode, maxPlayers }` | Create a new room with a 6-digit code. |
| `join_room` | `{ roomCode, playerName }` | Join an existing room via code. |
| `start_game` | `{ roomCode }` | Host starts the game once minimum players join. |
| `roll_dice` | `{ roomCode }` | Roll dice for the active player. |
| `move_token` | `{ roomCode, tokenId }` | Move selected token with current dice roll. |
| `leave_room` | `{ roomCode }` | Explicitly leave a room. |

### Server to Client (Listeners)

| Event | Payload | Description |
|---|---|---|
| `player_joined` | `{ room }` | Emitted when a new player joins the lobby. |
| `player_left` | `{ room, leftPlayerId }` | Emitted when a player leaves or disconnects. |
| `game_started` | `{ room }` | Match has begun; all clients transition to board. |
| `dice_rolled` | `{ room, rollValue, consecutiveSixes }` | Broadcasted dice result. |
| `token_moved` | `{ room, movedTokenId, targetCell, isCapture, isHome }` | Broadcasted token movement and capture resolution. |
| `turn_changed` | `{ room, activePlayerId }` | Emitted when turn switches to next player. |
| `turn_timeout` | `{ room }` | Emitted if player doesn't act within timeout window. |
| `game_over` | `{ room, winnerId, rankings }` | Emitted when winning conditions are met. |

---

## 🐳 Docker Deployment

```bash
# Build Docker image
docker build -t abhi-ludo-server .

# Run container on port 3000
docker run -p 3000:3000 -e PORT=3000 abhi-ludo-server
```

---

## ☁️ Deploy to Render

This repository includes a `render.yaml` blueprint. Simply link your GitHub repository to Render and deploy as a Web Service.
