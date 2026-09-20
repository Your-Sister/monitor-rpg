import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  const PlaceholderScreen(this.title, this.subtitle, this.icon, {super.key});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(
      flex: 2,
      child: Center(
        child: Text('$title\n[ $subtitle ]',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, letterSpacing: 2, height: 1.6)),
      ),
    ),
    const VerticalDivider(width: 1, color: Color(0xFF3A3A3A)),
    Expanded(
      flex: 3,
      child: Center(child: Icon(icon, size: 96, color: const Color(0xFF3A3A3A))),
    ),
  ]);
}

