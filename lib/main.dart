import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game/game_phase.dart';
import 'game/player_side.dart';
import 'game/puzzle_board.dart';
import 'game/rally_sequence.dart';
import 'widgets/puzzle_grid.dart';
import 'widgets/scoreboard.dart';
import 'widgets/volleyball_net.dart';

void main() {
  runApp(const TieBreakApp());
}

class TieBreakApp extends StatelessWidget {
  const TieBreakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TieBreak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const PuzzlePage(),
    );
  }
}

class PuzzlePage extends StatefulWidget {
  const PuzzlePage({super.key});

  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> {
  late final PlayerSide _opponent;
  late final PlayerSide _player;
  GamePhase _phase = GamePhase.setup;
  late PlayerSide _active;
  String? _sidelineMessage;
  PlayerSide? _plusOneSide;
  Timer? _plusOneTimer;

  @override
  void initState() {
    super.initState();
    final boards = PuzzleBoard.shuffledPair();
    _player = PlayerSide(name: 'Jugador 1', board: boards.$1);
    _opponent = PlayerSide(name: 'Jugador 2', board: boards.$2);
    _active = _player;
  }

  @override
  void dispose() {
    _plusOneTimer?.cancel();
    super.dispose();
  }

  PlayerSide _other(PlayerSide side) =>
      identical(side, _player) ? _opponent : _player;

  void _startSubstitution({required bool firstPlay}) {
    setState(() {
      if (firstPlay) {
        _opponent.prepareRally();
        _player.prepareRally();
        _active = _player;
      }
      _opponent.beginSubstitution();
      _player.beginSubstitution();
      _phase = GamePhase.substitution;
    });
  }

  void _confirmReady(PlayerSide side) {
    if (side.ready) return;
    setState(() {
      side.confirmReady();
      _advanceIfBothReady();
    });
  }

  void _advanceIfBothReady() {
    if (_player.ready && _opponent.ready) {
      _phase = GamePhase.play;
    }
  }

  void _onCellTap(PlayerSide side, int index) {
    if (_phase == GamePhase.setup) {
      setState(() => side.onSetupTap(index));
      return;
    }

    if (_phase == GamePhase.substitution) {
      setState(() {
        if (side.onSubstitutionTap(index)) {
          _advanceIfBothReady();
        }
      });
      return;
    }

    if (!identical(side, _active)) return;

    setState(() {
      final outcome = side.tryPlayMove(index);
      if (outcome == SequenceOutcome.completed) {
        _showSidelineMessage('Ataque del ${side.name}');
        _passTurn(side);
      } else if (outcome != null && outcome.awardsPointToOpponent) {
        final scorer = _other(side);
        scorer.score++;
        _showPlusOne(scorer);
        side.rally = RallySequence();
        _active = side;
        _opponent.beginSubstitution();
        _player.beginSubstitution();
        _phase = GamePhase.substitution;
      }
    });
  }

  void _showSidelineMessage(String text) {
    _sidelineMessage = text;
  }

  void _showPlusOne(PlayerSide side) {
    _plusOneTimer?.cancel();
    _plusOneSide = side;
    _plusOneTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _plusOneSide = null);
    });
  }

  void _passTurn(PlayerSide from) {
    _active = _other(from);
    _active.lastOutcome = null;
    _active.rally = RallySequence();
  }

  String get _instruction {
    return switch (_phase) {
      GamePhase.setup =>
        'Organiza las fichas de la cuadrícula. El líbero no se puede mover en esta fase.',
      GamePhase.substitution =>
        'Cambio de líbero: un único cambio o pulsa Listo. Esa decisión no se puede deshacer.',
      GamePhase.play =>
        'Completa Defensa → Colocación → Ataque para ceder el turno. Si fallas, usas la misma ficha dos veces seguidas o mueves una ficha que ya tiene 4 usos, el rival gana el punto.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isSetup = _phase == GamePhase.setup;
    final isPlay = _phase == GamePhase.play;
    final isSubstitution = _phase == GamePhase.substitution;
    return Scaffold(
      appBar: AppBar(
        title: const Text('TieBreak'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            children: [
              Text(
                _instruction,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: CourtLook.blue,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Column(
                      children: [
                        _PlayerHeader(
                          phase: _phase,
                          locked: isPlay && !identical(_active, _opponent),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const benchW = 108.0;
                              const benchGap = 8.0;
                              const msgW = 44.0;
                              const border = CourtLook.lineWidth;
                              const netH = CourtLook.netHeight;
                              final side = math.min(
                                constraints.maxWidth -
                                    benchW -
                                    benchGap -
                                    msgW -
                                    benchGap -
                                    2 * border,
                                (constraints.maxHeight - netH - 2 * border) / 2,
                              );
                              if (side <= 0) {
                                return const SizedBox.shrink();
                              }
                              final fieldH = 2 * side + netH + 2 * border;
                              final fieldW = side + 2 * border;
                              final scoreboardTop = border +
                                  side +
                                  netH / 2 -
                                  CourtLook.scoreboardBlockHeight / 2;
                              return Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: msgW,
                                      height: fieldH,
                                      child: _SidelineBoard(
                                        message: _sidelineMessage,
                                      ),
                                    ),
                                    const SizedBox(width: benchGap),
                                    SizedBox(
                                      width: fieldW,
                                      height: fieldH,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: CourtLook.cell,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: border,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(border),
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                width: side,
                                                height: side,
                                                child: Stack(
                                                  children: [
                                                    Positioned.fill(
                                                      child: _LockedBoard(
                                                      inverted: true,
                                                      locked: isPlay &&
                                                          !identical(
                                                            _active,
                                                            _opponent,
                                                          ),
                                                      frozen: isSubstitution &&
                                                          _opponent.ready,
                                                      child: PuzzleCourt(
                                                        board: _opponent.board,
                                                        inverted: true,
                                                        showUseCount: isPlay,
                                                        selectedIndex:
                                                            _phase ==
                                                                GamePhase.setup
                                                            ? _opponent
                                                                .selectedIndex
                                                            : null,
                                                        onCellTap: (index) =>
                                                            _onCellTap(
                                                          _opponent,
                                                          index,
                                                        ),
                                                      ),
                                                      ),
                                                    ),
                                                    if (identical(
                                                      _plusOneSide,
                                                      _opponent,
                                                    ))
                                                      const Positioned.fill(
                                                        child: _PlusOneBurst(
                                                          inverted: true,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const VolleyballNet(),
                                              SizedBox(
                                                width: side,
                                                height: side,
                                                child: Stack(
                                                  children: [
                                                    Positioned.fill(
                                                      child: _LockedBoard(
                                                      locked: isPlay &&
                                                          !identical(
                                                            _active,
                                                            _player,
                                                          ),
                                                      frozen: isSubstitution &&
                                                          _player.ready,
                                                      child: PuzzleCourt(
                                                        board: _player.board,
                                                        showUseCount: isPlay,
                                                        selectedIndex:
                                                            _phase ==
                                                                GamePhase.setup
                                                            ? _player
                                                                .selectedIndex
                                                            : null,
                                                        onCellTap: (index) =>
                                                            _onCellTap(
                                                          _player,
                                                          index,
                                                        ),
                                                      ),
                                                      ),
                                                    ),
                                                    if (identical(
                                                      _plusOneSide,
                                                      _player,
                                                    ))
                                                      const Positioned.fill(
                                                        child: _PlusOneBurst(),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: benchGap),
                                    SizedBox(
                                      width: benchW,
                                      height: fieldH,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Positioned(
                                            top: border,
                                            left: 0,
                                            right: 0,
                                            height: side,
                                            child: _BenchLane(
                                              inverted: true,
                                              locked: isPlay &&
                                                  !identical(_active, _opponent),
                                              showReady: isSubstitution,
                                              ready: _opponent.ready,
                                              onReady: () =>
                                                  _confirmReady(_opponent),
                                              bench: PuzzleBench(
                                                board: _opponent.board,
                                                inverted: true,
                                                showUseCount: isPlay,
                                                selectedIndex:
                                                    _phase == GamePhase.setup
                                                    ? _opponent.selectedIndex
                                                    : null,
                                                onCellTap: (index) =>
                                                    _onCellTap(
                                                  _opponent,
                                                  index,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: border,
                                            left: 0,
                                            right: 0,
                                            height: side,
                                            child: _BenchLane(
                                              locked: isPlay &&
                                                  !identical(_active, _player),
                                              showReady: isSubstitution,
                                              ready: _player.ready,
                                              onReady: () =>
                                                  _confirmReady(_player),
                                              bench: PuzzleBench(
                                                board: _player.board,
                                                showUseCount: isPlay,
                                                selectedIndex:
                                                    _phase == GamePhase.setup
                                                    ? _player.selectedIndex
                                                    : null,
                                                onCellTap: (index) =>
                                                    _onCellTap(_player, index),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: scoreboardTop,
                                            left: 0,
                                            right: 0,
                                            height: CourtLook.scoreboardBlockHeight,
                                            child: CourtScoreboard(
                                              leftScore: _opponent.score,
                                              rightScore: _player.score,
                                              leftName: _opponent.name,
                                              rightName: _player.name,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        _PlayerHeader(
                          phase: _phase,
                          locked: isPlay && !identical(_active, _player),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isSetup) ...[
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => _startSubstitution(firstPlay: true),
                  child: const Text('Empezar juego'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BenchLane extends StatelessWidget {
  const _BenchLane({
    required this.bench,
    required this.locked,
    this.inverted = false,
    this.showReady = false,
    this.ready = false,
    this.onReady,
  });

  final Widget bench;
  final bool locked;
  final bool inverted;
  final bool showReady;
  final bool ready;
  final VoidCallback? onReady;

  @override
  Widget build(BuildContext context) {
    final blocked = locked || ready;
    final readyButton = showReady
        ? _SubstitutionReadyButton(
            inverted: inverted,
            ready: ready,
            onPressed: onReady,
          )
        : null;
    final body = AbsorbPointer(
      absorbing: blocked,
      child: Opacity(
        opacity: blocked ? 0.4 : 1,
        child: bench,
      ),
    );
    return Column(
      children: [
        if (inverted && readyButton != null) readyButton,
        Expanded(child: body),
        if (!inverted && readyButton != null) readyButton,
      ],
    );
  }
}

class _SubstitutionReadyButton extends StatelessWidget {
  const _SubstitutionReadyButton({
    required this.ready,
    required this.inverted,
    this.onPressed,
  });

  final bool ready;
  final bool inverted;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = ready
        ? FilledButton(
            onPressed: null,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Listo'),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
            ),
            child: const Text('Listo'),
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: RotatedBox(
          quarterTurns: inverted ? 2 : 0,
          child: child,
        ),
      ),
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader({
    required this.phase,
    required this.locked,
  });

  final GamePhase phase;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    if (phase != GamePhase.play || locked) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Chip(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        label: const Text('Turno'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }
}

class _LockedBoard extends StatelessWidget {
  const _LockedBoard({
    required this.locked,
    required this.child,
    this.inverted = false,
    this.frozen = false,
  });

  final bool locked;
  final bool frozen;
  final bool inverted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final blocked = locked || frozen;
    return Stack(
      children: [
        Positioned.fill(
          child: AbsorbPointer(
            absorbing: blocked,
            child: Opacity(
              opacity: blocked ? 0.4 : 1,
              child: child,
            ),
          ),
        ),
        if (locked)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.28),
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RotatedBox(
                      quarterTurns: inverted ? 2 : 0,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Esperando turno'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SidelineBoard extends StatelessWidget {
  const _SidelineBoard({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: RotatedBox(
          quarterTurns: 3,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AnimatedOpacity(
                opacity: message == null ? 0 : 1,
                duration: const Duration(milliseconds: 120),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    message ?? '',
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlusOneBurst extends StatefulWidget {
  const _PlusOneBurst({this.inverted = false});

  final bool inverted;

  @override
  State<_PlusOneBurst> createState() => _PlusOneBurstState();
}

class _PlusOneBurstState extends State<_PlusOneBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.22).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.45, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFE082);
    const core = Color(0xFFFF6F00);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Center(
            child: Transform.scale(
              scale: _scale.value,
              child: RotatedBox(
                quarterTurns: widget.inverted ? 2 : 0,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        gold.withValues(alpha: 0.95 * _glow.value),
                        core.withValues(alpha: 0.7 * _glow.value),
                        Colors.transparent,
                      ],
                      stops: const [0.15, 0.45, 1],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gold.withValues(alpha: 0.85 * _glow.value),
                        blurRadius: 28,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '+1',
                          style: TextStyle(
                            fontSize: 92,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 10
                              ..color = const Color(0xFF3E1A00),
                          ),
                        ),
                        const Text(
                          '+1',
                          style: TextStyle(
                            fontSize: 92,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            color: gold,
                            shadows: [
                              Shadow(
                                color: Color(0xFFFFF59D),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
