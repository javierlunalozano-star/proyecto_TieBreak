import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game/game_phase.dart';
import 'game/player_side.dart';
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

  @override
  void initState() {
    super.initState();
    _opponent = PlayerSide(name: 'Jugador 2');
    _player = PlayerSide(name: 'Jugador 1');
    _active = _player;
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
      _opponent.selectedIndex = null;
      _player.selectedIndex = null;
      _phase = GamePhase.substitution;
    });
  }

  void _continueToPlay() {
    setState(() {
      _phase = GamePhase.play;
    });
  }

  void _onCellTap(PlayerSide side, int index) {
    if (_phase == GamePhase.setup) {
      setState(() => side.onSetupTap(index));
      return;
    }

    if (_phase == GamePhase.substitution) {
      setState(() => side.onSubstitutionTap(index));
      return;
    }

    if (!identical(side, _active)) return;

    setState(() {
      final outcome = side.tryPlayMove(index);
      if (outcome == SequenceOutcome.completed) {
        _passTurn(side);
      } else if (outcome != null && outcome.awardsPointToOpponent) {
        _other(side).score++;
        _passTurn(side);
        _opponent.selectedIndex = null;
        _player.selectedIndex = null;
        _phase = GamePhase.substitution;
      }
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
        'Cambio de líbero: intercámbialo con el banquillo o, si está en el banquillo, con una ficha de tu cuadrícula.',
      GamePhase.play =>
        'Completa Defensa → Colocación → Ataque para ceder el turno. Si fallas o usas la misma ficha dos veces seguidas, el rival gana el punto.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isSetup = _phase == GamePhase.setup;
    final isPlay = _phase == GamePhase.play;
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
                          side: _opponent,
                          phase: _phase,
                          locked: isPlay && !identical(_active, _opponent),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const benchW = 88.0;
                              const benchGap = 8.0;
                              const border = CourtLook.lineWidth;
                              const netH = CourtLook.netHeight;
                              final side = math.min(
                                constraints.maxWidth - benchW - benchGap - 2 * border,
                                (constraints.maxHeight - netH - 2 * border) / 2,
                              );
                              if (side <= 0) {
                                return const SizedBox.shrink();
                              }
                              final fieldH = 2 * side + netH + 2 * border;
                              final fieldW = side + 2 * border;
                              return Row(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: SizedBox(
                                        width: fieldW,
                                        height: fieldH,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
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
                                                  child: _LockedBoard(
                                                    inverted: true,
                                                    locked: isPlay &&
                                                        !identical(
                                                          _active,
                                                          _opponent,
                                                        ),
                                                    child: PuzzleCourt(
                                                      board: _opponent.board,
                                                      inverted: true,
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
                                                const VolleyballNet(),
                                                SizedBox(
                                                  width: side,
                                                  height: side,
                                                  child: _LockedBoard(
                                                    locked: isPlay &&
                                                        !identical(
                                                          _active,
                                                          _player,
                                                        ),
                                                    child: PuzzleCourt(
                                                      board: _player.board,
                                                      selectedIndex:
                                                          _phase == GamePhase.setup
                                                          ? _player.selectedIndex
                                                          : null,
                                                      onCellTap: (index) =>
                                                          _onCellTap(
                                                        _player,
                                                        index,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: benchGap),
                                  SizedBox(
                                    width: benchW,
                                    height: fieldH,
                                    child: Column(
                                      children: [
                                        const SizedBox(height: border),
                                        Expanded(
                                          child: AbsorbPointer(
                                            absorbing: isPlay &&
                                                !identical(_active, _opponent),
                                            child: Opacity(
                                              opacity: isPlay &&
                                                      !identical(
                                                        _active,
                                                        _opponent,
                                                      )
                                                  ? 0.4
                                                  : 1,
                                              child: PuzzleBench(
                                                board: _opponent.board,
                                                inverted: true,
                                                selectedIndex:
                                                    _phase == GamePhase.setup
                                                    ? _opponent.selectedIndex
                                                    : null,
                                                onCellTap: (index) =>
                                                    _onCellTap(_opponent, index),
                                              ),
                                            ),
                                          ),
                                        ),
                                        CourtScoreboard(
                                          leftScore: _opponent.score,
                                          rightScore: _player.score,
                                        ),
                                        Expanded(
                                          child: AbsorbPointer(
                                            absorbing: isPlay &&
                                                !identical(_active, _player),
                                            child: Opacity(
                                              opacity: isPlay &&
                                                      !identical(_active, _player)
                                                  ? 0.4
                                                  : 1,
                                              child: PuzzleBench(
                                                board: _player.board,
                                                selectedIndex:
                                                    _phase == GamePhase.setup
                                                    ? _player.selectedIndex
                                                    : null,
                                                onCellTap: (index) =>
                                                    _onCellTap(_player, index),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: border),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        _PlayerHeader(
                          side: _player,
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
              if (_phase == GamePhase.substitution) ...[
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _continueToPlay,
                  child: const Text('Continuar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader({
    required this.side,
    required this.phase,
    required this.locked,
  });

  final PlayerSide side;
  final GamePhase phase;
  final bool locked;

  String get _hint {
    if (locked) {
      return switch (side.lastOutcome) {
        SequenceOutcome.completed => 'Secuencia completa. Esperando turno.',
        SequenceOutcome.fault => 'Secuencia rota. El rival gana el punto.',
        SequenceOutcome.doubleTouch =>
          'Toque doble. El rival gana el punto.',
        _ => 'Esperando turno.',
      };
    }
    return 'Tu turno. Siguiente: ${side.rally.expected.label}.';
  }

  @override
  Widget build(BuildContext context) {
    final showPlayHud = phase == GamePhase.play;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                side.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: locked ? Colors.white54 : Colors.white,
                ),
              ),
              if (showPlayHud && !locked) ...[
                const SizedBox(width: 8),
                Chip(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  label: const Text('Turno'),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
              ],
            ],
          ),
          if (showPlayHud) ...[
            _SequenceProgress(currentStep: side.rally.currentStep),
            Text(
              _hint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LockedBoard extends StatelessWidget {
  const _LockedBoard({
    required this.locked,
    required this.child,
    this.inverted = false,
  });

  final bool locked;
  final bool inverted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AbsorbPointer(
            absorbing: locked,
            child: Opacity(
              opacity: locked ? 0.4 : 1,
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

class _SequenceProgress extends StatelessWidget {
  const _SequenceProgress({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      children: [
        for (var i = 0; i < RallySequence.steps.length; i++)
          Chip(
            visualDensity: VisualDensity.compact,
            label: Text(RallySequence.steps[i].label),
            padding: EdgeInsets.zero,
            backgroundColor: i < currentStep
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            side: i == currentStep
                ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
          ),
      ],
    );
  }
}
