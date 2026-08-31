import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/puzzle_board.dart';
import '../game/puzzle_tile.dart';
import '../game/tile_kind.dart';

class PuzzleCourt extends StatelessWidget {
  const PuzzleCourt({
    super.key,
    required this.board,
    required this.onCellTap,
    this.selectedIndex,
    this.inverted = false,
    this.showUseCount = false,
  });

  final PuzzleBoard board;
  final ValueChanged<int> onCellTap;
  final int? selectedIndex;
  final bool inverted;
  final bool showUseCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: PuzzleBoard.cellCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: PuzzleBoard.size,
        mainAxisSpacing: CourtLook.cellGap,
        crossAxisSpacing: CourtLook.cellGap,
      ),
      itemBuilder: (context, index) {
        final tile = board.cells[index];
        return _Cell(
          tile: tile,
          selected: selectedIndex == index,
          zone: board.isLiberoZone(index),
          inverted: inverted,
          showUseCount: showUseCount,
          onTap: () => onCellTap(index),
        );
      },
    );
  }
}

class PuzzleBench extends StatelessWidget {
  const PuzzleBench({
    super.key,
    required this.board,
    required this.onCellTap,
    this.selectedIndex,
    this.inverted = false,
    this.showUseCount = false,
  });

  final PuzzleBoard board;
  final ValueChanged<int> onCellTap;
  final int? selectedIndex;
  final bool inverted;
  final bool showUseCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = math.min(
          constraints.maxWidth * 0.55,
          math.min(constraints.maxHeight * 0.45, 72.0),
        );
        return Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RotatedBox(
                  quarterTurns: inverted ? 3 : 1,
                  child: Text(
                    'Banquillo',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: cell,
                  height: cell,
                  child: _Cell(
                    tile: board.bench,
                    selected: selectedIndex == PuzzleBoard.benchIndex,
                    zone: false,
                    inverted: inverted,
                    showUseCount: showUseCount,
                    onTap: () => onCellTap(PuzzleBoard.benchIndex),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.tile,
    required this.selected,
    required this.zone,
    required this.onTap,
    this.inverted = false,
    this.showUseCount = false,
  });

  final PuzzleTile? tile;
  final bool selected;
  final bool zone;
  final bool inverted;
  final bool showUseCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const radius = CourtLook.cellRadius;
    final background = zone ? TileLook.liberoZone : CourtLook.cell;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        hoverColor: CourtLook.cellHover,
        highlightColor: CourtLook.cellHover.withValues(alpha: 0.65),
        splashColor: CourtLook.cellHover.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: selected && tile == null
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  )
                : null,
          ),
          child: tile == null
              ? const SizedBox.expand()
              : Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.78,
                    heightFactor: 0.78,
                    child: _Token(
                      tile: tile!,
                      selected: selected,
                      inverted: inverted,
                      showUseCount: showUseCount,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _Token extends StatelessWidget {
  const _Token({
    required this.tile,
    required this.selected,
    this.inverted = false,
    this.showUseCount = false,
  });

  final PuzzleTile tile;
  final bool selected;
  final bool inverted;
  final bool showUseCount;

  @override
  Widget build(BuildContext context) {
    final look = TileLook.of(tile.kind);
    final exhausted = tile.isExhausted;
    return RotatedBox(
      quarterTurns: inverted ? 2 : 0,
      child: Material(
        color: look.color,
        elevation: selected ? 4 : 1,
        shape: const CircleBorder(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: selected
                ? Border.all(color: look.onColor, width: 3)
                : Border.all(color: Colors.black.withValues(alpha: 0.12)),
          ),
          child: Stack(
            children: [
              Center(
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      tile.kind.initials,
                      style: TextStyle(
                        color: look.onColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              if (showUseCount)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: _UseCountBadge(
                    count: tile.useCount,
                    exhausted: exhausted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UseCountBadge extends StatelessWidget {
  const _UseCountBadge({
    required this.count,
    required this.exhausted,
  });

  final int count;
  final bool exhausted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: exhausted ? const Color(0xFFC62828) : Colors.black.withValues(alpha: 0.72),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Apariencia por tipo. Al añadir un [TileKind], completar el `switch`.
class CourtLook {
  static const Color blue = Color(0xFF1B4F8A);
  static const Color cell = Color(0xFF16467C);
  static const Color cellHover = Color(0xFF2E6FB4);
  static const double lineWidth = 5;
  static const double netHeight = 96;
  static const double cellGap = 4;
  static const double cellRadius = 10;
}

class TileLook {
  const TileLook({
    required this.color,
    required this.onColor,
  });

  static const Color defense = Color(0xFF2E7D32);
  static const Color liberoZone = Color(0xFFA5D6A7);

  final Color color;
  final Color onColor;

  static TileLook of(TileKind kind) {
    return switch (kind) {
      TileKind.defensa => const TileLook(
        color: defense,
        onColor: Colors.white,
      ),
      TileKind.colocacion => const TileLook(
        color: Color(0xFFF9A825),
        onColor: Color(0xFF3E2723),
      ),
      TileKind.ataque => const TileLook(
        color: Color(0xFFC62828),
        onColor: Colors.white,
      ),
      TileKind.libero => const TileLook(
        color: Colors.white,
        onColor: defense,
      ),
    };
  }
}
