# CodeQuiz

Application mobile Flutter permettant d'évaluer son niveau dans différents
langages de programmation via des QCM organisés par niveau de difficulté.

Projet réalisé dans le cadre du module *Développement Mobile — Niveau
Approfondi* (DCLIC / OIF).

## État d'avancement — Étape 5 (réalisation) : débogage et performance

### Comment lancer Flutter DevTools sur ce projet
```
flutter pub get
flutter run                # laisse l'application tourner sur un émulateur/appareil
```
Dans un second terminal, une fois l'application lancée :
```
dart devtools
```
DevTools s'ouvre dans le navigateur. Se connecter à l'application en cours
d'exécution via le lien affiché dans le terminal de `flutter run`
(`A Dart VM Service ... is available at: ...`). Les onglets utiles pour ce
projet : **Performance** (relevé des rebuilds et de la fluidité),
**Inspector** (arbre de widgets, en particulier sur l'écran Quiz) et
**Memory** (vérifier l'absence de fuite lors des allers-retours Historique/
Profil/Statistiques).

### Problèmes identifiés et corrigés à la lecture du code
| Écran | Problème | Correction |
|---|---|---|
| Statistiques | Un nouveau `Future` (donc une nouvelle requête SQL) était créé à **chaque rebuild**, y compris sans changement de langage, à cause d'un appel direct à la base dans `build()`. | Le `Future` est désormais mis en cache dans le state et rechargé uniquement quand le langage sélectionné change. |
| Historique | Même écran reconstruit en `StatelessWidget` avec requête dans `build()` : re-requête à chaque notification d'`AuthProvider`. | Passage en `StatefulWidget` avec `Future` chargé une seule fois dans `initState()`. |
| Profil | Le bouton "Partager mon certificat" déclenchait un `setState` qui reconstruisait tout l'écran, donc **rechargeait tous les badges à chaque partage**. | `Future` des badges mis en cache dans `initState()`, indépendant de l'état de partage. |
| Quiz | Tout l'écran (AppBar, barre de progression, énoncé, 4 cartes, bouton) se reconstruisait à chaque sélection de réponse à cause d'un `context.watch` global. | Écran découpé en sous-widgets (`_QuizOptions`, `_QuizExplanation`, `_QuizActionButton`) : seule la portion concernée se reconstruit désormais lors d'une sélection. |

### Points de vigilance pour la suite (à vérifier concrètement dans DevTools)
- Onglet **Performance** pendant un test complet : confirmer que l'AppBar et la barre de progression de l'écran Quiz n'apparaissent plus en violet (rebuild) lors de la sélection d'une réponse, seulement lors du changement de question.
- Onglet **Inspector**, case "Highlight repaints" : vérifier que seule la carte de réponse tapée clignote, pas l'écran entier.
- Fluidité de la transition Hero (Profil → Statistiques) : pas de saccade pendant l'animation.
- Taille de la base sqflite et nombre de requêtes après plusieurs sessions de test (onglet **Memory** / logs).

### Écoconception (déjà respectée par construction)
- Aucune image lourde chargée (icônes texte/emoji uniquement).
- Le certificat PDF n'est généré qu'à la demande (jamais en arrière-plan).
- La notification du défi quotidien est planifiée une seule fois par jour, pas de polling.

### Ce qu'il reste à faire (étape suivante)
- Préparer le déploiement (icône, App Bundle) et finaliser le dépôt GitHub.

## Structure du projet

```
lib/
├── main.dart
├── models/
│   ├── utilisateur.dart
│   ├── langage.dart
│   ├── niveau.dart
│   ├── question.dart
│   ├── tentative.dart
│   └── badge_model.dart
├── providers/
│   ├── auth_provider.dart
│   └── quiz_provider.dart
├── services/
│   ├── database_service.dart
│   ├── notification_service.dart
│   └── certificate_service.dart
├── data/
│   └── questions_data.dart
└── screens/
    ├── connexion_screen.dart
    ├── inscription_screen.dart
    ├── home_screen.dart
    ├── langage_screen.dart
    ├── niveau_screen.dart
    ├── quiz_screen.dart          → découpé en sous-widgets pour limiter les rebuilds
    ├── result_screen.dart
    ├── history_screen.dart       → Future mis en cache dans initState()
    ├── profile_screen.dart       → Future des badges mis en cache dans initState()
    └── statistiques_screen.dart  → Future rechargé seulement au changement de langage

test/
├── test_helpers/
│   └── db_test_setup.dart
├── quiz_provider_test.dart
├── auth_provider_test.dart
└── widgets/
    ├── quiz_screen_test.dart
    └── statistiques_screen_test.dart

integration_test/
└── parcours_complet_test.dart
```

## Prérequis

- Flutter SDK (canal stable, >= 3.x)
- Un émulateur Android/iOS ou un appareil physique

## Installation

```bash
flutter pub get
flutter run
```

## Technologies

- Flutter / Dart
- Provider (gestion d'état)
- crypto (hachage du mot de passe)
- sqflite + path (stockage local persistant)
- fl_chart (tableau de bord de progression animé)
- flutter_local_notifications + timezone (rappel du défi quotidien)
- pdf + path_provider + share_plus (certificat de compétence partageable)
