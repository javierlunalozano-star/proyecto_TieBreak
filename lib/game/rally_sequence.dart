import 'tile_kind.dart';

enum SequenceOutcome {
  /// El movimiento encaja y la secuencia sigue.
  progress,

  /// Defensa → colocación → ataque completados.
  completed,

  /// El movimiento no era el esperado.
  fault,

  /// La misma ficha se usó en dos toques consecutivos.
  doubleTouch,

  /// Se usó una ficha que ya había llegado a 4 usos.
  overuse;

  bool get awardsPointToOpponent =>
      this == SequenceOutcome.fault ||
      this == SequenceOutcome.doubleTouch ||
      this == SequenceOutcome.overuse;
}

/// Secuencia de juego: defensa, colocación, ataque.
class RallySequence {
  static const List<TileKind> steps = [
    TileKind.defensa,
    TileKind.colocacion,
    TileKind.ataque,
  ];

  int _index = 0;
  int? _lastTileId;

  TileKind get expected => steps[_index];

  int get currentStep => _index;

  SequenceOutcome play(TileKind kind, {int? tileId}) {
    if (tileId != null && tileId == _lastTileId) {
      _index = 0;
      _lastTileId = null;
      return SequenceOutcome.doubleTouch;
    }

    if (kind == expected) {
      _index++;
      _lastTileId = tileId;
      if (_index >= steps.length) {
        _index = 0;
        _lastTileId = null;
        return SequenceOutcome.completed;
      }
      return SequenceOutcome.progress;
    }

    _index = 0;
    _lastTileId = null;
    return SequenceOutcome.fault;
  }
}
