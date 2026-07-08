import 'niveau.dart';

/// Une tentative de QCM passée par l'utilisateur (historique).
class Tentative {
  final String id;
  final String utilisateurId;
  final String langageId;
  final NiveauType niveau;
  final DateTime date;
  final int score; // en pourcentage
  final int dureeSecondes;
  final bool estDefiQuotidien;

  const Tentative({
    required this.id,
    required this.utilisateurId,
    required this.langageId,
    required this.niveau,
    required this.date,
    required this.score,
    required this.dureeSecondes,
    this.estDefiQuotidien = false,
  });

  Map<String, Object?> versMap() {
    return {
      'id': id,
      'utilisateur_id': utilisateurId,
      'langage_id': langageId,
      'niveau': niveau.name,
      'date': date.toIso8601String(),
      'score': score,
      'duree_secondes': dureeSecondes,
      'est_defi_quotidien': estDefiQuotidien ? 1 : 0,
    };
  }

  factory Tentative.depuisMap(Map<String, Object?> map) {
    return Tentative(
      id: map['id'] as String,
      utilisateurId: map['utilisateur_id'] as String,
      langageId: map['langage_id'] as String,
      niveau: NiveauType.values.firstWhere((n) => n.name == map['niveau']),
      date: DateTime.parse(map['date'] as String),
      score: map['score'] as int,
      dureeSecondes: map['duree_secondes'] as int,
      estDefiQuotidien: (map['est_defi_quotidien'] as int) == 1,
    );
  }
}
