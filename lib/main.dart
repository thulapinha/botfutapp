import 'package:flutter/material.dart';
import 'pages/pre_live_page.dart';
import 'pages/live_page.dart';
import 'pages/report_page.dart';
import 'pages/multipla_page.dart';
import 'pages/historico_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();


  runApp(const BotFutApp());
}

class BotFutApp extends StatelessWidget {
  const BotFutApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BotFut',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    PreLivePage(),
    LivePage(),
    ReportPage(),
    MultiplaPage(),
    HistoricoPage(),
  ];

  static const List<String> _titles = [
    'Pré-Live',
    'Ao Vivo',
    'Relatórios',
    'Múltipla',
    'Histórico',
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BotFut – ${_titles[_selectedIndex]}'),
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Pré-Live',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.live_tv),
            label: 'Ao Vivo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Relatórios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.stacked_line_chart),
            label: 'Múltipla',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}
