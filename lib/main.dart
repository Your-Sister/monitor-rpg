import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models.dart';
import 'storage.dart';
import 'screens/boot_screen.dart';
import 'screens/stat_screen.dart';
import 'screens/inv_screen.dart';
import 'screens/placeholder_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  final data = await Storage.load();
  runApp(PipBoyApp(data: data));
}

class PipBoyApp extends StatelessWidget {
  final GameData data;
  const PipBoyApp({super.key, required this.data});

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
          primary: phosphor, secondary: phosphor,
          surface: Color(0xFF111111), onSurface: phosphor),
        textTheme: GoogleFonts.shareTechMonoTextTheme(base.textTheme)
            .apply(bodyColor: phosphor, displayColor: phosphor),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF0C0C0C),
          indicatorColor: phosphor,
          labelTextStyle: WidgetStatePropertyAll(
              TextStyle(fontSize: 11, letterSpacing: 1))),
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(color: phosphor),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0C0C0C)),
),
	home: Builder(
	  builder: (context) => BootScreen(
	    onDone: () {
     	Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(data: data)),
      );
    },
  ),
),	
}
}

class HomeScreen extends StatefulWidget {
  final GameData data;
  const HomeScreen({super.key, required this.data});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  static const _titles = ['STATUS', 'INV', 'DATA', 'MAP', 'RADIO'];

  void _changed() {
    widget.data.clamp();
    setState(() {});
    Storage.save(widget.data);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final screens = [
      StatScreen(data: d, onChanged: _changed),
      InvScreen(data: d, onChanged: _changed),
      const PlaceholderScreen('DATA MODULE', 'NO ACTIVE QUESTS'),
      const PlaceholderScreen('MAP MODULE', 'NO SIGNAL'),
      const PlaceholderScreen('RADIO MODULE', '0 STATIONS FOUND'),
    ];
    return Scaffold(
      appBar: AppBar(title: Text('PIP-BOY 2000 — ${_titles[_tab]}'), centerTitle: true),
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

