import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/utilisateur.dart';
import '../models/question.dart';
import '../models/tentative.dart';
import '../models/badge_model.dart';
import '../models/niveau.dart';
import '../data/questions_data.dart';

/// Point d'accès unique à la base de données locale (sqflite).
///
/// Aucun écran ni provider n'exécute de requête SQL directement :
/// tout passe par ce service, conformément au dossier de conception
/// technique (section 3.1).
class DatabaseService {
  DatabaseService._interne();
  static final DatabaseService instance = DatabaseService._interne();

  /// Nom du fichier de base de données. Ne jamais modifier en dehors des
  /// tests automatisés : test_helpers/db_test_setup.dart lui attribue une
  /// valeur unique par isolate de test, car `flutter test` exécute
  /// plusieurs fichiers de test en parallèle et un nom fixe partagé
  /// provoquerait des verrous SQLite concurrents (« database is locked »).
  static String nomFichierPourTests = 'codequiz.db';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initialiser();
    return _db!;
  }

  /// Réservé aux tests : ferme la base courante et supprime le fichier,
  /// afin que chaque test démarre avec une base vierge (utilisateurs et
  /// tentatives, mais aussi la banque de questions, qui est re-semée à la
  /// prochaine ouverture). Ne jamais appeler cette méthode en dehors des
  /// tests automatisés.
  Future<void> reinitialiserPourTests() async {
    if (_db != null) {
      final chemin = _db!.path;
      await _db!.close();
      await deleteDatabase(chemin);
      _db = null;
    }
  }

  Future<Database> _initialiser() async {
    final chemin = p.join(await getDatabasesPath(), nomFichierPourTests);
    final db = await openDatabase(
      chemin,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE utilisateurs (
            id TEXT PRIMARY KEY,
            nom_utilisateur TEXT UNIQUE NOT NULL,
            mot_de_passe_hache TEXT NOT NULL,
            date_creation TEXT NOT NULL,
            serie_actuelle INTEGER NOT NULL DEFAULT 0,
            meilleure_serie INTEGER NOT NULL DEFAULT 0,
            derniere_date_defi TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE questions (
            id TEXT PRIMARY KEY,
            langage_id TEXT NOT NULL,
            niveau TEXT NOT NULL,
            enonce TEXT NOT NULL,
            propositions TEXT NOT NULL,
            bonne_reponse_index INTEGER NOT NULL,
            explication TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE tentatives (
            id TEXT PRIMARY KEY,
            utilisateur_id TEXT NOT NULL,
            langage_id TEXT NOT NULL,
            niveau TEXT NOT NULL,
            date TEXT NOT NULL,
            score INTEGER NOT NULL,
            duree_secondes INTEGER NOT NULL,
            est_defi_quotidien INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE badges (
            id TEXT PRIMARY KEY,
            utilisateur_id TEXT NOT NULL,
            langage_id TEXT NOT NULL,
            niveau TEXT NOT NULL,
            date_obtention TEXT NOT NULL,
            type TEXT NOT NULL
          )
        ''');
      },
    );

    await _preremplirQuestions(db);
    return db;
  }

  /// Pré-remplit la table `questions` avec toute la banque de référence
  /// ([QuestionsData.questions]) qui n'y est pas déjà (comparaison par id,
  /// conflit ignoré). Appelée à chaque ouverture de la base, pas seulement
  /// à sa création : ainsi, une base déjà existante (installation mise à
  /// jour) reçoit aussi les questions ajoutées depuis, sans réinitialiser
  /// les données de l'utilisateur (tentatives, badges, série).
  Future<void> _preremplirQuestions(Database db) async {
    final batch = db.batch();
    for (final question in QuestionsData.questions) {
      batch.insert(
        'questions',
        question.versMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  // ---------------------------------------------------------- Utilisateurs

  Future<Utilisateur?> obtenirUtilisateurParNom(String nomUtilisateur) async {
    final db = await database;
    final resultats = await db.query(
      'utilisateurs',
      where: 'LOWER(nom_utilisateur) = ?',
      whereArgs: [nomUtilisateur.toLowerCase()],
      limit: 1,
    );
    if (resultats.isEmpty) return null;
    return Utilisateur.depuisMap(resultats.first);
  }

  Future<void> creerUtilisateur(Utilisateur utilisateur) async {
    final db = await database;
    await db.insert('utilisateurs', utilisateur.versMap());
  }

  /// Met à jour les champs d'un utilisateur existant (utilisé notamment
  /// pour la série du défi quotidien).
  Future<void> mettreAJourUtilisateur(Utilisateur utilisateur) async {
    final db = await database;
    await db.update(
      'utilisateurs',
      utilisateur.versMap(),
      where: 'id = ?',
      whereArgs: [utilisateur.id],
    );
  }

  // -------------------------------------------------------------- Questions

  Future<List<Question>> obtenirQuestions(String langageId, NiveauType niveau) async {
    final db = await database;
    final resultats = await db.query(
      'questions',
      where: 'langage_id = ? AND niveau = ?',
      whereArgs: [langageId, niveau.name],
    );
    return resultats.map(Question.depuisMap).toList();
  }

  /// Retourne une question aléatoire toutes langues/niveaux confondus,
  /// utilisée pour le défi quotidien.
  Future<Question?> obtenirQuestionAleatoire() async {
    final db = await database;
    final resultats = await db.query('questions', orderBy: 'RANDOM()', limit: 1);
    if (resultats.isEmpty) return null;
    return Question.depuisMap(resultats.first);
  }

  // ------------------------------------------------------------- Tentatives

  Future<void> enregistrerTentative(Tentative tentative) async {
    final db = await database;
    await db.insert('tentatives', tentative.versMap());
  }

  Future<List<Tentative>> obtenirTentatives(
    String utilisateurId, {
    String? langageId,
  }) async {
    final db = await database;
    final resultats = await db.query(
      'tentatives',
      where: langageId != null
          ? 'utilisateur_id = ? AND langage_id = ?'
          : 'utilisateur_id = ?',
      whereArgs: langageId != null ? [utilisateurId, langageId] : [utilisateurId],
      orderBy: 'date DESC',
    );
    return resultats.map(Tentative.depuisMap).toList();
  }

  // ----------------------------------------------------------------- Badges

  Future<bool> possedeBadge(
    String utilisateurId,
    String langageId,
    NiveauType niveau,
  ) async {
    final db = await database;
    final resultats = await db.query(
      'badges',
      where: 'utilisateur_id = ? AND langage_id = ? AND niveau = ?',
      whereArgs: [utilisateurId, langageId, niveau.name],
      limit: 1,
    );
    return resultats.isNotEmpty;
  }

  Future<void> enregistrerBadge(BadgeModel badge) async {
    final db = await database;
    await db.insert('badges', badge.versMap());
  }

  Future<List<BadgeModel>> obtenirBadges(String utilisateurId) async {
    final db = await database;
    final resultats = await db.query(
      'badges',
      where: 'utilisateur_id = ?',
      whereArgs: [utilisateurId],
      orderBy: 'date_obtention DESC',
    );
    return resultats.map(BadgeModel.depuisMap).toList();
  }
}
