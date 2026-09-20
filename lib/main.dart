import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models.dart';
import 'storage.dart';
import 'screens/boot_screen.dart';
import 'screens/stat_screen.dart';
import 'screens/inv_screen.dart';
import 'screens/data_screen.dart';
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
    const phosphor = Color(0xFFB5B5B5);
    final base = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      title: 'PIP-BOY 2000',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: const Color(0xFF0C0C0C),
        colorScheme: const ColorScheme.dark(
          primary: phosphor, secondary: phosphor,
          surface: Color(0xFF141414), onSurface: phosphor),
        textTheme: GoogleFonts.shareTechMonoTextTheme(base.textTheme)
            .apply(bodyColor: phosphor, displayColor: phosphor),
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(color: phosphor),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF0C0C0C),
          insetPadding: EdgeInsets.all(16),
        ),
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
    );
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
  static const _titles = ['STAT', 'INV', 'DATA', 'MAP', 'RADIO'];

  void _changed() {
    widget.data.clamp();
    setState(() {});
    Storage.save(widget.data);
  }

  Widget _topBar() => Container(
        height: 40,
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF3A3A3A)))),
        child: Row(
          children: List.generate(_titles.length, (i) {
            final sel = _tab == i;
            return Expanded(
              child: InkWell(
                onTap: () => setState(() => _tab = i),
                child: Center(
                  child: Text(
                    sel ? '[${_titles[i]}]' : _titles[i],
                    style: TextStyle(
                      fontSize: sel ? 18 : 15,
                      letterSpacing: 2,
                      color: sel
                          ? const Color(0xFFB5B5B5)
                          : const Color(0xFF555555),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final screens = [
      StatScreen(data: d, onChanged: _changed),
      InvScreen(data: d, onChanged: _changed),
      DataScreen(data: d, onChanged: _changed),
      const PlaceholderScreen('MAP MODULE', 'NO SIGNAL', Icons.map_outlined),
      const PlaceholderScreen('RADIO MODULE', '0 STATIONS FOUND', Icons.radio_outlined),
    ];
    return Scaffold(
      body: Column(children: [
        _topBar(),
        Expanded(child: screens[_tab]),
      ]),
    );
  }
}

