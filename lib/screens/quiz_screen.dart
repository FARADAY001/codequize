import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/auth_provider.dart';
import '../models/question.dart';
import 'result_screen.dart';

/// Écran de passage du quiz.
///
/// Architecture pensée pour limiter les rebuilds : le widget principal n'écoute que
/// les valeurs qui déterminent la structure globale de l'écran (question
/// en cours, index, chargement). La sélection d'une réponse ne déclenche
/// la reconstruction que des petits widgets `_QuizOptions` et
/// `_QuizActionButton`, pas de l'AppBar, de la barre de progression ni de
/// l'énoncé de la question.
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

    // Ne se reconstruit que lorsque la question change (pas à chaque tape
    // sur une réponse), grâce à context.select ciblé sur indexCourant.
    final indexCourant = context.select<QuizProvider, int>((q) => q.indexCourant);
    final totalQuestions = context.select<QuizProvider, int>((q) => q.questions.length);
    final question = context.select<QuizProvider, Question>((q) => q.questionCourante!);

    return Scaffold(
      appBar: AppBar(title: Text('Question ${indexCourant + 1}/$totalQuestions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: (indexCourant + 1) / totalQuestions),
            const SizedBox(height: 24),
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
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const _QuizMinuteur(),
                    const SizedBox(height: 16),
                    const _QuizOptions(),
                    const _QuizExplanation(),
                  ],
                ),
              ),
            ),
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

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final propositions = quiz.propositionsAffichees;

    return Column(
      children: List.generate(propositions.length, (i) {
        final estChoisie = quiz.reponseChoisie == i;
        final estBonneReponse = quiz.estPositionBonneReponse(i);
        Color? couleur;
        if (quiz.reponseValidee) {
          if (estBonneReponse) {
            couleur = Colors.green.shade100;
          } else if (estChoisie) {
            couleur = Colors.red.shade100;
          }
        } else if (estChoisie) {
          couleur = Colors.indigo.shade50;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            color: couleur,
            child: ListTile(
              title: Text(propositions[i]),
              onTap: () => context.read<QuizProvider>().selectionnerReponse(i),
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

    final secondes = quiz.secondesRestantes;
    final minutes = secondes ~/ 60;
    final reste = secondes % 60;
    return Text(
      'Question suivante dans ${minutes}m${reste.toString().padLeft(2, '0')}s',
      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        quiz.questionCourante!.explication,
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade700),
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
