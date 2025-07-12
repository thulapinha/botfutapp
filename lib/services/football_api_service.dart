import 'package:http/http.dart' as http;
import 'dart:convert';

class FootballApiService {
  static const String _apiKey = 'ffebc5794b0d9f51fd639ac54563b848';
  static const Map<String, String> _headers = {
    'x-apisports-key': _apiKey,
  };
  static const String _baseUrl = 'https://v3.football.api-sports.io';

  /// Busca jogos de HOJE usando data local
  static Future<List<dynamic>> getTodayFixtures() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    print("📡 Buscando jogos do dia (local): $today");

    final url = Uri.parse('$_baseUrl/fixtures?date=$today');
    final resp = await http.get(url, headers: _headers);

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      final list = data['response'] as List<dynamic>;
      print("✅ Fixtures retornadas: ${list.length}");
      return list;
    } else {
      print("❌ Erro ao buscar fixtures: ${resp.statusCode}");
      print("🧾 Corpo da resposta: ${resp.body}");
      throw Exception('Erro ao buscar fixtures');
    }
  }

  /// Busca previsão de um jogo e imprime o JSON bruto para debug
  static Future<Map<String, dynamic>?> getPrediction(int fixtureId) async {
    final url = Uri.parse('$_baseUrl/predictions?fixture=$fixtureId');
    final resp = await http.get(url, headers: _headers);

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      final list = data['response'] as List<dynamic>;

      if (list.isNotEmpty) {
        final prediction = list.first as Map<String, dynamic>;

        // 👇 Imprime o JSON bruto da previsão para debug
        print("📦 JSON da previsão [$fixtureId]: ${jsonEncode(prediction)}");

        return prediction;
      } else {
        print("⚠️ Nenhuma previsão encontrada para fixture $fixtureId");
        return null;
      }
    } else {
      print("❌ Erro ao buscar previsão [$fixtureId]: ${resp.statusCode}");
      print("🧾 Corpo da resposta: ${resp.body}");
      return null;
    }
  }

}
