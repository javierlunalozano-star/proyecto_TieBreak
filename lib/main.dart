import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game/game_phase.dart';
import 'game/player_side.dart';
import 'game/puzzle_board.dart';
import 'game/rally_sequence.dart';
import 'widgets/cover_page.dart';
import 'widgets/how_to_play_page.dart';
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
      title: 'TieBreak Volleyball',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: Builder(
        builder: (context) {
          return CoverPage(
            onPlay: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (howToContext) {
                    return HowToPlayPage(
                      onContinue: () {
                        Navigator.of(howToContext).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PuzzlePage(),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
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
  PlayerSide? _winner;
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
      if (_phase == GamePhase.substitution) {
        _advanceIfBothReady();
      }
    });
    if (_phase == GamePhase.setup && _player.ready && _opponent.ready) {
      _startSubstitution(firstPlay: true);
    }
  }

  void _advanceIfBothReady() {
    if (_player.ready && _opponent.ready) {
      _phase = GamePhase.play;
    }
  }

  void _onCellTap(PlayerSide side, int index) {
    if (_phase == GamePhase.finished) return;

    if (_phase == GamePhase.setup) {
      if (side.ready) return;
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
        _awardPoint(to: _other(side), from: side);
      }
    });
  }

  void _awardPoint({required PlayerSide to, required PlayerSide from}) {
    to.score++;
    _showPlusOne(to);
    _opponent.board.resetUseCounts();
    _player.board.resetUseCounts();
    if (to.hasWon) {
      _winner = to;
      _phase = GamePhase.finished;
      _showSidelineMessage('Victoria de ${to.name}');
      return;
    }
    from.rally = RallySequence();
    _active = from;
    _opponent.beginSubstitution();
    _player.beginSubstitution();
    _phase = GamePhase.substitution;
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

  @override
  Widget build(BuildContext context) {
    final isSetup = _phase == GamePhase.setup;
    final isPlay = _phase == GamePhase.play;
    final isSubstitution = _phase == GamePhase.substitution;
    final isFinished = _phase == GamePhase.finished;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: CourtLook.blue,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                                        phase: _phase,
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
                                                      frozen: (isSetup &&
                                                              _opponent.ready) ||
                                                          (isSubstitution &&
                                                              _opponent.ready) ||
                                                          isFinished,
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
                                                      frozen: (isSetup &&
                                                              _player.ready) ||
                                                          (isSubstitution &&
                                                              _player.ready) ||
                                                          isFinished,
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
                                              showReady: isSetup || isSubstitution,
                                              readyLabel: isSetup
                                                  ? 'Empezar juego'
                                                  : 'Listo',
                                              ready: _opponent.ready,
                                              onReady: () =>
                                                  _confirmReady(_opponent),
                                              setupSwapsLeft: isSetup
                                                  ? _opponent.setupSwapsLeft
                                                  : null,
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
                                              showReady: isSetup || isSubstitution,
                                              readyLabel: isSetup
                                                  ? 'Empezar juego'
                                                  : 'Listo',
                                              ready: _player.ready,
                                              onReady: () =>
                                                  _confirmReady(_player),
                                              setupSwapsLeft: isSetup
                                                  ? _player.setupSwapsLeft
                                                  : null,
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
                  ),
                ),
            ],
          ),
        ),
            if (_winner != null) _MatchOverBanner(winner: _winner!),
          ],
        ),
      ),
    );
  }
}

class _MatchOverBanner extends StatelessWidget {
  const _MatchOverBanner({required this.winner});

  final PlayerSide winner;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF003D6B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Victoria',
                      style: TextStyle(
                        color: CourtLook.cell,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      winner.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${PlayerSide.winScore} puntos',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: CourtLook.cell,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('PORTADA'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    this.readyLabel = 'Listo',
    this.onReady,
    this.setupSwapsLeft,
  });

  final Widget bench;
  final bool locked;
  final bool inverted;
  final bool showReady;
  final bool ready;
  final String readyLabel;
  final VoidCallback? onReady;
  final int? setupSwapsLeft;

  @override
  Widget build(BuildContext context) {
    final blocked = locked || ready;
    final extras = <Widget>[
      if (setupSwapsLeft != null)
        _SetupSwapsLabel(
          inverted: inverted,
          left: setupSwapsLeft!,
        ),
      if (showReady)
        _SideReadyButton(
          inverted: inverted,
          ready: ready,
          label: readyLabel,
          onPressed: onReady,
        ),
    ];
    final body = AbsorbPointer(
      absorbing: blocked,
      child: Opacity(
        opacity: blocked ? 0.4 : 1,
        child: bench,
      ),
    );
    return Column(
      children: [
        if (inverted) ...extras.reversed,
        Expanded(child: body),
        if (!inverted) ...extras,
      ],
    );
  }
}

class _SetupSwapsLabel extends StatelessWidget {
  const _SetupSwapsLabel({required this.left, required this.inverted});

  final int left;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: RotatedBox(
          quarterTurns: inverted ? 2 : 0,
          child: Text(
            '$left/${PlayerSide.maxSetupSwaps}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _SideReadyButton extends StatelessWidget {
  const _SideReadyButton({
    required this.ready,
    required this.inverted,
    required this.label,
    this.onPressed,
  });

  final bool ready;
  final bool inverted;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      visualDensity: VisualDensity.compact,
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final child = ready
        ? FilledButton(
            onPressed: null,
            style: style,
            child: FittedBox(child: Text(label)),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: style.copyWith(
              foregroundColor: const WidgetStatePropertyAll(Colors.white),
              side: const WidgetStatePropertyAll(
                BorderSide(color: Colors.white),
              ),
            ),
            child: FittedBox(child: Text(label)),
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

class _SidelineBoard extends StatelessWidget {
  const _SidelineBoard({required this.phase, this.message});

  final GamePhase phase;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message == null || message!.isEmpty
        ? phase.label
        : '${phase.label} · $message';
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
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
