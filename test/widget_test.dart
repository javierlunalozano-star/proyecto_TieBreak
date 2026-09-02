import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiebreakvolleyball/main.dart';
import 'package:tiebreakvolleyball/widgets/scoreboard.dart';

void main() {
  testWidgets('Dos jugadores: organización y paso a juego', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TieBreakApp());

    expect(find.text('TieBreak'), findsNWidgets(2));
    expect(find.text('VOLLEYBALL'), findsNWidgets(2));

    await tester.tap(find.text('JUGAR'));
    await tester.pumpAndSettle();

    expect(find.text('Fases del juego'), findsOneWidget);
    expect(find.text('Organización'), findsOneWidget);
    expect(find.text('Cambio de líbero'), findsOneWidget);
    expect(find.text('Juego'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Final'),
      60,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Final'), findsOneWidget);
    expect(
      find.textContaining('llega a 15 puntos'),
      findsOneWidget,
    );
    expect(
      find.textContaining('como máximo 5 cambios'),
      findsOneWidget,
    );
    expect(
      find.textContaining('El líbero no se puede mover'),
      findsOneWidget,
    );
    expect(find.textContaining('no se puede deshacer'), findsOneWidget);

    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();

    expect(find.text('Jugador 2'), findsOneWidget);
    expect(find.text('Jugador 1'), findsOneWidget);
    expect(find.byType(CourtScoreboard), findsOneWidget);
    expect(find.text('DEF'), findsNWidgets(10));
    expect(find.text('LÍB'), findsNWidgets(2));
    expect(find.text('Banquillo'), findsNWidgets(2));
    expect(find.text('Empezar juego'), findsNWidgets(2));
    expect(find.text('5/5'), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byType(PuzzlePage),
        matching: find.text('Organización'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('DEF').first);
    await tester.pump();
    await tester.tap(find.text('ATA').last);
    await tester.pump();

    await tester.tap(find.text('Empezar juego').first);
    await tester.pump();
    expect(find.text('Listo'), findsNothing);
    expect(find.text('Empezar juego'), findsNWidgets(2));

    await tester.tap(find.text('Empezar juego').last);
    await tester.pump();

    expect(find.text('Empezar juego'), findsNothing);
    expect(find.text('Listo'), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byType(PuzzlePage),
        matching: find.text('Cambio de líbero'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Listo').first);
    await tester.pump();
    expect(find.text('Listo'), findsNWidgets(2));

    await tester.tap(find.text('Listo').last);
    await tester.pump();

    expect(find.text('Listo'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(PuzzlePage),
        matching: find.text('Juego'),
      ),
      findsOneWidget,
    );
    expect(find.byType(CourtScoreboard), findsOneWidget);
    expect(find.text('Turno'), findsNothing);
    expect(find.text('Esperando turno'), findsOneWidget);
  });
}
