const fs = require('fs');
const path = require('path');

const SAMPLE_RATE = 44100;

function createWavBuffer(samples) {
  const numChannels = 1;
  const bitsPerSample = 16;
  const byteRate = SAMPLE_RATE * numChannels * (bitsPerSample / 8);
  const blockAlign = numChannels * (bitsPerSample / 8);
  const dataSize = samples.length * (bitsPerSample / 8);
  const buffer = Buffer.alloc(44 + dataSize);

  // RIFF chunk
  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write('WAVE', 8);

  // fmt chunk
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16); // subchunk1 size
  buffer.writeUInt16LE(1, 20);  // PCM format
  buffer.writeUInt16LE(numChannels, 22);
  buffer.writeUInt32LE(SAMPLE_RATE, 24);
  buffer.writeUInt32LE(byteRate, 28);
  buffer.writeUInt16LE(blockAlign, 32);
  buffer.writeUInt16LE(bitsPerSample, 34);

  // data chunk
  buffer.write('data', 36);
  buffer.writeUInt32LE(dataSize, 40);

  // samples
  for (let i = 0; i < samples.length; i++) {
    const s = Math.max(-1, Math.min(1, samples[i]));
    const intVal = s < 0 ? s * 0x8000 : s * 0x7FFF;
    buffer.writeInt16LE(Math.floor(intVal), 44 + i * 2);
  }

  return buffer;
}

// 1. Crisp UI Button Click
function genButtonClick() {
  const duration = 0.08;
  const numSamples = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(numSamples);
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    const env = Math.exp(-t * 60);
    const freq = 1200 - t * 6000;
    const s = Math.sin(2 * Math.PI * freq * t) * env;
    samples[i] = s * 0.7;
  }
  return samples;
}

// 2. Realistic Dice Rolling / Shaking Rattle
function genDiceRoll() {
  const duration = 0.55;
  const numSamples = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(numSamples);
  
  // Multiple random taps/clicks simulating dice tumbling in cup/on board
  const taps = [0.02, 0.07, 0.12, 0.18, 0.23, 0.28, 0.34, 0.40, 0.46, 0.50];
  for (const tap of taps) {
    const tapSample = Math.floor(tap * SAMPLE_RATE);
    const tapLen = Math.floor(0.04 * SAMPLE_RATE);
    const freq = 200 + Math.random() * 350;
    for (let i = 0; i < tapLen && (tapSample + i) < numSamples; i++) {
      const t = i / SAMPLE_RATE;
      const env = Math.exp(-t * 80);
      const noise = (Math.random() * 2 - 1) * 0.3;
      const tone = Math.sin(2 * Math.PI * freq * t);
      samples[tapSample + i] += (tone + noise) * env * 0.45;
    }
  }
  return samples;
}

// 3. Glorious Dice Six / Jackpot Roll
function genDiceSix() {
  const duration = 0.6;
  const numSamples = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(numSamples);
  // Arpeggio C5 -> E5 -> G5 -> C6
  const notes = [523.25, 659.25, 783.99, 1046.50];
  const noteDuration = 0.12;

  for (let n = 0; n < notes.length; n++) {
    const start = Math.floor(n * noteDuration * SAMPLE_RATE);
    const len = Math.floor(0.25 * SAMPLE_RATE);
    const freq = notes[n];
    for (let i = 0; i < len && (start + i) < numSamples; i++) {
      const t = i / SAMPLE_RATE;
      const env = Math.exp(-t * 9);
      const s = (Math.sin(2 * Math.PI * freq * t) + 0.5 * Math.sin(2 * Math.PI * freq * 2 * t)) * env;
      samples[start + i] += s * 0.3;
    }
  }
  return samples;
}

// 4. Token Step Hop (Tactile marimba pop)
function genTokenStep() {
  const duration = 0.12;
  const numSamples = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(numSamples);
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    const env = Math.exp(-t * 35);
    const freq = 680 + Math.sin(t * 100) * 80;
    const s = Math.sin(2 * Math.PI * freq * t) * env;
    samples[i] = s * 0.8;
  }
  return samples;
}

