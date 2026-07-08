import 'package:flutter/foundation.dart';
import '../models/langage.dart';
import '../models/niveau.dart';
import '../models/question.dart';
import '../models/tentative.dart';
import '../models/badge_model.dart';
import '../services/database_service.dart';
import '../data/questions_data.dart';

/// Gère l'état d'une session de QCM : sélection, progression, score,
/// puis enregistrement du résultat (tentative + badge éventuel) en base.
/// Gère également le mode « défi quotidien » (une question aléatoire).
class QuizProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  Langage? _langageSelectionne;
  Niveau? _niveauSelectionne;

  List<Question> _questions = [];
  int _indexCourant = 0;
  int _bonnesReponses = 0;
  int? _reponseChoisie;
  bool _reponseValidee = false;
  bool _chargementEnCours = false;
  bool _estDefiQuotidien = false;

  DateTime? _debut;
  bool _resultatEnregistre = false;
  bool _badgeObtenuCetteSession = false;

  Langage? get langageSelectionne => _langageSelectionne;
  Niveau? get niveauSelectionne => _niveauSelectionne;
  List<Question> get questions => _questions;
  int get indexCourant => _indexCourant;
  int? get reponseChoisie => _reponseChoisie;
  bool get reponseValidee => _reponseValidee;
  bool get chargementEnCours => _chargementEnCours;
  bool get estDefiQuotidien => _estDefiQuotidien;
  bool get quizTermine => !_chargementEnCours && _indexCourant >= _questions.length;
  bool get badgeObtenuCetteSession => _badgeObtenuCetteSession;

  Question? get questionCourante =>
      _questions.isEmpty || quizTermine ? null : _questions[_indexCourant];

  int get scorePourcentage {
    if (_questions.isEmpty) return 0;
    return ((_bonnesReponses / _questions.length) * 100).round();
  }

  void choisirLangage(Langage langage) {
    _langageSelectionne = langage;
    notifyListeners();
  }

  void choisirNiveau(Niveau niveau) {
    _niveauSelectionne = niveau;
    notifyListeners();
  }

  /// Démarre une nouvelle session de QCM : charge les questions depuis
  /// la base sqflite pour le langage et le niveau sélectionnés.
  Future<void> demarrerQuiz() async {
    if (_langageSelectionne == null || _niveauSelectionne == null) return;

    _estDefiQuotidien = false;
    _chargementEnCours = true;
    _indexCourant = 0;
    _bonnesReponses = 0;
    _reponseChoisie = null;
    _reponseValidee = false;
    _resultatEnregistre = false;
    _badgeObtenuCetteSession = false;
    notifyListeners();

    _questions = await _db.obtenirQuestions(
      _langageSelectionne!.id,
      _niveauSelectionne!.type,
    );
    _debut = DateTime.now();
    _chargementEnCours = false;
    notifyListeners();
  }

  /// Démarre le défi quotidien : une unique question aléatoire, tous
  /// langages et niveaux confondus.
  Future<void> demarrerDefiQuotidien() async {
    _estDefiQuotidien = true;
    _chargementEnCours = true;
    _indexCourant = 0;
    _bonnesReponses = 0;
    _reponseChoisie = null;
    _reponseValidee = false;
    _resultatEnregistre = false;
    _badgeObtenuCetteSession = false;
    notifyListeners();

    final question = await _db.obtenirQuestionAleatoire();
    if (question == null) {
      _questions = [];
      _chargementEnCours = false;
      notifyListeners();
      return;
    }

    _questions = [question];
    _langageSelectionne = QuestionsData.langages.firstWhere(
      (l) => l.id == question.langageId,
      orElse: () => Langage(id: question.langageId, nom: question.langageId, icone: '❓'),
    );
    _niveauSelectionne = Niveau.tous.firstWhere((n) => n.type == question.niveau);
    _debut = DateTime.now();
    _chargementEnCours = false;
    notifyListeners();
  }

  void selectionnerReponse(int index) {
    if (_reponseValidee) return;
    _reponseChoisie = index;
    notifyListeners();
  }

  void validerReponse() {
    if (_reponseChoisie == null || questionCourante == null) return;
    _reponseValidee = true;
    if (_reponseChoisie == questionCourante!.bonneReponseIndex) {
      _bonnesReponses++;
    }
    notifyListeners();
  }

  void questionSuivante() {
    _indexCourant++;
    _reponseChoisie = null;
    _reponseValidee = false;
    notifyListeners();
  }

  /// Enregistre la tentative terminée pour `utilisateurId` et attribue
  /// un badge si le seuil du niveau est atteint et qu'il n'était pas déjà
  /// obtenu. Ne fait rien si déjà appelé pour cette session.
  Future<void> enregistrerResultat(String utilisateurId) async {
    if (_resultatEnregistre || _langageSelectionne == null || _niveauSelectionne == null) {
      return;
    }
    _resultatEnregistre = true;

    final duree = _debut != null
        ? DateTime.now().difference(_debut!).inSeconds
        : 0;

    final tentative = Tentative(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      utilisateurId: utilisateurId,
      langageId: _langageSelectionne!.id,
      niveau: _niveauSelectionne!.type,
      date: DateTime.now(),
      score: scorePourcentage,
      dureeSecondes: duree,
      estDefiQuotidien: _estDefiQuotidien,
    );
    await _db.enregistrerTentative(tentative);

    if (scorePourcentage >= _niveauSelectionne!.seuilBadge) {
      final dejaObtenu = await _db.possedeBadge(
        utilisateurId,
        _langageSelectionne!.id,
        _niveauSelectionne!.type,
      );
      if (!dejaObtenu) {
        final badge = BadgeModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          utilisateurId: utilisateurId,
          langageId: _langageSelectionne!.id,
          niveau: _niveauSelectionne!.type,
          dateObtention: DateTime.now(),
        );
        await _db.enregistrerBadge(badge);
      }
      _badgeObtenuCetteSession = true;
      notifyListeners();
    }
  }

  void reinitialiser() {
    _langageSelectionne = null;
    _niveauSelectionne = null;
    _questions = [];
    _indexCourant = 0;
    _bonnesReponses = 0;
    _reponseChoisie = null;
    _reponseValidee = false;
    _resultatEnregistre = false;
    _badgeObtenuCetteSession = false;
    _estDefiQuotidien = false;
    notifyListeners();
  }
}
