import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:codequiz/providers/auth_provider.dart';
import 'package:codequiz/providers/quiz_provider.dart';
import 'package:codequiz/models/langage.dart';
import 'package:codequiz/models/niveau.dart';
import 'package:codequiz/screens/quiz_screen.dart';

import '../test_helpers/db_test_setup.dart';

/// Test de widget prévu au dossier de conception technique (section 7) :
/// affichage de l'écran Quiz (sélection d'une réponse, affichage de
/// l'explication après validation).
void main() {
  setUpAll(() async {
    await initialiserDbPourTests();
  });

  setUp(() async {
    await initialiserDbPourTests();
  });

  Future<QuizProvider> preparerQuizPourDartDebutant() async {
    final quiz = QuizProvider();
    quiz.choisirLangage(const Langage(id: 'dart', nom: 'Dart', icone: '🎯'));
    quiz.choisirNiveau(Niveau.tous.firstWhere((n) => n.type == NiveauType.debutant));
    await quiz.demarrerQuiz();
    return quiz;
  }

  Widget construireEcran(AuthProvider auth, QuizProvider quiz) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<QuizProvider>.value(value: quiz),
      ],
      child: const MaterialApp(home: QuizScreen()),
    );
  }

  testWidgets("l'énoncé et les propositions de la première question s'affichent",
      (tester) async {
    final auth = AuthProvider();
    // La préparation (inscription + chargement des questions) exécute de
    // vraies opérations asynchrones (accès sqflite) : sans tester.runAsync,
    // le zonage « fake async » de testWidgets ne les laisse jamais se
    // terminer et le test reste bloqué jusqu'au timeout.
    final quiz = (await tester.runAsync(() async {
      await auth.inscrire('joueur_widget_1', 'motdepasse123');
      return preparerQuizPourDartDebutant();
    }))!;

    await tester.pumpWidget(construireEcran(auth, quiz));
    await tester.pumpAndSettle();

    final premiereQuestion = quiz.questions.first;
    expect(find.text(premiereQuestion.enonce), findsOneWidget);
    for (final proposition in premiereQuestion.propositions) {
      expect(find.text(proposition), findsOneWidget);
    }

    // Le bouton "Valider" est désactivé tant qu'aucune réponse n'est choisie.
    final boutonValider = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(boutonValider.onPressed, isNull);
  });

  testWidgets("sélectionner une réponse puis valider affiche l'explication",
      (tester) async {
    final auth = AuthProvider();
    final quiz = (await tester.runAsync(() async {
      await auth.inscrire('joueur_widget_2', 'motdepasse123');
      return preparerQuizPourDartDebutant();
    }))!;

    await tester.pumpWidget(construireEcran(auth, quiz));
    await tester.pumpAndSettle();

    final premiereQuestion = quiz.questions.first;

    // Sélectionne la bonne réponse.
    await tester.tap(find.text(premiereQuestion.propositions[premiereQuestion.bonneReponseIndex]));
    await tester.pumpAndSettle();

    // Valide la réponse.
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.text(premiereQuestion.explication), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
  });
}
