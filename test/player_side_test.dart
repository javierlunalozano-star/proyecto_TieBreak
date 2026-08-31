import 'package:flutter_test/flutter_test.dart';
import 'package:tiebreakvolleyball/game/player_side.dart';
import 'package:tiebreakvolleyball/game/rally_sequence.dart';
import 'package:tiebreakvolleyball/game/tile_kind.dart';

void main() {
  test('deslizar ataque al inicio es falta', () {
    final side = PlayerSide(name: 'A');
    side.prepareRally();
    expect(side.board.cells[14]?.kind, TileKind.ataque);
    expect(side.tryPlayMove(14), SequenceOutcome.fault);
  });

  test('un ataque junto al líbero cuenta como defensa', () {
    final side = PlayerSide(name: 'A');
    side.prepareRally();
    expect(side.board.trySwapWithBench(10), isTrue);
    expect(side.tryPlayMove(14), SequenceOutcome.progress);
    expect(side.rally.expected, TileKind.colocacion);
  });

  test('deslizar la misma ficha dos veces seguidas es toque doble', () {
    final side = PlayerSide(name: 'A');
    side.prepareRally();
    expect(side.board.trySwap(4, 14), isTrue);
    expect(side.board.cells[14]?.kind, TileKind.defensa);
    expect(side.tryPlayMove(14), SequenceOutcome.progress);
    expect(side.tryPlayMove(15), SequenceOutcome.doubleTouch);
  });
}
