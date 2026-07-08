import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/questions_data.dart';
import '../providers/quiz_provider.dart';
import 'niveau_screen.dart';

class LangageScreen extends StatelessWidget {
  const LangageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const langages = QuestionsData.langages;

    return Scaffold(
      appBar: AppBar(title: const Text('Choisis un langage')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: langages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final langage = langages[i];
          return Card(
            child: ListTile(
              leading: Text(langage.icone, style: const TextStyle(fontSize: 28)),
              title: Text(langage.nom, style: const TextStyle(fontSize: 18)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                context.read<QuizProvider>().choisirLangage(langage);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NiveauScreen()),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
