import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/connexion_screen.dart';

void main() {
  runApp(const CodeQuizApp());
}

class CodeQuizApp extends StatelessWidget {
  const CodeQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: MaterialApp(
        title: 'CodeQuiz',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Décide de l'écran de démarrage selon qu'une session est active ou non.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final estConnecte = context.watch<AuthProvider>().estConnecte;
    return estConnecte ? const HomeScreen() : const ConnexionScreen();
  }
}
