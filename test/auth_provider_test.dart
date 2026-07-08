import 'package:flutter_test/flutter_test.dart';
import 'package:codequiz/providers/auth_provider.dart';
import 'package:codequiz/services/database_service.dart';

import 'test_helpers/db_test_setup.dart';

/// Test unitaire prévu au dossier de conception technique (section 7) :
/// mise à jour de la série (streak) dans AuthProvider après un défi
/// quotidien.
void main() {
  setUpAll(() async {
    await initialiserDbPourTests();
  });

  setUp(() async {
    await initialiserDbPourTests();
  });

  test("la série passe à 1 lors de la première participation au défi", () async {
    final auth = AuthProvider();
    final inscrit = await auth.inscrire('joueur_streak_1', 'motdepasse123');
    expect(inscrit, isTrue);

    expect(auth.defiDejaFaitAujourdHui, isFalse);

    final incrementee = await auth.enregistrerParticipationDefi();

    expect(incrementee, isTrue);
    expect(auth.utilisateurCourant!.serieActuelle, 1);
    expect(auth.utilisateurCourant!.meilleureSerie, 1);
    expect(auth.defiDejaFaitAujourdHui, isTrue);
  });

  test("participer deux fois le même jour n'incrémente pas la série", () async {
    final auth = AuthProvider();
    await auth.inscrire('joueur_streak_2', 'motdepasse123');

    await auth.enregistrerParticipationDefi();
    final deuxiemeParticipation = await auth.enregistrerParticipationDefi();

    expect(deuxiemeParticipation, isFalse);
    expect(auth.utilisateurCourant!.serieActuelle, 1);
  });

  test("la série s'incrémente si le défi précédent date d'hier", () async {
    final auth = AuthProvider();
    await auth.inscrire('joueur_streak_3', 'motdepasse123');
    await auth.enregistrerParticipationDefi();

    // Simule une participation la veille en modifiant directement la date
    // en base, puis en rechargeant l'utilisateur courant.
    final utilisateur = auth.utilisateurCourant!;
    final hier = DateTime.now().subtract(const Duration(days: 1));
    final utilisateurHier = utilisateur.copierAvec(
      derniereDateDefi: DateTime(hier.year, hier.month, hier.day),
    );
    await DatabaseService.instance.mettreAJourUtilisateur(utilisateurHier);
    await auth.rafraichirUtilisateurCourant();

    final incrementee = await auth.enregistrerParticipationDefi();

    expect(incrementee, isTrue);
    expect(auth.utilisateurCourant!.serieActuelle, 2);
    expect(auth.utilisateurCourant!.meilleureSerie, 2);
  });

  test("la série repart à 1 si un jour a été manqué", () async {
    final auth = AuthProvider();
    await auth.inscrire('joueur_streak_4', 'motdepasse123');
    await auth.enregistrerParticipationDefi();

    // Simule une dernière participation il y a 3 jours (un jour manqué).
    final utilisateur = auth.utilisateurCourant!;
    final ilYA3Jours = DateTime.now().subtract(const Duration(days: 3));
    final utilisateurAncien = utilisateur.copierAvec(
      serieActuelle: 5,
      meilleureSerie: 5,
      derniereDateDefi: DateTime(ilYA3Jours.year, ilYA3Jours.month, ilYA3Jours.day),
    );
    await DatabaseService.instance.mettreAJourUtilisateur(utilisateurAncien);
    await auth.rafraichirUtilisateurCourant();

    await auth.enregistrerParticipationDefi();

    expect(auth.utilisateurCourant!.serieActuelle, 1);
    expect(auth.utilisateurCourant!.meilleureSerie, 5, reason: 'la meilleure série ne doit pas régresser');
  });

  test('un badge de série est débloqué au 7ᵉ jour consécutif', () async {
    final auth = AuthProvider();
    await auth.inscrire('joueur_streak_7', 'motdepasse123');

    final utilisateur = auth.utilisateurCourant!;
    final hier = DateTime.now().subtract(const Duration(days: 1));
    final utilisateurVeilleAvec6Jours = utilisateur.copierAvec(
      serieActuelle: 6,
      meilleureSerie: 6,
      derniereDateDefi: DateTime(hier.year, hier.month, hier.day),
    );
    await DatabaseService.instance.mettreAJourUtilisateur(utilisateurVeilleAvec6Jours);
    await auth.rafraichirUtilisateurCourant();

    await auth.enregistrerParticipationDefi();
    expect(auth.utilisateurCourant!.serieActuelle, 7);

    final badges = await DatabaseService.instance.obtenirBadges(utilisateur.id);
    expect(badges.any((b) => b.type.toString().contains('serie')), isTrue);
  });
}
