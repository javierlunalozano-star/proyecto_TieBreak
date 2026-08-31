import 'package:flutter_test/flutter_test.dart';

import 'package:tiebreakvolleyball/main.dart';
import 'package:tiebreakvolleyball/widgets/scoreboard.dart';

void main() {
  testWidgets('Dos jugadores: organización y paso a juego', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TieBreakApp());

    expect(find.text('Jugador 2'), findsOneWidget);
    expect(find.text('Jugador 1'), findsOneWidget);
    expect(find.text('DEF'), findsNWidgets(10));
    expect(find.text('LÍB'), findsNWidgets(2));
    expect(find.text('Banquillo'), findsNWidgets(2));
    expect(find.text('Empezar juego'), findsOneWidget);

    await tester.tap(find.text('DEF').first);
    await tester.pump();
    await tester.tap(find.text('ATA').last);
    await tester.pump();

    await tester.tap(find.text('Empezar juego'));
    await tester.pump();

    expect(find.text('Empezar juego'), findsNothing);
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.textContaining('Cambio de líbero'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(find.text('Continuar'), findsNothing);
    expect(
      find.text(
        'Completa Defensa → Colocación → Ataque para ceder el turno. Si fallas o usas la misma ficha dos veces seguidas, el rival gana el punto.',
      ),
      findsOneWidget,
    );
    expect(find.byType(CourtScoreboard), findsOneWidget);
    expect(find.text('Turno'), findsOneWidget);
    expect(find.text('Esperando turno'), findsOneWidget);
  });
}
