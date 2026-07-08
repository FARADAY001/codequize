import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:codequiz/main.dart';

/// Test d'intégration prévu au dossier de conception technique:
/// parcours complet inscription → connexion → choix langage/niveau → quiz
/// → résultat → historique.
///
/// Ce test s'exécute sur un émulateur ou un appareil réel (il utilise le
/// vrai plugin sqflite via les canaux de plateforme, pas la version FFI
/// utilisée dans test/) :
///
///   flutter test integration_test/parcours_complet_test.dart
///
/// Un nom d'utilisateur horodaté est généré à chaque exécution pour éviter
/// tout conflit avec une exécution précédente sur le même appareil.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'parcours complet : inscription, connexion, quiz, résultat, historique',
    (tester) async {
      final nomUtilisateur = 'integration_${DateTime.now().millisecondsSinceEpoch}';
      const motDePasse = 'motdepasse123';

      await tester.pumpWidget(const CodeQuizApp());
      await tester.pumpAndSettle();

      // --- Inscription ---------------------------------------------------
      expect(find.text('Connexion'), findsWidgets);
      await tester.tap(find.text('Pas encore de compte ? Créer un compte'));
      await tester.pumpAndSettle();

      final champsInscription = find.byType(TextField);
      await tester.enterText(champsInscription.at(0), nomUtilisateur);
      await tester.enterText(champsInscription.at(1), motDePasse);
      await tester.enterText(champsInscription.at(2), motDePasse);
      await tester.tap(find.text("S'inscrire"));
      await tester.pumpAndSettle();

      // Après inscription, l'utilisateur est automatiquement connecté.
      expect(find.textContaining('Bonjour, $nomUtilisateur'), findsOneWidget);

      // --- Déconnexion puis connexion -------------------------------------
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();
      expect(find.text('Connexion'), findsWidgets);

      final champsConnexion = find.byType(TextField);
      await tester.enterText(champsConnexion.at(0), nomUtilisateur);
      await tester.enterText(champsConnexion.at(1), motDePasse);
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Bonjour, $nomUtilisateur'), findsOneWidget);

      // --- Choix du langage et du niveau, passage du quiz -----------------
      await tester.tap(find.text('Commencer un test'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dart'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Débutant'));
      await tester.pumpAndSettle();

      // Répond à chaque question en sélectionnant toujours la première
      // proposition, puis en validant et en passant à la suivante.
      while (find.text('Valider').evaluate().isNotEmpty) {
        final premiereProposition = find.byType(Card).first;
        await tester.tap(premiereProposition);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Valider'));
        await tester.pumpAndSettle();

        if (find.text('Suivant').evaluate().isNotEmpty) {
          await tester.tap(find.text('Suivant'));
          await tester.pumpAndSettle();
        }
      }

      // --- Écran Résultat --------------------------------------------------
      expect(find.textContaining('%'), findsWidgets);
      await tester.tap(find.text("Retour à l'accueil"));
      await tester.pumpAndSettle();

      // --- Historique : la tentative doit apparaître ----------------------
      await tester.tap(find.text('Historique'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Dart'), findsWidgets);
      expect(find.textContaining('%'), findsWidgets);
    },
  );
}
