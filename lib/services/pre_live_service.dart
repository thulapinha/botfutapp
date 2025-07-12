import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fixture_prediction.dart';
import 'football_api_service.dart';

class PreLiveService {
  static const _cacheKey     = 'pre_live_data';
  static const _cacheDateKey = 'pre_live_date';

  // Cache em memória para evitar leituras repetidas
  static List<FixturePrediction>? _memoryCache;
  static String? _memoryDate;

  /// Se forceRefresh=true, ignora cache e busca da API
  static Future<List<FixturePrediction>> getPreLive({bool forceRefresh = false}) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    // 1) Retorna do cache em memória
    if (!forceRefresh &&
        _memoryCache != null &&
        _memoryDate == today) {
      return _memoryCache!;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_cacheDateKey);

    // 2) Se for hoje e houver cache em prefs, carrega dele
    if (!forceRefresh &&
        _memoryCache == null &&
        savedDate == today) {
      final raw = prefs.getString(_cacheKey);
      if (raw != null) {
        final list = (json.decode(raw) as List<dynamic>)
            .map((e) => FixturePrediction.fromJson(e as Map<String, dynamic>))
            .toList();
        _memoryCache = list;
        _memoryDate  = today;
        return list;
      }
    }

    // 3) Caso contrário, busca da API
    final fixtures = await FootballApiService.getTodayFixtures();
    final notStarted = fixtures
        .where((fx) => fx['fixture']['status']['short'] == 'NS')
        .toList();

    final List<FixturePrediction> preds = [];
    for (final fx in notStarted) {
      final id = fx['fixture']['id'] as int;
      final resp = await FootballApiService.getPrediction(id);
      if (resp == null) continue;
      try {
        preds.add(
          FixturePrediction.fromApiJson(fx as Map<String, dynamic>, resp),
        );
      } catch (_) {
        // pula entry mal-formatada
      }
    }

    // 4) Grava cache em prefs e memória
    final rawJson = json.encode(preds.map((e) => e.toJson()).toList());
    await prefs.setString(_cacheKey, rawJson);
    await prefs.setString(_cacheDateKey, today);

    _memoryCache = preds;
    _memoryDate  = today;

    // 5) Também salva uma cópia permanente por data
    final todayKey = 'prelive_$today';
    await prefs.setString(todayKey, rawJson);

    return preds;
  }
}
