import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/niveau.dart';
import '../providers/quiz_provider.dart';
import 'quiz_screen.dart';

class NiveauScreen extends StatelessWidget {
  const NiveauScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Niveau — ${quiz.langageSelectionne?.nom ?? ""}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: Niveau.tous.map((niveau) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: () async {
                  final provider = context.read<QuizProvider>();
                  provider.choisirNiveau(niveau);
                  await provider.demarrerQuiz();
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QuizScreen()),
                    );
                  }
                },
                child: Text(niveau.nom, style: const TextStyle(fontSize: 18)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
