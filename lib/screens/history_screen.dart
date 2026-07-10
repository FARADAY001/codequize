import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tentative.dart';
import '../models/niveau.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../data/questions_data.dart';
import '../theme/app_theme.dart';
import '../theme/niveau_style.dart';

/// Écran d'historique des tentatives, alimenté par la base sqflite locale :
/// seules les tentatives de l'utilisateur connecté sont affichées.

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final Future<List<Tentative>> _futureTentatives;

  @override
  void initState() {
    super.initState();
    final utilisateurId = context.read<AuthProvider>().utilisateurCourant?.id;
    _futureTentatives = utilisateurId == null
        ? Future.value(<Tentative>[])
        : DatabaseService.instance.obtenirTentatives(utilisateurId);
  }

  String _formaterDate(DateTime date) {
    final j = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$j/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: FutureBuilder<List<Tentative>>(
        future: _futureTentatives,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tentatives = snapshot.data ?? [];
          if (tentatives.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 56, color: colorScheme.onSurfaceVariant),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      "Aucune tentative enregistrée pour le moment.\n"
                      "Lance un test depuis l'accueil pour commencer !",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: tentatives.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final t = tentatives[i];
              final couleur = t.niveau.couleur;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: couleur.withValues(alpha: 0.15),
                    child: Icon(t.niveau.icone, color: couleur, size: 20),
                  ),
                  title: Text(
                    '${QuestionsData.nomLangage(t.langageId)} — ${t.niveau.libelle}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(_formaterDate(t.date)),
                  trailing: Text(
                    '${t.score}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: t.score >= 70 ? Colors.green : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
