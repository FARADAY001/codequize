import 'package:flutter_test/flutter_test.dart';
import 'package:codequiz/providers/quiz_provider.dart';
import 'package:codequiz/models/langage.dart';
import 'package:codequiz/models/niveau.dart';

import 'test_helpers/db_test_setup.dart';

/// Test unitaire prévu au dossier de conception technique (section 7) :
/// calcul du score pondéré dans QuizProvider.
///
/// Le jeu de questions de base (questions_data.dart) contient exactement
/// 2 questions pour Dart / Débutant : ce test s'appuie sur ce nombre connu
/// pour vérifier le calcul du pourcentage.
void main() {
  setUpAll(() async {
    await initialiserDbPourTests();
  });

  setUp(() async {
    await initialiserDbPourTests();
  });

  const langageDart = Langage(id: 'dart', nom: 'Dart', icone: '🎯');
  final niveauDebutant = Niveau.tous.firstWhere((n) => n.type == NiveauType.debutant);

  test('le score est de 100% si toutes les réponses sont correctes', () async {
    final quiz = QuizProvider();
    quiz.choisirLangage(langageDart);
    quiz.choisirNiveau(niveauDebutant);
    await quiz.demarrerQuiz();

    expect(quiz.questions, isNotEmpty, reason: 'la banque de questions seed doit être disponible');

    // Répond correctement à toutes les questions.
    while (!quiz.quizTermine) {
      final question = quiz.questionCourante!;
      quiz.selectionnerReponse(question.bonneReponseIndex);
      quiz.validerReponse();
      quiz.questionSuivante();
    }

    expect(quiz.scorePourcentage, 100);
  });

  test('le score est de 0% si toutes les réponses sont incorrectes', () async {
    final quiz = QuizProvider();
    quiz.choisirLangage(langageDart);
    quiz.choisirNiveau(niveauDebutant);
    await quiz.demarrerQuiz();

    while (!quiz.quizTermine) {
      final question = quiz.questionCourante!;
      // Choisit systématiquement une réponse différente de la bonne.
      final mauvaiseReponse = (question.bonneReponseIndex + 1) % question.propositions.length;
      quiz.selectionnerReponse(mauvaiseReponse);
      quiz.validerReponse();
      quiz.questionSuivante();
    }

    expect(quiz.scorePourcentage, 0);
  });

  test('le score se calcule correctement avec un mélange de bonnes et de mauvaises réponses', () async {
    final quiz = QuizProvider();
    quiz.choisirLangage(langageDart);
    quiz.choisirNiveau(niveauDebutant);
    await quiz.demarrerQuiz();

    final nombreDeQuestions = quiz.questions.length;
    expect(nombreDeQuestions, greaterThanOrEqualTo(2));

    var index = 0;
    while (!quiz.quizTermine) {
      final question = quiz.questionCourante!;
      if (index == 0) {
        // Première question : bonne réponse.
        quiz.selectionnerReponse(question.bonneReponseIndex);
      } else {
        // Questions suivantes : mauvaise réponse.
        final mauvaiseReponse = (question.bonneReponseIndex + 1) % question.propositions.length;
        quiz.selectionnerReponse(mauvaiseReponse);
      }
      quiz.validerReponse();
      quiz.questionSuivante();
      index++;
    }

    final scoreAttendu = ((1 / nombreDeQuestions) * 100).round();
    expect(quiz.scorePourcentage, scoreAttendu);
  });

  test('un badge est marqué comme obtenu si le score atteint le seuil du niveau', () async {
    final quiz = QuizProvider();
    quiz.choisirLangage(langageDart);
    quiz.choisirNiveau(niveauDebutant);
    await quiz.demarrerQuiz();

    while (!quiz.quizTermine) {
      final question = quiz.questionCourante!;
      quiz.selectionnerReponse(question.bonneReponseIndex);
      quiz.validerReponse();
      quiz.questionSuivante();
    }

    // Utilisateur fictif : seul l'identifiant compte pour cet enregistrement.
    await quiz.enregistrerResultat('utilisateur_test_score');

    expect(quiz.scorePourcentage, greaterThanOrEqualTo(niveauDebutant.seuilBadge));
    expect(quiz.badgeObtenuCetteSession, isTrue);
  });
}
