import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'inscription_screen.dart';

class ConnexionScreen extends StatefulWidget {
  const ConnexionScreen({super.key});

  @override
  State<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends State<ConnexionScreen> {
  final _nomController = TextEditingController();
  final _motDePasseController = TextEditingController();
  bool _motDePasseVisible = false;

  @override
  void dispose() {
    _nomController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  Future<void> _seConnecter(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    // Pas de navigation manuelle ici : AuthGate observe
    // AuthProvider.estConnecte et bascule seul vers HomeScreen dès que la
    // connexion réussit. 
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Connexion'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(Icons.code_rounded, size: 48, color: colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'CodeQuiz',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Teste et progresse en programmation',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _nomController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: "Nom d'utilisateur",
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _motDePasseController,
              obscureText: !_motDePasseVisible,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => enCours ? null : _seConnecter(context),
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_motDePasseVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _motDePasseVisible = !_motDePasseVisible),
                ),
              ),
            ),
            if (erreur != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.onErrorContainer, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        erreur,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: enCours ? null : () => _seConnecter(context),
              child: enCours
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Se connecter'),
            ),
            const SizedBox(height: AppSpacing.sm),
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
