import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

class BootScreen extends StatefulWidget {
  final VoidCallback onDone;
  const BootScreen({super.key, required this.onDone});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  final List<String> _lines = [];
  int _shown = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  Future<void> _boot() async {
    _lines.addAll([
      '*************** PIP-OS(R) V7.1.0.8 ***************',
      'COPYRIGHT 2075 ROBCO(R)',
      'LOADER V1.1',
    ]);
    setState(() {});
    try {
      final info = await DeviceInfoPlugin()
          .androidInfo
          .timeout(const Duration(seconds: 2));
      final level = await Battery()
          .batteryLevel
          .timeout(const Duration(seconds: 2));
      final size = MediaQuery.sizeOf(context);
      _lines.addAll([
        'EXEC VERSION ${info.version.release} (SDK ${info.version.sdkInt})',
        '${info.brand.toUpperCase()} ${info.model.toUpperCase()} DETECTED',
        'DISPLAY ${size.width.toInt()}x${size.height.toInt()} OK',
        'BATTERY $level% CHARGED',
      ]);
    } catch (_) {
      _lines.add('DEVICE QUERY FAILED... SKIPPING');
    }
    _lines.addAll(['NO HOLOTAPE FOUND', 'LOAD ROM(1): DEITRIX 303']);
    setState(() {});

    Timer.periodic(const Duration(milliseconds: 320), (t) {
      if (!mounted || _done) { t.cancel(); return; }
      if (_shown < _lines.length) {
        setState(() => _shown++);
      } else {
        t.cancel();
        Timer(const Duration(milliseconds: 900), _finish);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_done) return;
        if (_shown < _lines.length) {
          setState(() => _shown = _lines.length); // тап: показать всё сразу
        } else {
          _finish(); // второй тап: перейти сразу
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _shown && i < _lines.length; i++)
                  Text(_lines[i], style: const TextStyle(fontSize: 13, height: 1.7)),
                const Text('█', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

