import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/badge_model.dart';
import '../models/niveau.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../services/certificate_service.dart';
import '../data/questions_data.dart';
import '../theme/app_theme.dart';
import 'statistiques_screen.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil et badges')),
      body: utilisateurId == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistiques par langage',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Appuie sur un langage pour voir ta progression.',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 96,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: QuestionsData.langages.map((langage) {
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.md),
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
                                    backgroundColor: colorScheme.primaryContainer,
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
                  const Divider(),
                  Text(
                    'Mes badges',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
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
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          child: Column(
                            children: [
                              Icon(Icons.emoji_events_outlined, size: 48, color: colorScheme.onSurfaceVariant),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                "Aucun badge débloqué pour le moment.\n"
                                "Réussis un test pour commencer à en gagner !",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: badges.map((badge) {
                          final estSerie = badge.type == TypeBadge.serie;
                          final enCours = _partageEnCoursBadgeId == badge.id;
                          final couleur = estSerie ? Colors.deepOrange : Colors.amber;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: couleur.withValues(alpha: 0.15),
                                  child: Icon(
                                    estSerie ? Icons.local_fire_department : Icons.emoji_events,
                                    color: couleur,
                                  ),
                                ),
                                title: Text(
                                  estSerie ? 'Série de 7 jours' : QuestionsData.nomLangage(badge.langageId),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
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
