// lib/models/fixture_prediction.dart

class FixturePrediction {
  final int id;
  final String home;
  final String away;
  final DateTime date;
  final double homePct;
  final double awayPct;
  final String advice;

  FixturePrediction({
    required this.id,
    required this.home,
    required this.away,
    required this.date,
    required this.homePct,
    required this.awayPct,
    required this.advice,
  });

  factory FixturePrediction.fromApiJson(
      Map<String, dynamic> fx,
      Map<String, dynamic> resp,
      ) {
    final home = fx['teams']['home']['name'] as String;
    final away = fx['teams']['away']['name'] as String;
    final date = DateTime.parse(fx['fixture']['date'] as String).toLocal();

    final p = resp['predictions'] as Map<String, dynamic>;
    final percent = p['percent'] as Map<String, dynamic>? ?? {};

    double parsePct(dynamic v) {
      if (v == null) return 0;
      final s = v.toString().replaceAll('%', '').trim();
      return double.tryParse(s) ?? 0;
    }

    return FixturePrediction(
      id: fx['fixture']['id'] as int,
      home: home,
      away: away,
      date: date,
      homePct: parsePct(percent['home']),
      awayPct: parsePct(percent['away']),
      advice: (p['advice'] as String?) ?? '',
    );
  }

  factory FixturePrediction.fromJson(Map<String, dynamic> json) {
    return FixturePrediction(
      id: json['id'] as int,
      home: json['home'] as String,
      away: json['away'] as String,
      date: DateTime.parse(json['date'] as String),
      homePct: (json['homePct'] as num).toDouble(),
      awayPct: (json['awayPct'] as num).toDouble(),
      advice: json['advice'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'home': home,
      'away': away,
      'date': date.toIso8601String(),
      'homePct': homePct,
      'awayPct': awayPct,
      'advice': advice,
    };
  }
}
