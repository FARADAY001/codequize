import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/auth_provider.dart';
import '../services/certificate_service.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Résultat')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score %',
                style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${quiz.langageSelectionne?.nom} — ${niveau?.nom}',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              if (badgeObtenu) ...[
                const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
                const SizedBox(height: 8),
                const Text(
                  'Badge débloqué !',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: _partageEnCours
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share),
                  label: const Text('Partager mon certificat'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                  onPressed: _partageEnCours ? null : () => _partagerCertificat(context),
                ),
              ],
              const SizedBox(height: 32),
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
