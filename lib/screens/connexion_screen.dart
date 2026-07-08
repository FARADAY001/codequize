import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'inscription_screen.dart';

class ConnexionScreen extends StatefulWidget {
  const ConnexionScreen({super.key});

  @override
  State<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends State<ConnexionScreen> {
  final _nomController = TextEditingController();
  final _motDePasseController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  Future<void> _seConnecter(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    // Pas de navigation manuelle ici : AuthGate (main.dart) observe
    // AuthProvider.estConnecte et bascule seul vers HomeScreen dès que la
    // connexion réussit. Naviguer en plus ici retirerait AuthGate de la
    // pile et empêcherait la déconnexion ultérieure de fonctionner.
    await auth.connecter(
      _nomController.text,
      _motDePasseController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final erreur = auth.erreur;
    final enCours = auth.enCours;

    return Scaffold(
      appBar: AppBar(title: const Text('Connexion'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.code, size: 72, color: Colors.indigo),
            const SizedBox(height: 8),
            const Text(
              'CodeQuiz',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: "Nom d'utilisateur",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _motDePasseController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
            if (erreur != null) ...[
              const SizedBox(height: 12),
              Text(
                erreur,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: enCours ? null : () => _seConnecter(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: enCours
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Se connecter'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                context.read<AuthProvider>().effacerErreur();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InscriptionScreen()),
                );
              },
              child: const Text('Pas encore de compte ? Créer un compte'),
            ),
          ],
        ),
      ),
    );
  }
}
