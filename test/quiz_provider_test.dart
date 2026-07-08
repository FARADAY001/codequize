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
///
/// Les propositions étant mélangées à l'affichage (QuizProvider mélange
/// leur ordre et le renouvelle périodiquement), on ne peut plus utiliser
/// `question.bonneReponseIndex` comme index à sélectionner : il faut
/// retrouver la position, dans l'ordre mélangé courant, qui correspond à
/// la bonne réponse (ou à une mauvaise), via `estPositionBonneReponse`.
int _indexBonneReponse(QuizProvider quiz) {
  final total = quiz.propositionsAffichees.length;
  for (var i = 0; i < total; i++) {
    if (quiz.estPositionBonneReponse(i)) return i;
  }
  throw StateError('Aucune bonne réponse trouvée dans les propositions affichées');
}

int _indexMauvaiseReponse(QuizProvider quiz) {
  final total = quiz.propositionsAffichees.length;
  for (var i = 0; i < total; i++) {
    if (!quiz.estPositionBonneReponse(i)) return i;
  }
  throw StateError('Aucune mauvaise réponse trouvée dans les propositions affichées');
}

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
      quiz.selectionnerReponse(_indexBonneReponse(quiz));
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
      // Choisit systématiquement une réponse différente de la bonne.
      quiz.selectionnerReponse(_indexMauvaiseReponse(quiz));
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
      if (index == 0) {
        // Première question : bonne réponse.
        quiz.selectionnerReponse(_indexBonneReponse(quiz));
      } else {
        // Questions suivantes : mauvaise réponse.
        quiz.selectionnerReponse(_indexMauvaiseReponse(quiz));
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
      quiz.selectionnerReponse(_indexBonneReponse(quiz));
      quiz.validerReponse();
      quiz.questionSuivante();
    }

    // Utilisateur fictif : seul l'identifiant compte pour cet enregistrement.
    await quiz.enregistrerResultat('utilisateur_test_score');

    expect(quiz.scorePourcentage, greaterThanOrEqualTo(niveauDebutant.seuilBadge));
    expect(quiz.badgeObtenuCetteSession, isTrue);
  });
}
