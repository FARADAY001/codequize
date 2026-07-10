import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'langage_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'quiz_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/quiz_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Planifie le rappel du défi quotidien. Si l'autorisation de
    // notification est refusée, l'application continue de fonctionner
    // normalement.
    NotificationService.instance.demanderAutorisation();
    NotificationService.instance.planifierRappelQuotidien();
  }

  Future<void> _demarrerDefiQuotidien(BuildContext context) async {
    final quiz = context.read<QuizProvider>();
    await quiz.demarrerDefiQuotidien();
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QuizScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nomUtilisateur = auth.utilisateurCourant?.nomUtilisateur ?? '';
    final defiDejaFait = auth.defiDejaFaitAujourdHui;
    final serie = auth.utilisateurCourant?.serieActuelle ?? 0;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CodeQuiz'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () {
              context.read<AuthProvider>().deconnecter();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.code_rounded, color: colorScheme.onPrimaryContainer, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, $nomUtilisateur',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        'Prêt à progresser ?',
                        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Carte du défi quotidien
            Material(
              color: defiDejaFait ? colorScheme.surfaceContainerHigh : colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: defiDejaFait ? null : () => _demarrerDefiQuotidien(context),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: defiDejaFait
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.onTertiaryContainer.withValues(alpha: 0.15),
                        child: Icon(
                          Icons.local_fire_department,
                          color: defiDejaFait ? colorScheme.onSurfaceVariant : Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              defiDejaFait ? 'Défi du jour déjà fait !' : 'Défi du jour',
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              serie > 0
                                  ? 'Série actuelle : $serie jour(s)'
                                  : 'Réponds à une question pour démarrer ta série',
                              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      defiDejaFait
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Commencer un test'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LangageScreen()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Historique'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.person),
              label: const Text('Profil et badges'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
