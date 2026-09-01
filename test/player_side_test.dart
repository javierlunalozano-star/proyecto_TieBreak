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

  test('usar una ficha con 4 usos es falta por agotamiento', () {
    final side = PlayerSide(name: 'A');
    side.prepareRally();
    expect(side.board.trySwap(4, 14), isTrue);
    final tile = side.board.cells[14]!;
    tile.useCount = 4;
    expect(side.tryPlayMove(14), SequenceOutcome.overuse);
    expect(tile.useCount, 4);
    expect(side.rally.expected, TileKind.defensa);
  });

  test('cada deslizamiento válido incrementa el contador de la ficha', () {
    final side = PlayerSide(name: 'A');
    side.prepareRally();
    expect(side.board.trySwap(4, 14), isTrue);
    final tile = side.board.cells[14]!;
    expect(tile.useCount, 0);
    expect(side.tryPlayMove(14), SequenceOutcome.progress);
    expect(tile.useCount, 1);
  });

  test('en cambio de líbero solo se permite un movimiento', () {
    final side = PlayerSide(name: 'A');
    expect(side.board.bench.kind, TileKind.libero);
    expect(side.onSubstitutionTap(0), isTrue);
    expect(side.ready, isTrue);
    expect(side.board.cells[0]?.kind, TileKind.libero);
    expect(side.onSubstitutionTap(0), isFalse);
    expect(side.board.cells[0]?.kind, TileKind.libero);
  });

  test('listo bloquea el cambio de líbero y no se puede deshacer', () {
    final side = PlayerSide(name: 'A');
    side.confirmReady();
    expect(side.ready, isTrue);
    side.confirmReady();
    expect(side.ready, isTrue);
    expect(side.onSubstitutionTap(0), isFalse);
    expect(side.board.bench.kind, TileKind.libero);
  });
}
