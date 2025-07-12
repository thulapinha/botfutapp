import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fixture_prediction.dart';
import '../services/pre_live_service.dart';
import '../services/football_api_service.dart';
import '../services/telegram_service.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late Future<List<Map<String, String>>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _generateReport();
  }

  Future<List<Map<String, String>>> _generateReport() async {
    final preLive = await PreLiveService.getPreLive();
    final fixtures = await FootballApiService.getTodayFixtures();
    final List<Map<String, String>> report = [];

    const endedStatuses = ['FT', 'AET', 'PEN'];
    int encontrados = 0;

    for (final tip in preLive) {
      final fx = fixtures.firstWhere(
            (f) => f['fixture']['id'] == tip.id,
        orElse: () => null,
      );
      if (fx == null) {
        print('❌ Fixture não encontrada para tip.id=${tip.id}');
        continue;
      }

      final status = fx['fixture']['status']['short'] as String? ?? '';
      if (!endedStatuses.contains(status)) {
        print('⏳ Ainda não finalizado: ${tip.id} status=$status');
        continue;
      }

      final home = fx['teams']['home']['name'] as String;
      final away = fx['teams']['away']['name'] as String;
      final goals = fx['goals'] as Map<String, dynamic>? ?? {};
      final homeGoals = (goals['home'] ?? 0) as int;
      final awayGoals = (goals['away'] ?? 0) as int;

      final melhor = _getMelhorEntrada(tip);
      String result = '';
      String reason = '';

      if (melhor.label == 'Casa vence') {
        if (homeGoals > awayGoals) {
          result = '✅ GREEN';
          reason = 'mandante venceu';
        } else {
          result = '❌ RED';
          reason = 'mandante não venceu';
        }
      } else if (melhor.label == 'Fora vence') {
        if (awayGoals > homeGoals) {
          result = '✅ GREEN';
          reason = 'visitante venceu';
        } else {
          result = '❌ RED';
          reason = 'visitante não venceu';
        }
      }

      if (result.isNotEmpty) {
        encontrados++;
        report.add({
          'match': '$home $homeGoals x $awayGoals $away',
          'category': melhor.label,
          'result': result,
          'reason': reason,
        });
      }
    }

    print('📊 Total de jogos finalizados com previsão: $encontrados');

    // ✅ Salva o relatório do dia no shared_preferences
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    await prefs.setString('report_$today', jsonEncode(report));

    return report;
  }

  _EntradaSugestao _getMelhorEntrada(FixturePrediction m) {
    final opcoes = {
      'Casa vence': m.homePct,
      'Fora vence': m.awayPct,
    };
    final melhor = opcoes.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return _EntradaSugestao(melhor.key, melhor.value);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, String>>>(
      future: _reportFuture,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erro: ${snap.error}'));
        }

        final reports = snap.data ?? [];
        if (reports.isEmpty) {
          return const Center(
            child: Text('Nenhum jogo finalizado com previsão registrada.'),
          );
        }

        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (ctx, i) {
            final r = reports[i];
            final isGreen = r['result']!.startsWith('✅');
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text("📋 ${r['category']}"),
                subtitle: Text("${r['match']}\n${r['reason']}"),
                trailing: Text(
                  r['result']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isGreen ? Colors.green : Colors.red,
                  ),
                ),
                isThreeLine: true,
                onTap: () {
                  final msg = """
📊 *BotFut – Relatório*
🏟️ ${r['match']}
📌 Previsão: ${r['category']}
🎯 Resultado: ${r['result']}
📝 Motivo: ${r['reason']}
""";
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("📋 Detalhes do Jogo"),
                      content: Text(msg),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Fechar"),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text("Enviar Telegram"),
                          onPressed: () async {
                            Navigator.pop(context);
                            await TelegramService.sendMessage(msg);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Relatório enviado ao Telegram!"),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _EntradaSugestao {
  final String label;
  final double pct;
  _EntradaSugestao(this.label, this.pct);
}
