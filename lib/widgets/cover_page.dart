import 'package:flutter/material.dart';

import 'puzzle_grid.dart';

class CoverPage extends StatelessWidget {
  const CoverPage({super.key, required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF003D6B),
              CourtLook.blue,
              Color(0xFF002A4A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const Spacer(),
                const _CoverTitle(),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onPlay,
                    style: FilledButton.styleFrom(
                      backgroundColor: CourtLook.cell,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    child: const Text('JUGAR'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverTitle extends StatelessWidget {
  const _CoverTitle();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        children: [
          CustomPaint(
            painter: const _CourtBackdropPainter(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _OutlinedTitle(
                      text: 'TieBreak',
                      fontSize: 78,
                      strokeWidth: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _OutlinedTitle(
                      text: 'VOLLEYBALL',
                      fontSize: 34,
                      strokeWidth: 7,
                      letterSpacing: 6,
                      fill: CourtLook.cell,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinedTitle extends StatelessWidget {
  const _OutlinedTitle({
    required this.text,
    required this.fontSize,
    required this.strokeWidth,
    this.letterSpacing = 0,
    this.fill = Colors.white,
  });

  final String text;
  final double fontSize;
  final double strokeWidth;
  final double letterSpacing;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      letterSpacing: letterSpacing,
      height: 1,
    );
    return Stack(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = const Color(0xFF0A1A28),
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: base.copyWith(
            color: fill,
            shadows: const [
              Shadow(
                color: Color(0x99000000),
                offset: Offset(0, 8),
                blurRadius: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CourtBackdropPainter extends CustomPainter {
  const _CourtBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final court = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.12, size.width, size.height * 0.76),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      court,
      Paint()..color = CourtLook.cell.withValues(alpha: 0.35),
    );
    canvas.drawRRect(
      court,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    final midY = size.height / 2;
    canvas.drawLine(
      Offset(18, midY),
      Offset(size.width - 18, midY),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
