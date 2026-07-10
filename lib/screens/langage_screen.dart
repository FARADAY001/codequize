import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/questions_data.dart';
import '../providers/quiz_provider.dart';
import '../theme/app_theme.dart';
import 'niveau_screen.dart';

class LangageScreen extends StatelessWidget {
  const LangageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const langages = QuestionsData.langages;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Choisis un langage')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: langages.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) {
          final langage = langages[i];
          return Material(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                context.read<QuizProvider>().choisirLangage(langage);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NiveauScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(langage.icone, style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        langage.nom,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
