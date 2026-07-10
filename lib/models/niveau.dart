/// Niveau de difficulté d'un QCM : Débutant, Intermédiaire, Expert.
enum NiveauType { debutant, intermediaire, expert }

class Niveau {
  final NiveauType type;
  final String nom;
  final int seuilBadge; // score minimum (%) pour débloquer le badge

  const Niveau({
    required this.type,
    required this.nom,
    required this.seuilBadge,
  });

  static const List<Niveau> tous = [
    Niveau(type: NiveauType.debutant, nom: 'Débutant', seuilBadge: 70),
    Niveau(type: NiveauType.intermediaire, nom: 'Intermédiaire', seuilBadge: 75),
    Niveau(type: NiveauType.expert, nom: 'Expert', seuilBadge: 80),
  ];
}

/// écran qui affiche un niveau.
extension NiveauTypeLibelle on NiveauType {
  String get libelle => Niveau.tous.firstWhere((n) => n.type == this).nom;
}
