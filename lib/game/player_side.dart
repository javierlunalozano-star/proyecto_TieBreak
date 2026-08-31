import 'puzzle_board.dart';
import 'rally_sequence.dart';

class PlayerSide {
  PlayerSide({required this.name})
    : board = PuzzleBoard(),
      rally = RallySequence();

  final String name;
  final PuzzleBoard board;
  RallySequence rally;
  int score = 0;
  int? selectedIndex;
  SequenceOutcome? lastOutcome;

  void onSetupTap(int index) {
    if (index == PuzzleBoard.benchIndex || board.slotHasLibero(index)) {
      return;
    }
    if (selectedIndex == null) {
      selectedIndex = index;
    } else if (selectedIndex == index) {
      selectedIndex = null;
    } else {
      board.trySwapSlotsWithoutLibero(selectedIndex!, index);
      selectedIndex = null;
    }
  }

  void onSubstitutionTap(int index) {
    board.tryLiberoSubstitution(index);
  }

  SequenceOutcome? tryPlayMove(int index) {
    if (index == PuzzleBoard.benchIndex) return null;
    if (board.cells[index] == null || !board.isAdjacentToEmpty(index)) {
      return null;
    }
    final expected = rally.expected;
    final ok = board.countsAs(index, expected);
    final moved = board.trySlide(index);
    if (moved == null) return null;
    if (moved.isExhausted) {
      lastOutcome = SequenceOutcome.overuse;
      rally = RallySequence();
      return lastOutcome;
    }
    moved.useCount++;
    lastOutcome = rally.play(
      ok ? expected : moved.kind,
      tileId: moved.id,
    );
    return lastOutcome;
  }

  void prepareRally() {
    selectedIndex = null;
    lastOutcome = null;
    rally = RallySequence();
  }
}
