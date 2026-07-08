import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/badge_model.dart';
import '../models/niveau.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../services/certificate_service.dart';
import '../data/questions_data.dart';
import 'statistiques_screen.dart';

/// Écran de profil et badges, alimenté par la base sqflite locale :
/// seuls les badges de l'utilisateur connecté sont affichés. Permet
/// aussi de partager un certificat et d'ouvrir le tableau de bord de
/// progression (Statistiques) pour un langage donné.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _partageEnCoursBadgeId;
  late final Future<List<BadgeModel>> _futureBadges;

  @override
  void initState() {
    super.initState();
    final utilisateurId = context.read<AuthProvider>().utilisateurCourant?.id;
    _futureBadges = utilisateurId == null
        ? Future.value(<BadgeModel>[])
        : DatabaseService.instance.obtenirBadges(utilisateurId);
  }

  Future<void> _partagerCertificat(BadgeModel badge) async {
    final nomUtilisateur = context.read<AuthProvider>().utilisateurCourant?.nomUtilisateur;
    if (nomUtilisateur == null) return;

    setState(() => _partageEnCoursBadgeId = badge.id);
    try {
      await CertificateService.genererEtPartager(
        nomUtilisateur: nomUtilisateur,
        nomLangage: QuestionsData.nomLangage(badge.langageId),
        nomNiveau: badge.niveau.libelle,
        dateObtention: badge.dateObtention,
      );
    } finally {
      if (mounted) setState(() => _partageEnCoursBadgeId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final utilisateurId = context.read<AuthProvider>().utilisateurCourant?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil et badges')),
      body: utilisateurId == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistiques par langage',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Appuie sur un langage pour voir ta progression.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 96,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: QuestionsData.langages.map((langage) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StatistiquesScreen(langageIdInitial: langage.id),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Hero(
                                  tag: 'langage-${langage.id}',
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.indigo.shade50,
                                    child: Text(langage.icone, style: const TextStyle(fontSize: 22)),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(langage.nom, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Mes badges',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<BadgeModel>>(
                    future: _futureBadges,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final badges = snapshot.data ?? [];
                      if (badges.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            "Aucun badge débloqué pour le moment.\n"
                            "Réussis un test pour commencer à en gagner !",
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return Column(
                        children: badges.map((badge) {
                          final estSerie = badge.type == TypeBadge.serie;
                          final enCours = _partageEnCoursBadgeId == badge.id;
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                estSerie ? Icons.local_fire_department : Icons.emoji_events,
                                color: estSerie ? Colors.deepOrange : Colors.amber,
                              ),
                              title: Text(
                                estSerie ? 'Série de 7 jours' : QuestionsData.nomLangage(badge.langageId),
                              ),
                              subtitle: Text(estSerie ? 'Défi quotidien' : badge.niveau.libelle),
                              trailing: estSerie
                                  ? null
                                  : IconButton(
                                      icon: enCours
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Icon(Icons.share),
                                      tooltip: 'Partager mon certificat',
                                      onPressed: enCours ? null : () => _partagerCertificat(badge),
                                    ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
