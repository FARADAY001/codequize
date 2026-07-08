import 'dart:math';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:codequiz/services/database_service.dart';

/// Nom de fichier unique à cet isolate de test (calculé une seule fois par
/// fichier de test). `flutter test` exécute plusieurs fichiers de test en
/// parallèle, chacun dans son propre isolate : sans un nom distinct, ils se
/// disputeraient tous le même fichier 'codequiz.db' et provoqueraient des
/// erreurs SqfliteFfiException « database is locked ».
final String _nomFichierDbTest =
    'codequiz_test_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 32)}.db';

/// Initialise sqflite en mode FFI pour pouvoir exécuter les tests sur la
/// machine de développement (sans émulateur), et repart d'une base vide.
///
/// À appeler dans setUpAll() une fois par fichier de test, puis
/// DatabaseService.instance.reinitialiserPourTests() dans setUp() avant
/// chaque test pour repartir d'un état propre.
Future<void> initialiserDbPourTests() async {
  sqfliteFfiInit();
  // databaseFactoryFfiNoIsolate (et non databaseFactoryFfi) : la variante
  // par isolate dédié provoque un blocage (timeout 10 min sur
  // dart:isolate _RawReceivePort._handleMessage) dès qu'elle est utilisée
  // depuis un testWidgets, la communication inter-isolate n'étant pas
  // compatible avec le binding de test de flutter_test. La variante
  // « no isolate » exécute le SQL sur l'isolate courant et évite le
  // problème, sans changer le comportement pour les tests unitaires.
  databaseFactory = databaseFactoryFfiNoIsolate;
  DatabaseService.nomFichierPourTests = _nomFichierDbTest;
  await DatabaseService.instance.reinitialiserPourTests();
}
