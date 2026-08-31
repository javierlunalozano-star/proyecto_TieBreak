import 'tile_kind.dart';

class PuzzleTile {
  PuzzleTile({required this.id, required this.kind, this.useCount = 0});

  static const int maxUses = 4;

  final int id;
  final TileKind kind;
  int useCount;

  bool get isExhausted => useCount >= maxUses;
}
