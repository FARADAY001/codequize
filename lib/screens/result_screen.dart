import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/auth_provider.dart';
import '../services/certificate_service.dart';
import '../theme/app_theme.dart';
import '../theme/niveau_style.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _partageEnCours = false;

  Future<void> _partagerCertificat(BuildContext context) async {
    final quiz = context.read<QuizProvider>();
    final auth = context.read<AuthProvider>();
    final niveau = quiz.niveauSelectionne;
    final langage = quiz.langageSelectionne;
    final nomUtilisateur = auth.utilisateurCourant?.nomUtilisateur;

    if (niveau == null || langage == null || nomUtilisateur == null) return;

    setState(() => _partageEnCours = true);
    try {
      await CertificateService.genererEtPartager(
        nomUtilisateur: nomUtilisateur,
        nomLangage: langage.nom,
        nomNiveau: niveau.nom,
        dateObtention: DateTime.now(),
      );
    } finally {
      if (mounted) setState(() => _partageEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final score = quiz.scorePourcentage;
    final niveau = quiz.niveauSelectionne;
    final badgeObtenu = niveau != null && score >= niveau.seuilBadge;
    final colorScheme = Theme.of(context).colorScheme;
    final couleurScore = badgeObtenu ? Colors.green : (niveau?.type.couleur ?? colorScheme.primary);

    return Scaffold(
      appBar: AppBar(title: const Text('Résultat')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(couleurScore),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score%',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: couleurScore,
                              ),
                        ),
                        Text(
                          badgeObtenu ? 'Réussi !' : 'Score',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${quiz.langageSelectionne?.nom ?? ""} — ${niveau?.nom ?? ""}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (badgeObtenu) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
                      const SizedBox(height: 8),
                      Text(
                        'Badge débloqué !',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  icon: _partageEnCours
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share),
                  label: const Text('Partager mon certificat'),
                  onPressed: _partageEnCours ? null : () => _partagerCertificat(context),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<QuizProvider>().reinitialiser();
                    // Dépile jusqu'à la route racine (AuthGate/HomeScreen) au
                    // lieu de pushAndRemoveUntil : cette dernière supprimait
                    // la route racine elle-même, ce qui rendait toute
                    // déconnexion ultérieure impossible (AuthGate n'existait
                    // plus dans la pile de navigation).
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text("Retour à l'accueil"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
