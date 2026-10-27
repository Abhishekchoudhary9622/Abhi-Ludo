import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import 'board_layout.dart';

/// Authentic Ludo King 3D Pawn Widget.
/// Features true 3D pawn silhouette (round head, sleek neck, flanged base, drop shadow),
/// energetic bouncing jump + golden aura when selectable, and smooth landing bounce.
class TokenWidget extends StatefulWidget {
  const TokenWidget({
    super.key,
    required this.seat,
    required this.gridPos,
    required this.cellSize,
    required this.selectable,
    this.clusterIndex = 0,
    this.clusterCount = 1,
    required this.onTap,
  });

  final int seat;
  final GridPos gridPos;
  final double cellSize;
  final bool selectable;
  final int clusterIndex;
  final int clusterCount;
  final VoidCallback? onTap;

  @override
  State<TokenWidget> createState() => _TokenWidgetState();
}

class _TokenWidgetState extends State<TokenWidget>
    with TickerProviderStateMixin {
  late AnimationController _jumpController;
  late Animation<double> _jumpAnimation;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  GridPos? _lastGridPos;

  @override
  void initState() {
    super.initState();

    // 1. Energetic bouncing hop when selectable (Ludo King style)
    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _jumpAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -16.0).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -16.0, end: 0.0).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 55,
      ),
    ]).animate(_jumpController);

    // 2. Pulsing golden aura glow
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _glowAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    if (widget.selectable) {
      _jumpController.repeat();
      _glowController.repeat(reverse: true);
    }

    _lastGridPos = widget.gridPos;
  }

  @override
  void didUpdateWidget(covariant TokenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectable && !_jumpController.isAnimating) {
      _jumpController.repeat();
      _glowController.repeat(reverse: true);
    } else if (!widget.selectable && _jumpController.isAnimating) {
      _jumpController.stop();
      _jumpController.reset();
      _glowController.stop();
      _glowController.reset();
    }

    // Trigger one hop on position move
    if (_lastGridPos != null &&
        (widget.gridPos.row != _lastGridPos!.row || widget.gridPos.col != _lastGridPos!.col)) {
      _lastGridPos = widget.gridPos;
      if (!widget.selectable) {
        _jumpController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _jumpController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double diameter;
    double offsetX = 0.0;
    double offsetY = 0.0;

    // Clustering logic for shared cells
    if (widget.clusterCount <= 1) {
      diameter = widget.cellSize * 0.90;
    } else if (widget.clusterCount == 2) {
      diameter = widget.cellSize * 0.72;
      offsetX = (widget.clusterIndex == 0 ? -0.16 : 0.16) * widget.cellSize;
    } else {
      diameter = widget.cellSize * 0.68;
      final idx = widget.clusterIndex % 4;
      offsetX = (idx % 2 == 0 ? -0.16 : 0.16) * widget.cellSize;
      offsetY = (idx ~/ 2 == 0 ? -0.16 : 0.16) * widget.cellSize;
    }

    final left = widget.gridPos.col * widget.cellSize +
        (widget.cellSize - diameter) / 2 +
        offsetX;
    final top = widget.gridPos.row * widget.cellSize +
        (widget.cellSize - diameter) / 2 +
        offsetY;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      left: left,
      top: top,
      width: diameter,
      height: diameter * 1.25, // Height taller for 3D standing pawn
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_jumpAnimation, _glowAnimation]),
          builder: (context, child) {
            final dy = widget.selectable ? _jumpAnimation.value : 0.0;
            final glowScale = widget.selectable ? _glowAnimation.value : 1.0;

            return Transform.translate(
              offset: Offset(0, dy),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // 1. Golden Aura Glow under pawn (when selectable)
                  if (widget.selectable)
                    Positioned(
                      bottom: 0,
                      child: Transform.scale(
                        scale: glowScale,
                        child: Container(
                          width: diameter * 1.1,
                          height: diameter * 0.45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.9),
                                blurRadius: 14,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 2. Realistic 3D Cast Shadow on board
                  Positioned(
                    bottom: 2,
                    child: Container(
                      width: diameter * 0.75,
                      height: diameter * 0.32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.45),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. True 3D Pawn Shape (Canvas rendering for crystal-clear pawn profile)
                  CustomPaint(
                    size: Size(diameter, diameter * 1.25),
                    painter: _Pawn3DPainter(
                      seat: widget.seat,
                      highlighted: widget.selectable,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom 3D Vector Pawn Painter that renders an authentic chess/Ludo pawn:
/// - Flanged base with metallic ring
/// - Tapered waist with glossy lighting
/// - Round spherical head with bright specular shine dot
class _Pawn3DPainter extends CustomPainter {
  final int seat;
  final bool highlighted;

  _Pawn3DPainter({required this.seat, required this.highlighted});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final baseColor = AppColors.playerColors[seat];
    final lightColor = AppColors.playerColorsLight[seat];
    final darkColor = AppColors.playerColorsDark[seat];

    // ==========================================
    // 1. BASE FLANGE (Bottom circular pedestal)
    // ==========================================
    final baseRect = Rect.fromCenter(
      center: Offset(cx, h - h * 0.16),
      width: w * 0.82,
      height: h * 0.30,
    );

    // Base gradient (Left highlight, right shadow)
    final baseGradient = LinearGradient(
      colors: [lightColor, baseColor, darkColor],
      stops: const [0.1, 0.45, 0.95],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    canvas.drawOval(baseRect, Paint()..shader = baseGradient.createShader(baseRect));

    // Base metallic rim highlight
    canvas.drawOval(
      baseRect,
      Paint()
        ..color = highlighted ? Colors.white : Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlighted ? 2.0 : 1.2,
    );

    // ==========================================
    // 2. TAPERED BODY CONE (Waist)
    // ==========================================
    final bodyPath = Path();
    final bodyTopY = h * 0.42;
    final bodyBotY = h - h * 0.22;
    final topHalfW = w * 0.22;
    final botHalfW = w * 0.36;

    bodyPath.moveTo(cx - topHalfW, bodyTopY);
    bodyPath.quadraticBezierTo(cx - topHalfW * 0.6, (bodyTopY + bodyBotY) / 2, cx - botHalfW, bodyBotY);
    bodyPath.lineTo(cx + botHalfW, bodyBotY);
    bodyPath.quadraticBezierTo(cx + topHalfW * 0.6, (bodyTopY + bodyBotY) / 2, cx + topHalfW, bodyTopY);
    bodyPath.close();

    final bodyRect = Rect.fromLTWH(cx - botHalfW, bodyTopY, botHalfW * 2, bodyBotY - bodyTopY);
    final bodyGradient = LinearGradient(
      colors: [lightColor, baseColor, darkColor],
      stops: const [0.15, 0.5, 0.95],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    canvas.drawPath(bodyPath, Paint()..shader = bodyGradient.createShader(bodyRect));

    // ==========================================
    // 3. COLLAR RING (Neck trim)
    // ==========================================
    final collarRect = Rect.fromCenter(
      center: Offset(cx, bodyTopY),
      width: w * 0.46,
      height: h * 0.10,
    );
    canvas.drawOval(
      collarRect,
      Paint()..color = lightColor,
    );
    canvas.drawOval(
      collarRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // ==========================================
    // 4. SPHERICAL HEAD (Glossy top ball)
    // ==========================================
    final headRadius = w * 0.26;
    final headCenter = Offset(cx, headRadius + h * 0.04);
    final headRect = Rect.fromCircle(center: headCenter, radius: headRadius);

    final headGradient = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: 0.95),
        lightColor,
        baseColor,
        darkColor,
      ],
      stops: const [0.0, 0.25, 0.65, 1.0],
      center: const Alignment(-0.35, -0.4),
      radius: 0.85,
    );
    canvas.drawCircle(
      headCenter,
      headRadius,
      Paint()..shader = headGradient.createShader(headRect),
    );

    // Outer head contour
    canvas.drawCircle(
      headCenter,
      headRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Specular Shine Dot (Gloss reflection on head)
    final shineCenter = Offset(cx - headRadius * 0.35, headCenter.dy - headRadius * 0.35);
    canvas.drawCircle(
      shineCenter,
      headRadius * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _Pawn3DPainter oldDelegate) =>
      oldDelegate.seat != seat || oldDelegate.highlighted != highlighted;
}
