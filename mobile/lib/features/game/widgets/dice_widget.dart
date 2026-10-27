import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../core/audio/audio_service.dart';

/// Authentic Ludo King 3D Dice Widget.
/// Includes 3D beveled ivory cube face, realistic tumbling roll animation,
/// active player glowing roll box, and special jackpot fanfare for rolling a 6.
class DiceWidget extends StatefulWidget {
  const DiceWidget({
    super.key,
    required this.value,
    required this.enabled,
    required this.onTap,
    this.playerSeat = 0,
  });

  final int? value;
  final bool enabled;
  final VoidCallback onTap;
  final int playerSeat;

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with TickerProviderStateMixin {
  late final AnimationController _rollController;
  late final AnimationController _pulseController;
  int? _displayValue;
  bool _isRolling = false;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value;

    // Roll animation controller (500ms multi-tumble)
    _rollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    // Pulse controller for "ROLL!" call-to-action
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    if (widget.enabled) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.enabled && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.enabled && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    if (widget.value != oldWidget.value && widget.value != null) {
      _triggerRollAnimation();
    }
  }

  void _triggerRollAnimation() {
    setState(() => _isRolling = true);
    _rollController.forward(from: 0).whenComplete(() {
      if (mounted) {
        setState(() {
          _displayValue = widget.value;
          _isRolling = false;
        });

        // Special 6 sound / fanfare
        if (widget.value == 6) {
          AudioService.instance.playDiceSix();
        }
      }
    });
  }

  @override
  void dispose() {
    _rollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seatColor = AppColors.playerColors[widget.playerSeat % 4];

    return GestureDetector(
      onTap: widget.enabled
          ? () {
              AudioService.instance.playDiceRoll();
              widget.onTap();
            }
          : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rollController, _pulseController]),
        builder: (context, child) {
          final rollProgress = _rollController.value;
          final pulseValue = _pulseController.value;

          // Scale & Rotation dynamics
          final scale = widget.enabled
              ? (1.0 + pulseValue * 0.08) - (math.sin(rollProgress * math.pi) * 0.22)
              : 0.95;
          final rotation = _isRolling ? math.sin(rollProgress * math.pi * 3.5) * 0.35 : 0.0;

          // Rapid pip shuffling during mid-tumble
          final shownValue = _isRolling && rollProgress > 0.1 && rollProgress < 0.85
              ? ((_displayValue ?? 1) + (rollProgress * 23).floor()) % 6 + 1
              : (_displayValue ?? widget.value ?? 1);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 3D Dice Box Container
              Transform.scale(
                scale: scale,
                child: Transform.rotate(
                  angle: rotation,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: widget.enabled
                          ? seatColor.withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.enabled
                            ? const Color(0xFFFFD700)
                            : Colors.white.withValues(alpha: 0.2),
                        width: widget.enabled ? 2.5 : 1.0,
                      ),
                      boxShadow: [
                        if (widget.enabled)
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: _DiceFace(
                      value: shownValue,
                      seatColor: seatColor,
                      enabled: widget.enabled,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // "ROLL!" badge when enabled
              if (widget.enabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA502)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'ROLL',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      color: Color(0xFF2D1B00),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 3D Ivory Die Face with rounded beveled edges, deep circular pips, and ambient shading
class _DiceFace extends StatelessWidget {
  const _DiceFace({
    required this.value,
    required this.seatColor,
    required this.enabled,
  });

  final int value;
  final Color seatColor;
  final bool enabled;

  static const Map<int, List<List<int>>> _pipLayouts = {
    1: [[1, 1]],
    2: [[0, 2], [2, 0]],
    3: [[0, 2], [1, 1], [2, 0]],
    4: [[0, 0], [0, 2], [2, 0], [2, 2]],
    5: [[0, 0], [0, 2], [1, 1], [2, 0], [2, 2]],
    6: [[0, 0], [0, 2], [1, 0], [1, 2], [2, 0], [2, 2]],
  };

  @override
  Widget build(BuildContext context) {
    final pips = _pipLayouts[value] ?? _pipLayouts[1]!;

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF7F4EB),
            Color(0xFFE5DECB),
          ],
          stops: [0.3, 0.75, 1.0],
          center: Alignment(-0.3, -0.3),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFC7BBA5),
          width: 2.0,
        ),
        boxShadow: [
          const BoxShadow(
            color: Colors.black45,
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
          // Inner light bevel highlight
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 2,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(9),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(9, (i) {
          final row = i ~/ 3;
          final col = i % 3;
          final hasPip = pips.any((p) => p[0] == row && p[1] == col);

          if (!hasPip) return const SizedBox.shrink();

          // 1 pip in center is classic red/seat color in Ludo King, others are deep charcoal
          final isSinglePip = (value == 1 && row == 1 && col == 1);
          final pipColor = isSinglePip ? const Color(0xFFE52521) : const Color(0xFF24292E);

          return Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    pipColor,
                    isSinglePip ? const Color(0xFF9E0B0F) : Colors.black,
                  ],
                  center: const Alignment(-0.2, -0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 1.5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
