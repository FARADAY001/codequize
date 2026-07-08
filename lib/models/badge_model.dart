import 'niveau.dart';

/// Type de badge : lié à une compétence (score) ou à une série (streak).
enum TypeBadge { competence, serie }

/// Un badge de compétence débloqué par l'utilisateur.
class BadgeModel {
  final String id;
  final String utilisateurId;
  final String langageId;
  final NiveauType niveau;
  final DateTime dateObtention;
  final TypeBadge type;

  const BadgeModel({
    required this.id,
    required this.utilisateurId,
    required this.langageId,
    required this.niveau,
    required this.dateObtention,
    this.type = TypeBadge.competence,
  });

  Map<String, Object?> versMap() {
    return {
      'id': id,
      'utilisateur_id': utilisateurId,
      'langage_id': langageId,
      'niveau': niveau.name,
      'date_obtention': dateObtention.toIso8601String(),
      'type': type.name,
    };
  }

  factory BadgeModel.depuisMap(Map<String, Object?> map) {
    return BadgeModel(
      id: map['id'] as String,
      utilisateurId: map['utilisateur_id'] as String,
      langageId: map['langage_id'] as String,
      niveau: NiveauType.values.firstWhere((n) => n.name == map['niveau']),
      dateObtention: DateTime.parse(map['date_obtention'] as String),
      type: TypeBadge.values.firstWhere((t) => t.name == map['type']),
    );
  }
}
