// bin/scheduler.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ─── DADOS DA API E DO BOT TELEGRAM ─────────────────────────────────────────
const String _botToken     = '7854661345:AAEzg74OEidhdWB7_uJ9hefKdoBlGCV94f4';
const String _chatId       = '709273579';
const String _apiKey       = 'ffebc5794b0d9f51fd639ac54563b848';

const Map<String, String> _headers = {
  'x-apisports-key': _apiKey,
};

const String _baseUrl      = 'https://v3.football.api-sports.io';
const String _prelivePath  = '/predictions';  // endpoint de pré-live
const String _fixturesPath = '/fixtures';     // endpoint de resultados

String get _telegramUrl =>
    'https://api.telegram.org/bot$_botToken/sendMessage';
// ────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  final now   = DateTime.now();
  final today = now.toIso8601String().split('T').first;

  // 1) Busca pré-live (predictions) para hoje
  final preliveUrl = Uri.parse('$_baseUrl$_prelivePath?date=$today');
  final prResp     = await http.get(preliveUrl, headers: _headers);

  if (prResp.statusCode != 200) {
    stderr.writeln(
        'Erro ao buscar pré-live (${prResp.statusCode}): ${prResp.body}'
    );
    exit(1);
  }

  final List prelist = (jsonDecode(prResp.body)['response'] as List);
  final fixtures = prelist.map((e) => Fixture.fromJson(e)).toList();

  // Se não houver jogos hoje, encerra sem erro
  if (fixtures.isEmpty) {
    print('Não há jogos hoje. Encerrando scheduler.');
    return;
  }

  final sentTips = <int>{};
  final sentRes  = <int>{};

  // 2) Agenda envio de tip 30 minutos antes de cada jogo
  for (final m in fixtures) {
    final sendAt = m.date.subtract(const Duration(minutes: 30));
    final diff   = sendAt.difference(now);
    if (diff.isNegative) continue;

    Timer(diff, () async {
      if (sentTips.contains(m.id)) return;
      final best = m.homePct >= m.awayPct ? 'Casa vence' : 'Fora vence';
      final msg  = """
🎯 *BotFut Tip*
${m.home} x ${m.away}
📌 Sugestão: $best
""";
      await _sendTelegram(msg);
      sentTips.add(m.id);
      stdout.writeln('Tip enviada para jogo ${m.id} em ${DateTime.now()}');
    });
  }

  // 3) Polling a cada 5 minutos para reportar resultados
  final ticker = Timer.periodic(const Duration(minutes: 5), (timer) async {
    final fxUrl  = Uri.parse('$_baseUrl$_fixturesPath?date=$today');
    final fxResp = await http.get(fxUrl, headers: _headers);

    if (fxResp.statusCode != 200) {
      stderr.writeln(
          'Erro ao buscar fixtures (${fxResp.statusCode})'
      );
      return;
    }

    final List fxList = (jsonDecode(fxResp.body)['response'] as List);

    for (final m in fixtures) {
      if (sentRes.contains(m.id) || m.date.isAfter(DateTime.now())) continue;

      final fx = fxList.firstWhere(
            (f) => (f['fixture']['id'] as int) == m.id,
        orElse: () => null,
      );
      if (fx == null) continue;

      final status = fx['fixture']['status']['short'] as String? ?? '';
      if (!['FT', 'AET', 'PEN'].contains(status)) continue;

      final hg    = (fx['goals']['home'] ?? 0) as int;
      final ag    = (fx['goals']['away'] ?? 0) as int;
      final best  = m.homePct >= m.awayPct ? 'Casa vence' : 'Fora vence';
      final green = (best == 'Casa vence' && hg > ag) ||
          (best == 'Fora vence' && ag > hg);
      final res   = green ? '✅ GREEN' : '❌ RED';
      final msg   = """
📊 *BotFut Resultado*
${m.home} $hg x $ag ${m.away}
📌 Previsão: $best
🎯 Resultado: $res
""";
      await _sendTelegram(msg);
      sentRes.add(m.id);
      stdout.writeln(
          'Resultado enviado para jogo ${m.id} em ${DateTime.now()}'
      );
    }

    // Se todos resultados forem enviados, cancela o polling
    if (sentRes.length == fixtures.length) {
      timer.cancel();
    }
  });

  // 4) Mantém o script vivo até 1h após o último jogo
  final last = fixtures
      .map((m) => m.date)
      .reduce((a, b) => a.isAfter(b) ? a : b);
  final delay = last.difference(now) + const Duration(hours: 1);
  await Future.delayed(delay);

  if (ticker.isActive) ticker.cancel();
  stdout.writeln('Scheduler finalizado em ${DateTime.now()}');
}

Future<void> _sendTelegram(String text) async {
  final resp = await http.post(
    Uri.parse(_telegramUrl),
    body: {
      'chat_id': _chatId,
      'text': text,
      'parse_mode': 'Markdown',
    },
  );
  if (resp.statusCode != 200) {
    stderr.writeln(
        'Erro ao enviar Telegram (${resp.statusCode}): ${resp.body}'
    );
  }
}

class Fixture {
  final int id;
  final String home, away;
  final DateTime date;
  final double homePct, awayPct;

  Fixture({
    required this.id,
    required this.home,
    required this.away,
    required this.date,
    required this.homePct,
    required this.awayPct,
  });

  factory Fixture.fromJson(Map json) {
    final f = json['fixture'] as Map<String, dynamic>;
    final p = (json['predictions'] as List).first as Map<String, dynamic>;
    return Fixture(
      id: f['id'] as int,
      home: f['teams']['home']['name'] as String,
      away: f['teams']['away']['name'] as String,
      date: DateTime.parse(f['date'] as String),
      homePct: (p['home'] as num).toDouble(),
      awayPct: (p['away'] as num).toDouble(),
    );
  }
}
