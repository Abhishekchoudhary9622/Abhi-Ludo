import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../game/board/board_config.dart';
import '../../../game/board/cell_id.dart';
import 'board_layout.dart';

/// Authentic Ludo King Custom Board Painter.
/// Renders a rich 2D game board with wooden frame, glossy yard arenas,
/// sunken pawn slots, metallic safe stars, direction arrows, and golden center crown.
class BoardPainter extends CustomPainter {
  final BoardConfig config;
  final BoardLayout layout;

  const BoardPainter({
    required this.config,
    required this.layout,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellSize = size.width / BoardLayout.gridSize;

    // 1. Draw outer wooden frame & drop shadow
    _drawBoardFrame(canvas, size);

    // 2. Draw 4 Corner Yards (Red, Green, Yellow, Blue)
    _drawCornerYards(canvas, size, cellSize);

    // 3. Draw 52 Path Tiles (White path + Home columns + Safe stars + Arrows)
    _drawPathTiles(canvas, size, cellSize);

    // 4. Draw Center 4-color Victory Triangle & Golden Crown
    _drawCenterHome(canvas, size, cellSize);
  }

  void _drawBoardFrame(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    // Outer dark wood shadow
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF1A0F08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12),
    );

    // Wood border base
    canvas.drawRRect(
      rrect,
      Paint()..color = const Color(0xFF4A2810),
    );

    // Inner gold bevel rim
    final innerRRect = rrect.deflate(3);
    canvas.drawRRect(
      innerRRect,
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Board background (clean parchment white)
    final boardRRect = rrect.deflate(5);
    canvas.drawRRect(
      boardRRect,
      Paint()..color = const Color(0xFFFAFAFA),
    );
  }

