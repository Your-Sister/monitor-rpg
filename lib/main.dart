import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const PipBoyApp());

// ==================== МОДЕЛЬ ДАННЫХ ====================
class Character {
  String name;
  int level;
  int hp, maxHp;
  int ap, maxAp;
  int xp, xpNext;
  Map<String, int> special; // S.P.E.C.I.A.L.

  Character({
    this.name = 'WANDERER',
    this.level = 1,
    this.hp = 35, this.maxHp = 35,
    this.ap = 10, this.maxAp = 10,
    this.xp = 0, this.xpNext = 1000,
    Map<String, int>? special,
  }) : special = special ??
            {'S': 5, 'P': 5, 'E': 5, 'C': 5, 'I': 5, 'A': 5, 'L': 5};
}

// ==================== ПРИЛОЖЕНИЕ ====================
class PipBoyApp extends StatelessWidget {
  const PipBoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const phosphor = Color(0xFF33FF33);
    final base = ThemeData.dark(useMaterial3: true);

    return MaterialApp(
      title: 'PIP-BOY 2000',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: const Color(0xFF0C0C0C),
        colorScheme: const ColorScheme.dark(
          primary: phosphor,
          secondary: phosphor,
          surface: Color(0xFF111111),
          onSurface: phosphor,
        ),
        textTheme: GoogleFonts.shareTechMonoTextTheme(base.textTheme)
            .apply(bodyColor: phosphor, displayColor: phosphor),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF0C0C0C),
          indicatorColor: phosphor,
          labelTextStyle: WidgetStatePropertyAll(
              TextStyle(fontSize: 11, letterSpacing: 1)),
        ),
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(color: phosphor),
      ),
      home: const HomeShell(),
    );
  }
}

// ==================== ОБОЛОЧКА С ВКЛАДКАМИ ====================
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  final _character = Character();

  static const _titles = ['STATUS', 'INV', 'DATA', 'MAP', 'RADIO'];

  @override
  Widget build(BuildContext context) {
    final screens = [
      StatScreen(character: _character),
      const PlaceholderScreen('INV MODULE', 'CARRY WEIGHT: 0/210'),
      const PlaceholderScreen('DATA MODULE', 'NO ACTIVE QUESTS'),
      const PlaceholderScreen('MAP MODULE', 'NO SIGNAL'),
      const PlaceholderScreen('RADIO MODULE', '0 STATIONS FOUND'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('PIP-BOY 2000 — ${_titles[_tab]}'),
        centerTitle: true,
      ),
      body: screens[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.person), label: 'STAT'),
          NavigationDestination(icon: Icon(Icons.backpack), label: 'INV'),
          NavigationDestination(icon: Icon(Icons.description), label: 'DATA'),
          NavigationDestination(icon: Icon(Icons.map), label: 'MAP'),
          NavigationDestination(icon: Icon(Icons.radio), label: 'RADIO'),
        ],
      ),
    );
  }
}

// ==================== STATUS ====================
class StatScreen extends StatefulWidget {
  final Character character;
  const StatScreen({super.key, required this.character});

  @override
  State<StatScreen> createState() => _StatScreenState();
}

class _StatScreenState extends State<StatScreen> {
  Character get c => widget.character;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          '${c.name}   LV.${c.level}',
          style: const TextStyle(fontSize: 22, letterSpacing: 3),
        ),
        const SizedBox(height: 8),
        _bar('HP', c.hp, c.maxHp),
        _bar('AP', c.ap, c.ap),
        _bar('XP', c.xp, c.xpNext),
        const Divider(color: Color(0xFF33FF33), height: 32),
        const Text('S.P.E.C.I.A.L.',
            style: TextStyle(letterSpacing: 4, fontSize: 16)),
        const SizedBox(height: 8),
        ...c.special.entries.map((e) => _specialRow(e.key, e.value)),
      ],
    );
  }

  Widget _bar(String label, int value, int max) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 32, child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: LinearProgressIndicator(
              value: max == 0 ? 0 : value / max,
              minHeight: 14,
              backgroundColor: const Color(0xFF111111),
            ),
          ),
          SizedBox(
              width: 64,
              child: Text(' $value/$max',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _specialRow(String attr, int value) {
    return Row(
      children: [
        SizedBox(
            width: 24,
            child: Text(attr, style: const TextStyle(fontSize: 18))),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: value > 1 ? () => setState(() => c.special[attr] = value - 1) : null,
        ),
        Expanded(
          child: Center(
            child: Text('$value', style: const TextStyle(fontSize: 20)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: value < 10 ? () => setState(() => c.special[attr] = value + 1) : null,
        ),
      ],
    );
  }
}

// ==================== ЗАГЛУШКИ ====================
class PlaceholderScreen extends StatelessWidget {
  final String title, subtitle;
  const PlaceholderScreen(this.title, this.subtitle, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title\n[ $subtitle ]',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, letterSpacing: 2, height: 1.6),
      ),
    );
  }
}

