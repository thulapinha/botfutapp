import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fixture_prediction.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({Key? key}) : super(key: key);

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  List<String> _datasDisponiveis = [];
  String? _dataSelecionada;
  List<FixturePrediction> _preLiveDoDia = [];
  List<Map<String, dynamic>> _resultadosDoDia = [];

  @override
  void initState() {
    super.initState();
    _carregarDatasSalvas();
  }

  Future<void> _carregarDatasSalvas() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final datas = keys
        .where((k) => k.startsWith('prelive_'))
        .map((k) => k.replaceFirst('prelive_', ''))
        .toSet()
        .toList();

    datas.sort((a, b) => b.compareTo(a)); // mais recentes primeiro

    setState(() {
      _datasDisponiveis = datas;
    });
  }

  Future<void> _carregarDadosDoDia(String data) async {
    final prefs = await SharedPreferences.getInstance();

    final preRaw = prefs.getString('prelive_$data');
    final reportRaw = prefs.getString('report_$data');

    final preList = preRaw != null
        ? (jsonDecode(preRaw) as List<dynamic>)
        .map((e) => FixturePrediction.fromJson(e as Map<String, dynamic>))
        .toList()
        : <FixturePrediction>[];

    final reportList = reportRaw != null
        ? (jsonDecode(reportRaw) as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
        : <Map<String, dynamic>>[];

    setState(() {
      _dataSelecionada = data;
      _preLiveDoDia = preList;
      _resultadosDoDia = reportList;
    });
  }

  Widget _buildResumo(FixturePrediction m) {
    final resultado = _resultadosDoDia.firstWhere(
          (r) => r['match']?.contains(m.home) == true && r['match']?.contains(m.away) == true,
      orElse: () => {},
    );

    final label = _getMelhorEntrada(m).label;
    final result = resultado['result'] ?? '⏳';
    final color = result.toString().contains('GREEN')
        ? Colors.green
        : result.toString().contains('RED')
        ? Colors.red
        : Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text("${m.home} x ${m.away}"),
        subtitle: Text("📌 $label\n📝 ${resultado['reason'] ?? 'Sem resultado'}"),
        trailing: Text(
          result,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        isThreeLine: true,
      ),
    );
  }

  _EntradaSugestao _getMelhorEntrada(FixturePrediction m) {
    final op = {'Casa vence': m.homePct, 'Fora vence': m.awayPct};
    final sel = op.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return _EntradaSugestao(sel.key, sel.value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_datasDisponiveis.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Nenhum histórico salvo ainda.'),
          )
        else
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButton<String>(
              value: _dataSelecionada,
              hint: const Text("Selecione uma data"),
              isExpanded: true,
              items: _datasDisponiveis
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _carregarDadosDoDia(value);
                }
              },
            ),
          ),
        if (_dataSelecionada != null)
          Expanded(
            child: _preLiveDoDia.isEmpty
                ? const Center(child: Text('Nenhum jogo salvo para esse dia.'))
                : ListView.builder(
              itemCount: _preLiveDoDia.length,
              itemBuilder: (ctx, i) => _buildResumo(_preLiveDoDia[i]),
            ),
          ),
      ],
    );
  }
}

class _EntradaSugestao {
  final String label;
  final double pct;
  _EntradaSugestao(this.label, this.pct);
}
