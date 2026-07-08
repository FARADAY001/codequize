import 'dart:convert';
import 'niveau.dart';

/// Une question de QCM rattachée à un langage et un niveau.
class Question {
  final String id;
  final String langageId;
  final NiveauType niveau;
  final String enonce;
  final List<String> propositions;
  final int bonneReponseIndex;
  final String explication;

  const Question({
    required this.id,
    required this.langageId,
    required this.niveau,
    required this.enonce,
    required this.propositions,
    required this.bonneReponseIndex,
    required this.explication,
  });

  Map<String, Object?> versMap() {
    return {
      'id': id,
      'langage_id': langageId,
      'niveau': niveau.name,
      'enonce': enonce,
      'propositions': jsonEncode(propositions),
      'bonne_reponse_index': bonneReponseIndex,
      'explication': explication,
    };
  }

  factory Question.depuisMap(Map<String, Object?> map) {
    return Question(
      id: map['id'] as String,
      langageId: map['langage_id'] as String,
      niveau: NiveauType.values.firstWhere((n) => n.name == map['niveau']),
      enonce: map['enonce'] as String,
      propositions: List<String>.from(jsonDecode(map['propositions'] as String)),
      bonneReponseIndex: map['bonne_reponse_index'] as int,
      explication: map['explication'] as String,
    );
  }
}
