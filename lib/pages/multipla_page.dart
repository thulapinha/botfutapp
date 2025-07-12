import 'package:flutter/material.dart';
import '../models/fixture_prediction.dart';
import '../services/pre_live_service.dart';
import '../services/telegram_service.dart';

class MultiplaPage extends StatefulWidget {
  const MultiplaPage({Key? key}) : super(key: key);

  @override
  State<MultiplaPage> createState() => _MultiplaPageState();
}

class _MultiplaPageState extends State<MultiplaPage> {
  late Future<List<_EntradaSugestao>> _future;

  @override
  void initState() {
    super.initState();
    _future = _gerarMultipla();
  }

  Future<List<_EntradaSugestao>> _gerarMultipla() async {
    final preLive = await PreLiveService.getPreLive();

    final todas = preLive.map((m) {
      final opcoes = {
        'Casa vence': m.homePct,
        'Fora vence': m.awayPct,
      };
      final melhor = opcoes.entries.reduce((a, b) => a.value >= b.value ? a : b);

      return _EntradaSugestao(
        partida: "${m.home} x ${m.away}",
        label: melhor.key,
        pct: melhor.value,
        advice: m.advice,
      );
    }).toList();

    todas.sort((a, b) => b.pct.compareTo(a.pct));
    return todas.take(3).toList(); // pega os 3 melhores disponíveis
  }

  double _pctToOdd(double pct) {
    final prob = pct / 100;
    if (prob <= 0) return 1.01;
    return (1 / prob).clamp(1.01, 10.0);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_EntradaSugestao>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erro: ${snap.error}'));
        }

        final lista = snap.data ?? [];
        if (lista.length < 2) {
          return const Center(child: Text('Poucos jogos disponíveis para múltipla.'));
        }

        final odds = lista.map((e) => _pctToOdd(e.pct)).toList();
        final oddFinal = odds.fold(1.0, (a, b) => a * b);
        final probFinal = lista
            .map((e) => e.pct / 100)
            .fold(1.0, (a, b) => a * b) * 100;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                "🎯 Múltipla com ${lista.length} jogos",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: lista.length,
                itemBuilder: (ctx, i) {
                  final e = lista[i];
                  final cor = e.pct >= 80
                      ? Colors.green.shade800
                      : Colors.orange.shade700;
                  final odd = _pctToOdd(e.pct);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(e.partida),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📌 ${e.label}", style: TextStyle(color: cor, fontWeight: FontWeight.bold)),
                          if (e.advice.isNotEmpty)
                            Text("🧠 ${e.advice}", style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      trailing: Text("🧮 ${odd.toStringAsFixed(2)}"),
                      isThreeLine: e.advice.isNotEmpty,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    "💰 Odd combinada: ${oddFinal.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "🎯 Probabilidade estimada: ${probFinal.toStringAsFixed(1)}%",
                    style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text("Enviar múltipla ao Telegram"),
                    onPressed: () => _enviarMultipla(lista, oddFinal, probFinal),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _enviarMultipla(List<_EntradaSugestao> lista, double oddFinal, double probFinal) {
    final buf = StringBuffer()..writeln("🎯 *BotFut – Múltipla*");
    for (final e in lista) {
      buf.writeln("• ${e.partida}");
      buf.writeln("  ➤ ${e.label}");
      if (e.advice.isNotEmpty) {
        buf.writeln("  🧠 ${e.advice}");
      }
    }
    buf.writeln("💰 Odd combinada: ${oddFinal.toStringAsFixed(2)}");
    buf.writeln("🎯 Probabilidade estimada: ${probFinal.toStringAsFixed(1)}%");

    TelegramService.sendMessage(buf.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Múltipla enviada!")),
    );
  }
}

class _EntradaSugestao {
  final String partida;
  final String label;
  final double pct;
  final String advice;

  _EntradaSugestao({
    required this.partida,
    required this.label,
    required this.pct,
    required this.advice,
  });
}
