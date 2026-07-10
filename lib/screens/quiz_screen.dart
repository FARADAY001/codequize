import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/auth_provider.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

/// Écran de passage du quiz.

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chargementEnCours = context.select<QuizProvider, bool>((q) => q.chargementEnCours);
    final questionsVides = context.select<QuizProvider, bool>((q) => q.questions.isEmpty);
    final quizTermine = context.select<QuizProvider, bool>((q) => q.quizTermine);

    if (chargementEnCours) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (questionsVides) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              "Pas encore de questions pour ce niveau. Reviens bientôt !",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (quizTermine) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final quiz = context.read<QuizProvider>();
        final auth = context.read<AuthProvider>();
        final utilisateurId = auth.utilisateurCourant?.id;
        if (utilisateurId != null) {
          await quiz.enregistrerResultat(utilisateurId);
          if (!context.mounted) return;
          if (quiz.estDefiQuotidien) {
            await auth.enregistrerParticipationDefi();
            if (!context.mounted) return;
          }
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ResultScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

  
    final indexCourant = context.select<QuizProvider, int>((q) => q.indexCourant);
    final totalQuestions = context.select<QuizProvider, int>((q) => q.questions.length);
    final question = context.select<QuizProvider, Question>((q) => q.questionCourante!);

    return Scaffold(
      appBar: AppBar(title: Text('Question ${indexCourant + 1}/$totalQuestions')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (indexCourant + 1) / totalQuestions,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Contenu scrollable : une question, ses propositions et son
            // explication peuvent dépasser la hauteur disponible (questions
            // longues, petits écrans), ce qui provoquait un débordement
            // (RenderFlex overflowed) avec un Column non scrollable.
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.enonce,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _QuizMinuteur(),
                    const SizedBox(height: AppSpacing.md),
                    const _QuizOptions(),
                    const _QuizExplanation(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const _QuizActionButton(),
          ],
        ),
      ),
    );
  }
}

/// Liste des propositions de réponse. Isolée dans son propre widget afin
/// que seule cette portion de l'écran se reconstruise lors de la sélection
/// d'une réponse (context.watch limité à ce sous-arbre).
///
/// L'ordre des propositions est mélangé côté [QuizProvider] et re-mélangé
/// automatiquement toutes les minutes tant que la réponse n'est pas
/// validée : ce widget affiche donc toujours `propositionsAffichees`,
/// jamais `question.propositions` directement.
class _QuizOptions extends StatelessWidget {
  const _QuizOptions();

  static const _lettres = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final propositions = quiz.propositionsAffichees;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: List.generate(propositions.length, (i) {
        final estChoisie = quiz.reponseChoisie == i;
        final estBonneReponse = quiz.estPositionBonneReponse(i);

        Color fond = colorScheme.surfaceContainerHigh;
        Color accent = colorScheme.outlineVariant;
        Color badgeFond = colorScheme.surfaceContainerHighest;
        Color badgeTexte = colorScheme.onSurfaceVariant;
        IconData? icone;

        if (quiz.reponseValidee) {
          if (estBonneReponse) {
            fond = Colors.green.withValues(alpha: 0.12);
            accent = Colors.green;
            badgeFond = Colors.green;
            badgeTexte = Colors.white;
            icone = Icons.check_rounded;
          } else if (estChoisie) {
            fond = Colors.red.withValues(alpha: 0.12);
            accent = Colors.red;
            badgeFond = Colors.red;
            badgeTexte = Colors.white;
            icone = Icons.close_rounded;
          }
        } else if (estChoisie) {
          fond = colorScheme.primaryContainer;
          accent = colorScheme.primary;
          badgeFond = colorScheme.primary;
          badgeTexte = colorScheme.onPrimary;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Card(
            color: fond,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: accent, width: estChoisie || (quiz.reponseValidee && estBonneReponse) ? 1.5 : 1),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.read<QuizProvider>().selectionnerReponse(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: badgeFond,
                      child: icone != null
                          ? Icon(icone, size: 16, color: badgeTexte)
                          : Text(
                              _lettres[i % _lettres.length],
                              style: TextStyle(color: badgeTexte, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(propositions[i], style: const TextStyle(fontSize: 15))),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Compte à rebours avant le passage automatique à la question suivante.
/// Isolé pour ne reconstruire que ce petit texte à chaque tic (1 seconde),
/// pas le reste de l'écran.
class _QuizMinuteur extends StatelessWidget {
  const _QuizMinuteur();

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    if (quiz.reponseValidee) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final secondes = quiz.secondesRestantes;
    final urgent = secondes <= 10;
    final minutes = secondes ~/ 60;
    final reste = secondes % 60;
    final texte = minutes > 0
        ? '${minutes}m${reste.toString().padLeft(2, '0')}s'
        : '${reste}s';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: urgent ? colorScheme.errorContainer : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 14,
              color: urgent ? colorScheme.onErrorContainer : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Suivant dans $texte',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: urgent ? colorScheme.onErrorContainer : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Explication affichée après validation. Isolée pour ne pas forcer un
/// rebuild du reste de l'écran tant que la réponse n'est pas validée.
class _QuizExplanation extends StatelessWidget {
  const _QuizExplanation();

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    if (!quiz.reponseValidee || quiz.questionCourante == null) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, size: 20, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                quiz.questionCourante!.explication,
                style: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton Valider / Suivant. Isolé pour ne se reconstruire que lorsque
/// la sélection ou la validation change, pas le reste de l'écran.
class _QuizActionButton extends StatelessWidget {
  const _QuizActionButton();

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: quiz.reponseChoisie == null
            ? null
            : () {
                final provider = context.read<QuizProvider>();
                if (!quiz.reponseValidee) {
                  provider.validerReponse();
                } else {
                  provider.questionSuivante();
                }
              },
        child: Text(quiz.reponseValidee ? 'Suivant' : 'Valider'),
      ),
    );
  }
}
