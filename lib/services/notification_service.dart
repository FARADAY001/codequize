import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Gère la notification locale de rappel du défi quotidien.
///
/// Fonctionnement hors ligne total : aucune dépendance à un serveur, la
/// notification est planifiée localement sur l'appareil (voir dossier de
/// conception technique, section 3.3).
class NotificationService {
  NotificationService._interne();
  static final NotificationService instance = NotificationService._interne();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialise = false;

  Future<void> initialiser() async {
    if (_initialise) return;
    tz_data.initializeTimeZones();
    // Simplification assumée pour ce projet : on utilise UTC comme fuseau
    // de référence plutôt que de détecter le fuseau de l'appareil (ce qui
    // nécessiterait un package supplémentaire). Le rappel se déclenche donc
    // à l'heure indiquée en UTC, et non à l'heure locale de l'utilisateur.
    tz.setLocalLocation(tz.getLocation('UTC'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings);
    _initialise = true;
  }

  /// Demande l'autorisation d'envoyer des notifications (Android 13+ / iOS).
  /// Si l'autorisation est refusée, l'application continue de fonctionner
  /// normalement : seule la notification de rappel ne sera pas affichée.
  Future<void> demanderAutorisation() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Planifie (ou replanifie) le rappel quotidien à l'heure donnée.
  Future<void> planifierRappelQuotidien({int heure = 18, int minute = 0}) async {
    await initialiser();

    final maintenant = tz.TZDateTime.now(tz.local);
    var prochaineOccurrence = tz.TZDateTime(
      tz.local,
      maintenant.year,
      maintenant.month,
      maintenant.day,
      heure,
      minute,
    );
    if (prochaineOccurrence.isBefore(maintenant)) {
      prochaineOccurrence = prochaineOccurrence.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'defi_quotidien',
        'Défi quotidien',
        channelDescription: 'Rappel pour faire le défi du jour dans CodeQuiz',
        importance: Importance.defaultImportance,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      1,
      'Défi du jour disponible',
      'Une nouvelle question t\'attend dans CodeQuiz !',
      prochaineOccurrence,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> annulerRappel() async {
    await _plugin.cancel(1);
  }
}
