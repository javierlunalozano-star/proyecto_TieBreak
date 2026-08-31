import 'package:flutter/material.dart';

import 'puzzle_grid.dart';

/// Franja horizontal que simula la red sobre el azul de la pista.
class VolleyballNet extends StatelessWidget {
  const VolleyballNet({super.key, this.height = CourtLook.netHeight});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: const CustomPaint(
        painter: _NetPainter(),
      ),
    );
  }
}

class _NetPainter extends CustomPainter {
  const _NetPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = CourtLook.blue,
    );

    final tape = Paint()..color = Colors.white;
    final meshStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final post = Paint()..color = const Color(0xFF37474F);

    const tapeH = 3.5;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, tapeH), tape);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - tapeH, size.width, tapeH),
      tape,
    );

    const cell = 6.5;
    for (var x = 0.0; x <= size.width; x += cell) {
      canvas.drawLine(
        Offset(x, tapeH),
        Offset(x, size.height - tapeH),
        meshStroke,
      );
    }
    for (var y = tapeH; y <= size.height - tapeH; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), meshStroke);
    }

    canvas.drawRect(Rect.fromLTWH(0, 0, 3, size.height), post);
    canvas.drawRect(
      Rect.fromLTWH(size.width - 3, 0, 3, size.height),
      post,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
