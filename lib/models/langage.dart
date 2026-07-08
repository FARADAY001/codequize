/// Représente un langage de programmation proposé dans le QCM.
class Langage {
  final String id;
  final String nom;
  final String icone; // chemin d'asset ou emoji provisoire

  const Langage({
    required this.id,
    required this.nom,
    required this.icone,
  });
}
