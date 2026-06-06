import 'package:flutter/material.dart';
import 'package:tcc_flutter_mobile/pages/dashboard_screen/widgets/blocks.dart';

class ConnectionPainter extends CustomPainter {
  final LogicBlock from;
  final LogicBlock to;

  ConnectionPainter(this.from, this.to);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // centro do port de saída (dentro do bloco)
    final start = from.position + const Offset(140, 34);

    // centro do port de entrada (dentro do bloco)
    final end = to.position + const Offset(0, 34);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(start.dx + 50, start.dy, end.dx - 50, end.dy, end.dx, end.dy);

    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_) => true;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;

    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