  void _drawCornerYards(Canvas canvas, Size size, double cellSize) {
    // 4 Yards: 6x6 cells in each corner
    for (int seat = 0; seat < 4; seat++) {
      final origin = layout.yardOrigin(seat);
      final yardRect = Rect.fromLTWH(
        origin.col * cellSize + 4,
        origin.row * cellSize + 4,
        cellSize * 6 - 8,
        cellSize * 6 - 8,
      );
      final yardRRect = RRect.fromRectAndRadius(yardRect, const Radius.circular(16));

      final baseColor = AppColors.playerColors[seat];
      final lightColor = AppColors.playerColorsLight[seat];
      final darkColor = AppColors.playerColorsDark[seat];

      // 1. Colored yard container with subtle gradient
      final yardGradient = LinearGradient(
        colors: [lightColor, baseColor, darkColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      canvas.drawRRect(
        yardRRect,
        Paint()..shader = yardGradient.createShader(yardRect),
      );

      // Yard border
      canvas.drawRRect(
        yardRRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // 2. Inner White Arena (rounded card in center of yard)
      final arenaRect = yardRect.deflate(cellSize * 0.75);
      final arenaRRect = RRect.fromRectAndRadius(arenaRect, const Radius.circular(14));

      // Arena drop shadow
      canvas.drawRRect(
        arenaRRect,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Arena white fill
      canvas.drawRRect(
        arenaRRect,
        Paint()..color = Colors.white,
      );

      // 3. Four Sunken Pawn Slots inside the arena
      for (int slot = 0; slot < 4; slot++) {
        final slotPos = layout.baseSlot(seat, slot);
        final center = Offset(
          (slotPos.col + 0.5) * cellSize,
          (slotPos.row + 0.5) * cellSize,
        );
        final radius = cellSize * 0.65;

        // Outer colored ring
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = baseColor.withValues(alpha: 0.85)
            ..style = PaintingStyle.fill,
        );

        // Inner white dish
        canvas.drawCircle(
          center,
          radius * 0.78,
          Paint()..color = const Color(0xFFF0F3F8),
        );

        // Inner shadow for 3D sunken hole effect
        final innerShadowGradient = RadialGradient(
          colors: [
            Colors.black.withValues(alpha: 0.25),
            Colors.transparent,
          ],
          stops: const [0.7, 1.0],
        );
        canvas.drawCircle(
          center,
          radius * 0.78,
          Paint()..shader = innerShadowGradient.createShader(Rect.fromCircle(center: center, radius: radius * 0.78)),
        );

        // Center colored dot
        canvas.drawCircle(
          center,
          radius * 0.32,
          Paint()..color = baseColor,
        );
      }
    }
  }

  void _drawPathTiles(Canvas canvas, Size size, double cellSize) {
    // 1. Regular 52 Ring Cells
    for (int index = 0; index < BoardConfig.ringSize; index++) {
      final pos = layout.positionOf(RingCell(index));
      final seat = index ~/ 13;
      final offsetInSeat = index % 13;
      final isStartTile = (offsetInSeat == 0); // 0, 13, 26, 39
      final isSafeTile = config.isSafeRingIndex(index);

      Color fillColor = const Color(0xFFFFFFFF);
      if (isStartTile) {
        fillColor = AppColors.playerColors[seat];
      }

      _drawSingleTile(
        canvas: canvas,
        pos: pos,
        cellSize: cellSize,
        fillColor: fillColor,
        isStartTile: isStartTile,
        seat: seat,
        isSafeStar: isSafeTile && !isStartTile,
      );
    }

    // 2. Home Run Columns (5 colored cells each)
    for (int seat = 0; seat < 4; seat++) {
      for (int lane = 0; lane < BoardConfig.homeLaneLength; lane++) {
        final pos = layout.positionOf(HomeLaneCell(seat, lane));
        _drawSingleTile(
          canvas: canvas,
          pos: pos,
          cellSize: cellSize,
          fillColor: AppColors.playerColors[seat],
          seat: seat,
          isHomeLane: true,
        );
      }
    }
  }

  void _drawSingleTile({
    required Canvas canvas,
    required GridPos pos,
    required double cellSize,
    required Color fillColor,
    bool isStartTile = false,
    bool isSafeStar = false,
    bool isHomeLane = false,
    int seat = 0,
  }) {
    final rect = Rect.fromLTWH(
      pos.col * cellSize + 0.5,
      pos.row * cellSize + 0.5,
      cellSize - 1.0,
      cellSize - 1.0,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    // Fill
    canvas.drawRRect(rrect, Paint()..color = fillColor);

    // Border
    final borderColor = (isStartTile || isHomeLane)
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFFD0D7DE);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Draw Arrow on Start Tile
    if (isStartTile) {
      _drawStartArrow(canvas, rect.center, cellSize * 0.38, seat);
    }

    // Draw Gold Star on Safe Cells
    if (isSafeStar) {
      _drawSafeStar(canvas, rect.center, cellSize * 0.40);
    }
  }

  void _drawStartArrow(Canvas canvas, Offset center, double size, int seat) {
    // Arrow pointing in the direction of path flow
    final path = Path();
    final half = size / 2;

    // Draw clean white arrow with shadow
    canvas.save();
    canvas.translate(center.dx, center.dy);
    
    // Rotate based on seat path direction
    // Seat 0 (Top-Left): points Down (angle pi/2)
    // Seat 1 (Top-Right): points Left (angle pi)
    // Seat 2 (Bottom-Right): points Up (angle -pi/2)
    // Seat 3 (Bottom-Left): points Right (angle 0)
    double angle = 0;
    switch (seat) {
      case 0: angle = math.pi / 2; break;
      case 1: angle = math.pi; break;
      case 2: angle = -math.pi / 2; break;
      case 3: angle = 0; break;
    }
    canvas.rotate(angle);

    path.moveTo(-half, -half * 0.7);
    path.lineTo(half * 0.6, 0);
    path.lineTo(-half, half * 0.7);
    path.lineTo(-half * 0.3, 0);
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  void _drawSafeStar(Canvas canvas, Offset center, double radius) {
    // 5-pointed golden star with drop shadow
    final path = Path();
    const points = 5;
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Shadow
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Star gold gradient
    final starGradient = const LinearGradient(
      colors: [Color(0xFFFFF0A0), Color(0xFFFFD700), Color(0xFFB8860B)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    canvas.drawPath(
      path,
      Paint()..shader = starGradient.createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // Star outline
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF8B6508)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _drawCenterHome(Canvas canvas, Size size, double cellSize) {
    final centerPos = layout.positionOf(const FinalHomeCell(0));
    final center = Offset(
      (centerPos.col + 0.5) * cellSize,
      (centerPos.row + 0.5) * cellSize,
    );
    final armRadius = cellSize * 1.5;

    // Draw 4 Center Triangles
    for (int seat = 0; seat < 4; seat++) {
      final path = Path();
      path.moveTo(center.dx, center.dy);

      switch (seat) {
        case 0: // Top-Left (Red)
          path.lineTo(center.dx - armRadius, center.dy - armRadius);
          path.lineTo(center.dx - armRadius, center.dy + armRadius);
          break;
        case 1: // Top-Right (Green)
          path.lineTo(center.dx - armRadius, center.dy - armRadius);
          path.lineTo(center.dx + armRadius, center.dy - armRadius);
          break;
        case 2: // Bottom-Right (Yellow)
          path.lineTo(center.dx + armRadius, center.dy - armRadius);
          path.lineTo(center.dx + armRadius, center.dy + armRadius);
          break;
        case 3: // Bottom-Left (Blue)
          path.lineTo(center.dx - armRadius, center.dy + armRadius);
          path.lineTo(center.dx + armRadius, center.dy + armRadius);
          break;
      }
      path.close();

      canvas.drawPath(
        path,
        Paint()..color = AppColors.playerColors[seat],
      );

      // Subtle divider line
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // Center Gold Medal / Crown Base
    final medalRadius = cellSize * 0.75;
    canvas.drawCircle(
      center,
      medalRadius,
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      medalRadius * 0.85,
      Paint()..color = const Color(0xFFFFD700),
    );

    // Crown Icon in Center
    _drawCrown(canvas, center, medalRadius * 0.5);
  }

  void _drawCrown(Canvas canvas, Offset center, double size) {
    final path = Path();
    final halfW = size * 0.9;
    final h = size * 0.7;
    final top = center.dy - h / 2;
    final bot = center.dy + h / 2;

    path.moveTo(center.dx - halfW, bot);
    path.lineTo(center.dx + halfW, bot);
    path.lineTo(center.dx + halfW, top + h * 0.3);
    path.lineTo(center.dx + halfW * 0.5, top + h * 0.7);
    path.lineTo(center.dx, top);
    path.lineTo(center.dx - halfW * 0.5, top + h * 0.7);
    path.lineTo(center.dx - halfW, top + h * 0.3);
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF5C3D00),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
