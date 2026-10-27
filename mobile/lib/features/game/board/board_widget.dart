import 'package:flutter/material.dart';

import '../../../game/board/board_config.dart';
import 'board_layout.dart';
import 'board_painter.dart';

/// Square widget that renders the logical board and positions its
/// children (token widgets, supplied by the caller) on top, using the same
/// [BoardLayout] the painter uses — so painted cells and token widgets are
/// always aligned, no matter the board's on-screen size.
class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key, required this.tokenBuilder});

  /// Called once per grid cell size to build the positioned token layer.
  /// Receives the resolved cell size in logical pixels so callers can
  /// position/size token widgets consistently with the painted grid.
  final Widget Function(double cellSize) tokenBuilder;

  @override
  Widget build(BuildContext context) {
    const config = BoardConfig();
    const layout = BoardLayout();

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = constraints.maxWidth / BoardLayout.gridSize;
          return Stack(
            children: [
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: const BoardPainter(config: config, layout: layout),
              ),
              tokenBuilder(cellSize),
            ],
          );
        },
      ),
    );
  }
}
