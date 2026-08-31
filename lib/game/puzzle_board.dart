import 'puzzle_tile.dart';
import 'tile_kind.dart';

/// Tablero 4x4 (15 fichas + hueco) y un banquillo con una ficha.
class PuzzleBoard {
  static const int size = 4;
  static const int cellCount = size * size;
  static const int tilesPerKind = 5;
  static const int benchIndex = -1;

  static const List<TileKind> courtKinds = [
    TileKind.defensa,
    TileKind.colocacion,
    TileKind.ataque,
  ];

  /// Fichas o `null` (hueco libre). Siempre hay exactamente un hueco.
  final List<PuzzleTile?> cells;

  /// Ficha en el banquillo. Nunca está vacío.
  PuzzleTile bench;

  PuzzleBoard({List<PuzzleTile?>? cells, PuzzleTile? bench})
    : cells = List<PuzzleTile?>.from(cells ?? _initialCourt()),
      bench = bench ?? const PuzzleTile(id: 15, kind: TileKind.libero) {
    assert(this.cells.length == cellCount);
    assert(this.cells.where((c) => c == null).length == 1);
  }

  static List<PuzzleTile?> _initialCourt() {
    final tiles = <PuzzleTile>[];
    var id = 0;
    for (final kind in courtKinds) {
      for (var i = 0; i < tilesPerKind; i++) {
        tiles.add(PuzzleTile(id: id++, kind: kind));
      }
    }
    return [...tiles, null];
  }

  int get emptyIndex => cells.indexOf(null);

  /// Índice del líbero en la cuadrícula, o `-1` si está en el banquillo.
  int get liberoIndex => cells.indexWhere((c) => c?.kind == TileKind.libero);

  bool isAdjacent(int a, int b) {
    final rowA = a ~/ size;
    final colA = a % size;
    final rowB = b ~/ size;
    final colB = b % size;
    return (rowA == rowB && (colA - colB).abs() == 1) ||
        (colA == colB && (rowA - rowB).abs() == 1);
  }

  bool isAdjacentToEmpty(int index) => isAdjacent(index, emptyIndex);

  /// Casilla del líbero y las ocupadas que comparten lado con ella.
  /// El hueco no forma parte de la zona.
  bool isLiberoZone(int index) {
    if (cells[index] == null) return false;
    final libero = liberoIndex;
    if (libero < 0) return false;
    return index == libero || isAdjacent(index, libero);
  }

  /// Si la ficha en [index] cuenta para el paso [expected] de la secuencia.
  /// El líbero y las fichas de su zona cuentan como defensa.
  bool countsAs(int index, TileKind expected) {
    final tile = cells[index];
    if (tile == null) return false;
    if (tile.kind == expected) return true;
    if (expected == TileKind.defensa) {
      return tile.kind == TileKind.libero || isLiberoZone(index);
    }
    return false;
  }

  /// Intercambia dos casillas de la cuadrícula (fichas o hueco).
  bool trySwap(int a, int b) {
    if (a == b) return false;
    final temp = cells[a];
    cells[a] = cells[b];
    cells[b] = temp;
    return true;
  }

  /// Intercambia una ficha de la cuadrícula con el banquillo.
  /// El hueco no puede salir de la cuadrícula.
  bool trySwapWithBench(int gridIndex) {
    if (gridIndex == benchIndex) return false;
    final tile = cells[gridIndex];
    if (tile == null) return false;
    cells[gridIndex] = bench;
    bench = tile;
    return true;
  }

  /// Intercambia dos casillas; [benchIndex] representa el banquillo.
  bool trySwapSlots(int a, int b) {
    if (a == b) return false;
    if (a == benchIndex) return trySwapWithBench(b);
    if (b == benchIndex) return trySwapWithBench(a);
    return trySwap(a, b);
  }

  bool slotHasLibero(int index) {
    if (index == benchIndex) return bench.kind == TileKind.libero;
    return cells[index]?.kind == TileKind.libero;
  }

  /// Reorganización: no se puede mover el líbero.
  bool trySwapSlotsWithoutLibero(int a, int b) {
    if (slotHasLibero(a) || slotHasLibero(b)) return false;
    return trySwapSlots(a, b);
  }

  /// Cambio de líbero con el banquillo, o del líbero en banquillo con una ficha de cancha.
  bool tryLiberoSubstitution(int index) {
    if (index == benchIndex) {
      final libero = liberoIndex;
      if (libero < 0) return false;
      return trySwapWithBench(libero);
    }
    final tile = cells[index];
    if (tile == null) return false;
    if (liberoIndex < 0) return trySwapWithBench(index);
    if (tile.kind == TileKind.libero) return trySwapWithBench(index);
    return false;
  }

  /// Mueve la ficha en [index] al hueco si es adyacente.
  /// Devuelve la ficha movida, o `null` si el movimiento no es válido.
  PuzzleTile? trySlide(int index) {
    if (index == benchIndex) return null;
    final tile = cells[index];
    if (tile == null || !isAdjacentToEmpty(index)) return null;
    final empty = emptyIndex;
    cells[empty] = tile;
    cells[index] = null;
    return tile;
  }
}
