import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const PipBoyApp());

class PipBoyApp extends StatelessWidget {
  const PipBoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const phosphor = Color(0xFF33FF33); // зелёный фосфор
    final base = ThemeData.dark(useMaterial3: true);
    final mono = GoogleFonts.shareTechMonoTextTheme(base.textTheme);

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
        textTheme: mono.apply(bodyColor: phosphor, displayColor: phosphor),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF0C0C0C),
          indicatorColor: phosphor,
        ),
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  static const _titles = ['STATUS', 'INV', 'DATA', 'RADIO'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PIP-BOY 2000 — ${_titles[_tab]}')),
      body: Center(
        child: Text(
          '${_titles[_tab]} MODULE\n[ INITIALIZING... ]',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 2),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.person), label: 'STAT'),
          NavigationDestination(icon: Icon(Icons.backpack), label: 'INV'),
          NavigationDestination(icon: Icon(Icons.map), label: 'DATA'),
          NavigationDestination(icon: Icon(Icons.radio), label: 'RADIO'),
        ],
      ),
    );
  }
}

