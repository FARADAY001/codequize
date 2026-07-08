import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tentative.dart';
import '../models/niveau.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../data/questions_data.dart';

/// Écran d'historique des tentatives, alimenté par la base sqflite locale :
/// seules les tentatives de l'utilisateur connecté sont affichées.
///
/// StatefulWidget avec Future mis en cache dans initState() plutôt que
/// StatelessWidget interrogeant la base à chaque build() : l'identifiant
/// de l'utilisateur ne change pas pendant que cet écran est ouvert, donc
/// une seule requête suffit.
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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Aucune tentative enregistrée pour le moment.\n"
                  "Lance un test depuis l'accueil pour commencer !",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tentatives.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final t = tentatives[i];
              return Card(
                child: ListTile(
                  title: Text('${QuestionsData.nomLangage(t.langageId)} — ${t.niveau.libelle}'),
                  subtitle: Text(_formaterDate(t.date)),
                  trailing: Text(
                    '${t.score} %',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
