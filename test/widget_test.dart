import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';

void main() {
  testWidgets('Verifica caricamento schermata login', (WidgetTester tester) async {
    // Carichiamo l'app passandogli il parametro richiesto nel tuo main originale
    await tester.pumpWidget(
      const MyApp(currentUserEmail: '')
    );

    // Verifichiamo che appaia il testo "Log in" nella schermata iniziale
    // Nota: find.text('Log in') cercherà il testo nel tuo widget LoginScreen
    expect(find.text('Log in'), findsWidgets);
  });
}