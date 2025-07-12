import 'package:flutter/material.dart';
import '../services/football_api_service.dart';
import '../services/pre_live_service.dart';

class LivePage extends StatefulWidget {
  const LivePage({Key? key}) : super(key: key);

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  late Future<List<Map<String, dynamic>>> _liveMatches;

  @override
  void initState() {
    super.initState();
    _liveMatches = _loadLiveMatches();
  }

  Future<List<Map<String, dynamic>>> _loadLiveMatches() async {
    final preLiveList = await PreLiveService.getPreLive();
    final preLiveIds = preLiveList.map((e) => e.id).toSet();
    final fixtures = await FootballApiService.getTodayFixtures();
    final List<Map<String, dynamic>> filtered = [];

    const liveStatuses = ['1H', '2H', 'ET', 'P', 'LIVE', 'HT'];
    int predictionCalls = 0;
    const maxCalls = 5;

    for (var fx in fixtures) {
      final fid = fx['fixture']['id'] as int;
      final status = fx['fixture']['status']['short'] as String? ?? '';

      if (!liveStatuses.contains(status)) {
        print('⛔ Ignorado (status não ao vivo): $fid status=$status');
        continue;
      }

      if (!preLiveIds.contains(fid)) {
        print('⛔ Ignorado (não está no pré-live): $fid');
        continue;
      }

      if (predictionCalls >= maxCalls) {
        print('⚠️ Limite de chamadas atingido ($maxCalls)');
        break;
      }

      predictionCalls++;
      final pred = await FootballApiService.getPrediction(fid);
      if (pred == null) {
        print('❌ Sem previsão para $fid');
        continue;
      }

      final p = pred['predictions'] as Map<String, dynamic>? ?? {};
      final over15 = double.tryParse(
        p['under_over']?['goals']?['over_1_5']?['percentage']?.toString() ??
            '0',
      ) ??
          0;
      final xgHome = double.tryParse(
        p['xGoals']?['home']?['total']?.toString() ?? '0',
      ) ??
          0;
      final xgAway = double.tryParse(
        p['xGoals']?['away']?['total']?.toString() ?? '0',
      ) ??
          0;

      if (over15 >= 60 || (xgHome + xgAway) >= 1.0) {
        print('✅ Adicionado: ${fx['teams']['home']['name']} x ${fx['teams']['away']['name']}');
        filtered.add({
          'home': fx['teams']['home']['name'],
          'away': fx['teams']['away']['name'],
          'time': fx['fixture']['status']['elapsed'],
          'over15': over15,
          'xgSum': xgHome + xgAway,
        });
      } else {
        print('⛔ Ignorado (over15=$over15 xG=${(xgHome + xgAway).toStringAsFixed(2)})');
      }
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _liveMatches,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erro: ${snap.error}'));
        }
        final matches = snap.data ?? [];
        if (matches.isEmpty) {
          return const Center(child: Text('Nenhum jogo ao vivo com potencial.'));
        }
        return ListView.builder(
          itemCount: matches.length,
          itemBuilder: (ctx, i) {
            final m = matches[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text("${m['home']} x ${m['away']}"),
                subtitle: Text("⏱️ ${m['time']} min"),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("📊 Over1.5: ${m['over15'].toStringAsFixed(0)}%"),
                    Text("⚽ xG: ${m['xgSum'].toStringAsFixed(2)}"),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
