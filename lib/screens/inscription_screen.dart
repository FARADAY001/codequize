import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _nomController = TextEditingController();
  final _motDePasseController = TextEditingController();
  final _confirmationController = TextEditingController();
  String? _erreurLocale;
  bool _motDePasseVisible = false;

  @override
  void dispose() {
    _nomController.dispose();
    _motDePasseController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _creerCompte(BuildContext context) async {
    if (_motDePasseController.text != _confirmationController.text) {
      setState(() {
        _erreurLocale = "Les deux mots de passe ne correspondent pas.";
      });
      return;
    }
    setState(() => _erreurLocale = null);

    final auth = context.read<AuthProvider>();
    final succes = await auth.inscrire(
      _nomController.text,
      _motDePasseController.text,
    );

    if (succes && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final erreurAffichee = _erreurLocale ?? auth.erreur;
    final enCours = auth.enCours;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Rejoins CodeQuiz',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Crée ton compte pour suivre ta progression',
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
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_motDePasseVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _motDePasseVisible = !_motDePasseVisible),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _confirmationController,
              obscureText: !_motDePasseVisible,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => enCours ? null : _creerCompte(context),
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            if (erreurAffichee != null) ...[
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
                        erreurAffichee,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: enCours ? null : () => _creerCompte(context),
              child: enCours
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("S'inscrire"),
            ),
          ],
        ),
      ),
    );
  }
}
