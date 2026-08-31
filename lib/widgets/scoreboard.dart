import 'package:flutter/material.dart';

import 'puzzle_grid.dart';

/// Marcador LED horizontal, girado para leerse desde la izquierda de la pista.
class CourtScoreboard extends StatelessWidget {
  const CourtScoreboard({
    super.key,
    required this.leftScore,
    required this.rightScore,
  });

  final int leftScore;
  final int rightScore;

  static const double _thickness = 44;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CourtLook.netHeight,
      width: double.infinity,
      child: Center(
        child: RotatedBox(
          quarterTurns: 1,
          child: SizedBox(
            width: CourtLook.netHeight,
            height: _thickness,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF6D6D6D),
                    Color(0xFF2A2A2A),
                    Color(0xFF454545),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(color: const Color(0xFFB0B0B0), width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFF1F1F1F)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _ScoreLane(score: leftScore)),
                        const _Colon(),
                        Expanded(child: _ScoreLane(score: rightScore)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Colon extends StatelessWidget {
  const _Colon();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ColonDot(),
          _ColonDot(),
        ],
      ),
    );
  }
}

class _ColonDot extends StatelessWidget {
  const _ColonDot();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFFFF2A2A),
        shape: BoxShape.circle,
      ),
      child: SizedBox(width: 5, height: 5),
    );
  }
}

class _ScoreLane extends StatelessWidget {
  const _ScoreLane({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0, 99);
    final tens = clamped ~/ 10;
    final units = clamped % 10;
    return Row(
      children: [
        Expanded(child: _SevenSegment(digit: tens)),
        const SizedBox(width: 3),
        Expanded(child: _SevenSegment(digit: units)),
      ],
    );
  }
}

class _SevenSegment extends StatelessWidget {
  const _SevenSegment({required this.digit});

  final int digit;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SevenSegmentPainter(digit: digit),
      child: const SizedBox.expand(),
    );
  }
}

class _SevenSegmentPainter extends CustomPainter {
  const _SevenSegmentPainter({required this.digit});

  final int digit;

  static const _on = Color(0xFFFF2A2A);
  static const _off = Color(0xFF3A1010);

  /// A, B, C, D, E, F, G
  static const _patterns = <int, List<bool>>{
    0: [true, true, true, true, true, true, false],
    1: [false, true, true, false, false, false, false],
    2: [true, true, false, true, true, false, true],
    3: [true, true, true, true, false, false, true],
    4: [false, true, true, false, false, true, true],
    5: [true, false, true, true, false, true, true],
    6: [true, false, true, true, true, true, true],
    7: [true, true, true, false, false, false, false],
    8: [true, true, true, true, true, true, true],
    9: [true, true, true, true, false, true, true],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final segs = _patterns[digit] ?? _patterns[8]!;
    final t = (size.shortestSide * 0.16).clamp(2.2, 3.6);
    final inset = t * 0.55;
    final w = size.width;
    final h = size.height;
    final midY = h / 2;

    void hSeg(bool on, double y) {
      final path = Path()
        ..moveTo(inset + t, y)
        ..lineTo(w - inset - t, y)
        ..lineTo(w - inset - t * 0.35, y + t / 2)
        ..lineTo(w - inset - t, y + t)
        ..lineTo(inset + t, y + t)
        ..lineTo(inset + t * 0.35, y + t / 2)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = on ? _on : _off,
      );
    }

    void vSeg(bool on, double x, double y0, double y1) {
      final path = Path()
        ..moveTo(x, y0 + t * 0.35)
        ..lineTo(x + t / 2, y0)
        ..lineTo(x + t, y0 + t * 0.35)
        ..lineTo(x + t, y1 - t * 0.35)
        ..lineTo(x + t / 2, y1)
        ..lineTo(x, y1 - t * 0.35)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = on ? _on : _off,
      );
    }

    hSeg(segs[0], inset);
    vSeg(segs[1], w - inset - t, inset + t * 0.7, midY - t * 0.25);
    vSeg(segs[2], w - inset - t, midY + t * 0.25, h - inset - t * 0.7);
    hSeg(segs[3], h - inset - t);
    vSeg(segs[4], inset, midY + t * 0.25, h - inset - t * 0.7);
    vSeg(segs[5], inset, inset + t * 0.7, midY - t * 0.25);
    hSeg(segs[6], midY - t / 2);
  }

  @override
  bool shouldRepaint(covariant _SevenSegmentPainter oldDelegate) =>
      oldDelegate.digit != digit;
}
