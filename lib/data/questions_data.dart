import '../models/langage.dart';
import '../models/niveau.dart';
import '../models/question.dart';

/// Jeu de données de référence (langages et banque de questions seed).
///
/// Ces questions ne sont lues qu'une fois, par DatabaseService, pour
/// pré-remplir la base sqflite locale à sa création; tous les écrans lisent ensuite
/// les questions depuis la base, jamais depuis cette liste directement.
class QuestionsData {
  static const List<Langage> langages = [
    Langage(id: 'dart', nom: 'Dart', icone: '🎯'),
    Langage(id: 'python', nom: 'Python', icone: '🐍'),
    Langage(id: 'javascript', nom: 'JavaScript', icone: '🟨'),
  ];

  static const List<Question> questions = [
    Question(
      id: 'q1',
      langageId: 'dart',
      niveau: NiveauType.debutant,
      enonce: "Quel mot-clé permet de déclarer une variable dont la valeur ne changera jamais en Dart ?",
      propositions: ['var', 'final', 'const', 'let'],
      bonneReponseIndex: 2,
      explication: "const définit une constante évaluée à la compilation, contrairement à final évaluée à l'exécution.",
    ),
    Question(
      id: 'q2',
      langageId: 'dart',
      niveau: NiveauType.debutant,
      enonce: "Quelle fonction est le point d'entrée d'une application Dart ?",
      propositions: ['start()', 'main()', 'run()', 'init()'],
      bonneReponseIndex: 1,
      explication: "Toute application Dart démarre par l'exécution de la fonction main().",
    ),
    Question(
      id: 'q3',
      langageId: 'python',
      niveau: NiveauType.debutant,
      enonce: "Comment définit-on une fonction en Python ?",
      propositions: ['function maFonction():', 'def maFonction():', 'func maFonction():', 'fn maFonction():'],
      bonneReponseIndex: 1,
      explication: "Le mot-clé def introduit la définition d'une fonction en Python.",
    ),
    Question(
      id: 'q4',
      langageId: 'javascript',
      niveau: NiveauType.debutant,
      enonce: "Quel opérateur compare la valeur ET le type en JavaScript ?",
      propositions: ['==', '=', '===', '!='],
      bonneReponseIndex: 2,
      explication: "=== est l'opérateur d'égalité stricte : il compare la valeur et le type.",
    ),
  ];

  /// Nom affichable d'un langage à partir de son id, ou l'id lui-même si
  /// inconnu (ex. donnée orpheline après suppression d'un langage).
  static String nomLangage(String langageId) {
    final trouve = langages.where((l) => l.id == langageId);
    return trouve.isEmpty ? langageId : trouve.first.nom;
  }
}