// 5. Token Capture Smash Impact
function genTokenCapture() {
  const duration = 0.65;
  const numSamples = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(numSamples);
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    // Low bass punch + noise burst
    const punchEnv = Math.exp(-t * 15);
    const punch = Math.sin(2 * Math.PI * (180 - t * 240) * t) * punchEnv;
    const noiseEnv = Math.exp(-t * 22);
    const noise = (Math.random() * 2 - 1) * noiseEnv * 0.5;
    // Laser zap down
    const zapFreq = Math.max(80, 900 - t * 2000);
    const zap = Math.sin(2 * Math.PI * zapFreq * t) * Math.exp(-t * 8) * 0.4;
    samples[i] = (punch * 0.6 + noise + zap) * 0.8;
  }
  return samples;
}

// 6. Token Home Reach Chime
function genTokenHome() {
  const duration = 0.8;
  const numSamples = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(numSamples);
  const freqs = [587.33, 880.0, 1174.66]; // D5, A5, D6
  for (let f of freqs) {
    for (let i = 0; i < numSamples; i++) {
      const t = i / SAMPLE_RATE;
      const env = Math.exp(-t * 5);
      const s = Math.sin(2 * Math.PI * f * t) * env;
      samples[i] += s * 0.25;
    }
  }
  return samples;
}

// 7. Turn Warning Clock Tick
function genTimerTick() {
  const duration = 0.09;
  const numSamples = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(numSamples);
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    const env = Math.exp(-t * 80);
    const freq = 1800;
    const s = Math.sin(2 * Math.PI * freq * t) * env;
    samples[i] = s * 0.6;
  }
  return samples;
}

// 8. Win Fanfare
function genWinFanfare() {
  const duration = 1.6;
  const numSamples = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(numSamples);
  const melody = [
    { f: 523.25, start: 0.0, len: 0.18 }, // C5
    { f: 659.25, start: 0.18, len: 0.18 }, // E5
    { f: 783.99, start: 0.36, len: 0.18 }, // G5
    { f: 1046.50, start: 0.54, len: 0.5 }, // C6
    { f: 880.00, start: 1.05, len: 0.15 }, // A5
    { f: 1046.50, start: 1.20, len: 0.4 }, // C6
  ];
  for (const m of melody) {
    const startSample = Math.floor(m.start * SAMPLE_RATE);
    const lenSample = Math.floor(m.len * SAMPLE_RATE);
    for (let i = 0; i < lenSample && (startSample + i) < numSamples; i++) {
      const t = i / SAMPLE_RATE;
      const env = Math.exp(-t * 4.5);
      // Rich brass harmonic
      const s = (Math.sin(2 * Math.PI * m.f * t) + 0.4 * Math.sin(2 * Math.PI * m.f * 2 * t) + 0.2 * Math.sin(2 * Math.PI * m.f * 3 * t)) * env;
      samples[startSample + i] += s * 0.35;
    }
  }
  return samples;
}

// 9. Coin Collect
function genCoinCollect() {
  const duration = 0.35;
  const numSamples = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(numSamples);
  const f1 = 987.77; // B5
  const f2 = 1318.51; // E6
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    const env1 = t < 0.1 ? Math.exp(-t * 15) : 0;
    const env2 = t >= 0.08 ? Math.exp(-(t - 0.08) * 12) : 0;
    const s1 = Math.sin(2 * Math.PI * f1 * t) * env1;
    const s2 = Math.sin(2 * Math.PI * f2 * t) * env2;
    samples[i] = (s1 + s2) * 0.45;
  }
  return samples;
}

// Output directory
const outDir = path.join(__dirname, '..', 'mobile', 'assets', 'audio');
if (!fs.existsSync(outDir)) {
  fs.mkdirSync(outDir, { recursive: true });
}

const sfxMap = {
  'button_press.wav': genButtonClick(),
  'dice_roll.wav': genDiceRoll(),
  'dice_six.wav': genDiceSix(),
  'token_move.wav': genTokenStep(),
  'token_step.wav': genTokenStep(),
  'token_capture.wav': genTokenCapture(),
  'token_home.wav': genTokenHome(),
  'timer_tick.wav': genTimerTick(),
  'win.wav': genWinFanfare(),
  'turn_change.wav': genButtonClick(),
  'coin_collect.wav': genCoinCollect(),
};

for (const [filename, samples] of Object.entries(sfxMap)) {
  const buffer = createWavBuffer(samples);
  const target = path.join(outDir, filename);
  fs.writeFileSync(target, buffer);
  console.log(`Generated SFX: ${filename} (${buffer.length} bytes)`);
}

console.log('All SFX successfully generated!');
