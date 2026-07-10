import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/niveau.dart';
import '../providers/quiz_provider.dart';
import '../theme/app_theme.dart';
import '../theme/niveau_style.dart';
import 'quiz_screen.dart';

class NiveauScreen extends StatelessWidget {
  const NiveauScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final langage = quiz.langageSelectionne;

    return Scaffold(
      appBar: AppBar(title: const Text('Choisis un niveau')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (langage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Row(
                children: [
                  Text(langage.icone, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      langage.nom,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ...Niveau.tous.map((niveau) {
            final couleur = niveau.type.couleur;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Material(
                color: couleur.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    final provider = context.read<QuizProvider>();
                    provider.choisirNiveau(niveau);
                    await provider.demarrerQuiz();
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const QuizScreen()),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: couleur.withValues(alpha: 0.18),
                          child: Icon(niveau.type.icone, color: couleur),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                niveau.nom,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Badge dès ${niveau.seuilBadge}% de bonnes réponses',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: couleur),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
