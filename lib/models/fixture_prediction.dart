class FixturePrediction {
  final int id;
  final String home;
  final String away;
  final DateTime date;
  final double homePct;
  final double awayPct;
  final String advice;

  // 🔄 Novos campos para LivePage
  final String? statusShort;
  final int? elapsedTime;
  final double over15;
  final double xgHome;
  final double xgAway;

  FixturePrediction({
    required this.id,
    required this.home,
    required this.away,
    required this.date,
    required this.homePct,
    required this.awayPct,
    required this.advice,
    this.statusShort,
    this.elapsedTime,
    required this.over15,
    required this.xgHome,
    required this.xgAway,
  });

  factory FixturePrediction.fromApiJson(
      Map<String, dynamic> fx,
      Map<String, dynamic> resp,
      ) {
    final home = fx['teams']['home']['name'] as String;
    final away = fx['teams']['away']['name'] as String;
    final date = DateTime.parse(fx['fixture']['date'] as String).toLocal();

    final fStatus = fx['fixture']['status'] as Map<String, dynamic>? ?? {};
    final short = fStatus['short'] as String?;
    final elapsed = fStatus['elapsed'] as int?;

    final p = resp['predictions'] as Map<String, dynamic>;
    final percent = p['percent'] as Map<String, dynamic>? ?? {};

    double parsePct(dynamic v) {
      if (v == null) return 0;
      final s = v.toString().replaceAll('%', '').trim();
      return double.tryParse(s) ?? 0;
    }

    final over15 = double.tryParse(
      p['under_over']?['goals']?['over_1_5']?['percentage']?.toString() ?? '0',
    ) ?? 0;

    final xgHome = double.tryParse(
      p['xGoals']?['home']?['total']?.toString() ?? '0',
    ) ?? 0;

    final xgAway = double.tryParse(
      p['xGoals']?['away']?['total']?.toString() ?? '0',
    ) ?? 0;

    return FixturePrediction(
      id: fx['fixture']['id'] as int,
      home: home,
      away: away,
      date: date,
      homePct: parsePct(percent['home']),
      awayPct: parsePct(percent['away']),
      advice: (p['advice'] as String?) ?? '',
      statusShort: short,
      elapsedTime: elapsed,
      over15: over15,
      xgHome: xgHome,
      xgAway: xgAway,
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
      statusShort: json['statusShort'] as String?,
      elapsedTime: json['elapsedTime'] as int?,
      over15: (json['over15'] ?? 0).toDouble(),
      xgHome: (json['xgHome'] ?? 0).toDouble(),
      xgAway: (json['xgAway'] ?? 0).toDouble(),
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
      'statusShort': statusShort,
      'elapsedTime': elapsedTime,
      'over15': over15,
      'xgHome': xgHome,
      'xgAway': xgAway,
    };
  }
}
