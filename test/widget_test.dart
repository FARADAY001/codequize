import 'package:flutter_test/flutter_test.dart';

import 'package:codequiz/main.dart';

/// Test de smoke : au premier lancement (aucune session active), l'écran
/// de démarrage doit être Connexion, conformément à AuthGate (main.dart)
void main() {
  testWidgets("l'application démarre sur l'écran Connexion sans session active",
      (WidgetTester tester) async {
    await tester.pumpWidget(const CodeQuizApp());

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Pas encore de compte ? Créer un compte'), findsOneWidget);
  });
}
