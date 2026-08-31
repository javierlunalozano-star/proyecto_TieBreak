import 'package:flutter_test/flutter_test.dart';
import 'package:tiebreakvolleyball/game/rally_sequence.dart';
import 'package:tiebreakvolleyball/game/tile_kind.dart';

void main() {
  test('completa defensa, colocación y ataque', () {
    final rally = RallySequence();
    expect(rally.play(TileKind.defensa), SequenceOutcome.progress);
    expect(rally.play(TileKind.colocacion), SequenceOutcome.progress);
    expect(rally.play(TileKind.ataque), SequenceOutcome.completed);
    expect(rally.expected, TileKind.defensa);
  });

  test('un movimiento fuera de secuencia reinicia', () {
    final rally = RallySequence();
    rally.play(TileKind.defensa);
    expect(rally.play(TileKind.ataque), SequenceOutcome.fault);
    expect(rally.expected, TileKind.defensa);
  });

  test('la misma ficha dos veces seguidas es toque doble', () {
    final rally = RallySequence();
    expect(
      rally.play(TileKind.defensa, tileId: 4),
      SequenceOutcome.progress,
    );
    expect(
      rally.play(TileKind.colocacion, tileId: 4),
      SequenceOutcome.doubleTouch,
    );
    expect(rally.expected, TileKind.defensa);
  });

  test('fichas distintas pueden seguir la secuencia', () {
    final rally = RallySequence();
    expect(
      rally.play(TileKind.defensa, tileId: 1),
      SequenceOutcome.progress,
    );
    expect(
      rally.play(TileKind.colocacion, tileId: 7),
      SequenceOutcome.progress,
    );
    expect(
      rally.play(TileKind.ataque, tileId: 12),
      SequenceOutcome.completed,
    );
  });
}
