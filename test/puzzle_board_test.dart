import 'package:flutter_test/flutter_test.dart';
import 'package:tiebreakvolleyball/game/puzzle_board.dart';
import 'package:tiebreakvolleyball/game/tile_kind.dart';

void main() {
  test('tablero inicial tiene 15 fichas en cancha, hueco y líbero en banquillo', () {
    final board = PuzzleBoard();
    expect(board.cells.length, 16);
    expect(board.cells.where((c) => c != null).length, 15);
    expect(board.emptyIndex, 15);
    expect(board.bench.kind, TileKind.libero);

    for (final kind in PuzzleBoard.courtKinds) {
      expect(
        board.cells.where((c) => c?.kind == kind).length,
        PuzzleBoard.tilesPerKind,
      );
    }
  });

  test('solo desliza fichas adyacentes al hueco', () {
    final board = PuzzleBoard();
    expect(board.trySlide(0), isNull);
    final sliding = board.cells[14];
    expect(board.trySlide(14), sliding);
    expect(board.emptyIndex, 14);
    expect(board.cells[15], sliding);
  });

  test('intercambia dos casillas, incluido el hueco', () {
    final board = PuzzleBoard();
    final first = board.cells[0];
    expect(board.trySwap(0, 15), isTrue);
    expect(board.cells[0], isNull);
    expect(board.cells[15], first);
    expect(board.trySwap(0, 0), isFalse);
  });

  test('el banquillo intercambia con una ficha, no con el hueco', () {
    final board = PuzzleBoard();
    final courtTile = board.cells[0]!;
    expect(board.trySwapWithBench(15), isFalse);
    expect(board.emptyIndex, 15);
    expect(board.bench.kind, TileKind.libero);

    expect(board.trySwapWithBench(0), isTrue);
    expect(board.cells[0]?.kind, TileKind.libero);
    expect(board.bench, courtTile);
    expect(board.cells.where((c) => c == null).length, 1);
  });

  test('en reorganización no se intercambia el líbero', () {
    final board = PuzzleBoard();
    expect(board.trySwapSlotsWithoutLibero(0, PuzzleBoard.benchIndex), isFalse);
    expect(board.bench.kind, TileKind.libero);
    expect(board.cells[0]?.kind, TileKind.defensa);
  });

  test('sustitución de líbero con banquillo o con ficha de cancha', () {
    final board = PuzzleBoard();
    expect(board.tryLiberoSubstitution(PuzzleBoard.benchIndex), isFalse);
    expect(board.tryLiberoSubstitution(0), isTrue);
    expect(board.cells[0]?.kind, TileKind.libero);
    expect(board.bench.kind, TileKind.defensa);

    expect(board.tryLiberoSubstitution(PuzzleBoard.benchIndex), isTrue);
    expect(board.bench.kind, TileKind.libero);
    expect(board.cells[0]?.kind, TileKind.defensa);
  });

  test('zona del líbero es su casilla y las adyacentes por lado', () {
    final board = PuzzleBoard();
    expect(board.liberoIndex, -1);
    expect(board.isLiberoZone(0), isFalse);

    expect(board.trySwapWithBench(0), isTrue);
    expect(board.liberoIndex, 0);
    expect(board.isLiberoZone(0), isTrue);
    expect(board.isLiberoZone(1), isTrue);
    expect(board.isLiberoZone(4), isTrue);
    expect(board.isLiberoZone(2), isFalse);
    expect(board.isLiberoZone(5), isFalse);
  });

  test('el hueco adyacente al líbero no se colorea', () {
    final board = PuzzleBoard();
    expect(board.trySwapWithBench(14), isTrue);
    expect(board.liberoIndex, 14);
    expect(board.emptyIndex, 15);
    expect(board.isAdjacent(14, 15), isTrue);
    expect(board.isLiberoZone(15), isFalse);
    expect(board.isLiberoZone(14), isTrue);
    expect(board.isLiberoZone(13), isTrue);
    expect(board.isLiberoZone(10), isTrue);
  });

  test('el líbero y su zona cuentan como defensa', () {
    final board = PuzzleBoard();
    expect(board.countsAs(0, TileKind.defensa), isTrue);
    expect(board.countsAs(14, TileKind.defensa), isFalse);

    expect(board.trySwapWithBench(10), isTrue);
    expect(board.cells[10]?.kind, TileKind.libero);
    expect(board.countsAs(10, TileKind.defensa), isTrue);
    expect(board.countsAs(14, TileKind.defensa), isTrue);
    expect(board.countsAs(14, TileKind.ataque), isTrue);
    expect(board.countsAs(11, TileKind.defensa), isTrue);
  });
}
