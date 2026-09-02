import 'package:flutter/material.dart';

import '../game/game_phase.dart';
import 'puzzle_grid.dart';

class HowToPlayPage extends StatelessWidget {
  const HowToPlayPage({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF003D6B),
              CourtLook.blue,
              Color(0xFF002A4A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const Text(
                  'Fases del juego',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: const [
                      _PhaseCard(
                        phase: GamePhase.setup,
                        body:
                            'Organiza las fichas de la cuadrícula. Cada jugador puede hacer como máximo 5 cambios. El líbero no se puede mover. Ambos jugadores deben pulsar Empezar juego.',
                      ),
                      SizedBox(height: 12),
                      _PhaseCard(
                        phase: GamePhase.substitution,
                        body:
                            'Cambio de líbero: un único cambio o pulsa Listo. Esa decisión no se puede deshacer.',
                      ),
                      SizedBox(height: 12),
                      _PhaseCard(
                        phase: GamePhase.play,
                        body:
                            'Completa Defensa → Colocación → Ataque para ceder el turno. Si fallas, usas la misma ficha dos veces seguidas o mueves una ficha que ya tiene 4 usos, el rival gana el punto. Al marcar un punto, los contadores de uso de todas las fichas se reinician.',
                      ),
                      SizedBox(height: 12),
                      _PhaseCard(
                        phase: GamePhase.finished,
                        body:
                            'El primer jugador que llega a 15 puntos gana la partida.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: CourtLook.cell,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    child: const Text('CONTINUAR'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.phase, required this.body});

  final GamePhase phase;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              phase.label,
              style: const TextStyle(
                color: CourtLook.cell,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
