import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'langage_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'quiz_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/quiz_provider.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Planifie le rappel du défi quotidien. Si l'autorisation de
    // notification est refusée, l'application continue de fonctionner
    // normalement.
    NotificationService.instance.demanderAutorisation();
    NotificationService.instance.planifierRappelQuotidien();
  }

  Future<void> _demarrerDefiQuotidien(BuildContext context) async {
    final quiz = context.read<QuizProvider>();
    await quiz.demarrerDefiQuotidien();
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QuizScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nomUtilisateur = auth.utilisateurCourant?.nomUtilisateur ?? '';
    final defiDejaFait = auth.defiDejaFaitAujourdHui;
    final serie = auth.utilisateurCourant?.serieActuelle ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CodeQuiz'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () {
              context.read<AuthProvider>().deconnecter();
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.code, size: 88, color: Colors.indigo),
              const SizedBox(height: 8),
              Text(
                'Bonjour, $nomUtilisateur',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Teste ton niveau en programmation',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Carte du défi quotidien
              Card(
                color: defiDejaFait ? Colors.grey.shade100 : Colors.amber.shade50,
                child: ListTile(
                  leading: Icon(
                    Icons.local_fire_department,
                    color: defiDejaFait ? Colors.grey : Colors.deepOrange,
                  ),
                  title: Text(
                    defiDejaFait ? 'Défi du jour déjà fait !' : 'Défi du jour',
                  ),
                  subtitle: Text(
                    serie > 0 ? 'Série actuelle : $serie jour(s)' : 'Réponds à une question pour démarrer ta série',
                  ),
                  trailing: defiDejaFait
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: defiDejaFait ? null : () => _demarrerDefiQuotidien(context),
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Commencer un test'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LangageScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('Historique'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.person),
                label: const Text('Profil et badges'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
