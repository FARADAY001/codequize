import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/tentative.dart';
import '../data/questions_data.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';

/// Tableau de bord de progression : évolution du score dans le temps
/// pour un langage donné, avec sélecteur de langage et transition Hero
/// depuis l'écran Profil.
class StatistiquesScreen extends StatefulWidget {
  final String langageIdInitial;

  const StatistiquesScreen({super.key, required this.langageIdInitial});

  @override
  State<StatistiquesScreen> createState() => _StatistiquesScreenState();
}

class _StatistiquesScreenState extends State<StatistiquesScreen> {
  late String _langageSelectionneId;
  String? _utilisateurIdCharge;
  Future<List<Tentative>>? _futureTentatives;

  @override
  void initState() {
    super.initState();
    _langageSelectionneId = widget.langageIdInitial;
  }

  String _nomLangage(String langageId) {
    final trouve = QuestionsData.langages.where((l) => l.id == langageId);
    return trouve.isEmpty ? langageId : trouve.first.nom;
  }

  /// Recharge les tentatives uniquement si le langage ou l'utilisateur a
  /// changé, plutôt qu'à chaque rebuild du widget (voir dossier de
  /// conception technique, section 8 : observation des rebuilds inutiles
  /// avec DevTools).
  void _chargerTentativesSiNecessaire(String utilisateurId) {
    if (_futureTentatives != null && _utilisateurIdCharge == '$utilisateurId-$_langageSelectionneId') {
      return;
    }
    _utilisateurIdCharge = '$utilisateurId-$_langageSelectionneId';
    _futureTentatives = DatabaseService.instance.obtenirTentatives(
      utilisateurId,
      langageId: _langageSelectionneId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final utilisateurId = context.watch<AuthProvider>().utilisateurCourant?.id;
    final serieActuelle = context.watch<AuthProvider>().utilisateurCourant?.serieActuelle ?? 0;

    if (utilisateurId != null) {
      _chargerTentativesSiNecessaire(utilisateurId);
    }

    return Scaffold(
      appBar: AppBar(title: Text('Statistiques — ${_nomLangage(_langageSelectionneId)}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Hero(
                tag: 'langage-${widget.langageIdInitial}',
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.indigo.shade50,
                  child: Text(
                    QuestionsData.langages
                        .firstWhere((l) => l.id == widget.langageIdInitial, orElse: () => QuestionsData.langages.first)
                        .icone,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Sélecteur de langage (chips)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: QuestionsData.langages.map((langage) {
                  final selectionne = langage.id == _langageSelectionneId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(langage.nom),
                      selected: selectionne,
                      onSelected: (_) {
                        setState(() => _langageSelectionneId = langage.id);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: utilisateurId == null
                  ? const SizedBox.shrink()
                  : FutureBuilder<List<Tentative>>(
                      key: ValueKey(_langageSelectionneId),
                      future: _futureTentatives,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        // Les tentatives sont triées de la plus récente à la
                        // plus ancienne en base ; on les inverse pour tracer
                        // le graphique dans l'ordre chronologique.
                        final tentatives = (snapshot.data ?? []).reversed.toList();

                        if (tentatives.isEmpty) {
                          return Center(
                            child: Text(
                              "Pas encore de tentative en ${_nomLangage(_langageSelectionneId)}.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        final meilleurScore = tentatives.map((t) => t.score).reduce((a, b) => a > b ? a : b);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeOutCubic,
                                builder: (context, valeur, child) {
                                  return LineChart(
                                    LineChartData(
                                      minY: 0,
                                      maxY: 100,
                                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                                      titlesData: FlTitlesData(
                                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 24,
                                            interval: 1,
                                            getTitlesWidget: (v, meta) => Text(
                                              '${v.toInt() + 1}',
                                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 32,
                                            interval: 25,
                                            getTitlesWidget: (v, meta) => Text(
                                              '${v.toInt()}%',
                                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      lineBarsData: [
                                        LineChartBarData(
                                          isCurved: true,
                                          color: Colors.indigo,
                                          barWidth: 3,
                                          dotData: const FlDotData(show: true),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: Colors.indigo.withValues(alpha: 0.1),
                                          ),
                                          spots: List.generate(tentatives.length, (i) {
                                            return FlSpot(
                                              i.toDouble(),
                                              tentatives[i].score.toDouble() * valeur,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Meilleur score : $meilleurScore %'),
                                    const SizedBox(height: 6),
                                    Text('Série actuelle (défi quotidien) : $serieActuelle jour(s)'),
                                    const SizedBox(height: 6),
                                    Text('${tentatives.length} tentative(s) enregistrée(s)'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
