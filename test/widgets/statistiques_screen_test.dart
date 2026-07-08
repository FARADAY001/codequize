import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:codequiz/providers/auth_provider.dart';
import 'package:codequiz/models/niveau.dart';
import 'package:codequiz/models/tentative.dart';
import 'package:codequiz/services/database_service.dart';
import 'package:codequiz/screens/statistiques_screen.dart';

import '../test_helpers/db_test_setup.dart';

/// Test de widget prévu au dossier de conception technique (section 7) :
/// affichage du graphique de l'écran Statistiques à partir d'une liste de
/// tentatives simulée.
void main() {
  setUpAll(() async {
    await initialiserDbPourTests();
  });

  setUp(() async {
    await initialiserDbPourTests();
  });

  Future<Tentative> creerTentative(String utilisateurId, int score, int joursAvant) {
    final tentative = Tentative(
      id: 'tentative_${score}_$joursAvant',
      utilisateurId: utilisateurId,
      langageId: 'dart',
      niveau: NiveauType.debutant,
      date: DateTime.now().subtract(Duration(days: joursAvant)),
      score: score,
      dureeSecondes: 30,
    );
    return DatabaseService.instance.enregistrerTentative(tentative).then((_) => tentative);
  }

  testWidgets('le graphique et le résumé apparaissent avec des tentatives simulées',
      (tester) async {
    final auth = AuthProvider();
    // La préparation (inscription + tentatives simulées) exécute de vraies
    // opérations asynchrones (accès sqflite) : sans tester.runAsync, le
    // zonage « fake async » de testWidgets ne les laisse jamais se
    // terminer et le test reste bloqué jusqu'au timeout.
    await tester.runAsync(() async {
      await auth.inscrire('joueur_stats_1', 'motdepasse123');
      final utilisateurId = auth.utilisateurCourant!.id;

      // Simule 3 tentatives passées pour le langage Dart.
      await creerTentative(utilisateurId, 40, 3);
      await creerTentative(utilisateurId, 70, 2);
      await creerTentative(utilisateurId, 90, 1);
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(
          home: StatistiquesScreen(langageIdInitial: 'dart'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Le graphique doit être présent.
    expect(find.byType(LineChart), findsOneWidget);

    // Le résumé doit refléter les tentatives simulées.
    expect(find.textContaining('Meilleur score : 90'), findsOneWidget);
    expect(find.textContaining('3 tentative(s)'), findsOneWidget);
  });

  testWidgets("un message s'affiche quand aucune tentative n'existe pour le langage",
      (tester) async {
    final auth = AuthProvider();
    await tester.runAsync(() => auth.inscrire('joueur_stats_2', 'motdepasse123'));

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(
          home: StatistiquesScreen(langageIdInitial: 'python'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsNothing);
    expect(find.textContaining('Pas encore de tentative'), findsOneWidget);
  });
}
