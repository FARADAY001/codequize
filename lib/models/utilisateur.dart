/// Représente un compte utilisateur de CodeQuiz.
///
/// Le mot de passe n'est jamais stocké en clair : seul son hash
/// (SHA-256, voir AuthProvider) est conservé.
class Utilisateur {
  final String id;
  final String nomUtilisateur;
  final String motDePasseHache;
  final DateTime dateCreation;
  final int serieActuelle;
  final int meilleureSerie;
  final DateTime? derniereDateDefi;

  const Utilisateur({
    required this.id,
    required this.nomUtilisateur,
    required this.motDePasseHache,
    required this.dateCreation,
    this.serieActuelle = 0,
    this.meilleureSerie = 0,
    this.derniereDateDefi,
  });

  Utilisateur copierAvec({
    int? serieActuelle,
    int? meilleureSerie,
    DateTime? derniereDateDefi,
  }) {
    return Utilisateur(
      id: id,
      nomUtilisateur: nomUtilisateur,
      motDePasseHache: motDePasseHache,
      dateCreation: dateCreation,
      serieActuelle: serieActuelle ?? this.serieActuelle,
      meilleureSerie: meilleureSerie ?? this.meilleureSerie,
      derniereDateDefi: derniereDateDefi ?? this.derniereDateDefi,
    );
  }

  Map<String, Object?> versMap() {
    return {
      'id': id,
      'nom_utilisateur': nomUtilisateur,
      'mot_de_passe_hache': motDePasseHache,
      'date_creation': dateCreation.toIso8601String(),
      'serie_actuelle': serieActuelle,
      'meilleure_serie': meilleureSerie,
      'derniere_date_defi': derniereDateDefi?.toIso8601String(),
    };
  }

  factory Utilisateur.depuisMap(Map<String, Object?> map) {
    return Utilisateur(
      id: map['id'] as String,
      nomUtilisateur: map['nom_utilisateur'] as String,
      motDePasseHache: map['mot_de_passe_hache'] as String,
      dateCreation: DateTime.parse(map['date_creation'] as String),
      serieActuelle: map['serie_actuelle'] as int? ?? 0,
      meilleureSerie: map['meilleure_serie'] as int? ?? 0,
      derniereDateDefi: map['derniere_date_defi'] != null
          ? DateTime.parse(map['derniere_date_defi'] as String)
          : null,
    );
  }
}
