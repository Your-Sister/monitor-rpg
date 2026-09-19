import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title, subtitle;
  const PlaceholderScreen(this.title, this.subtitle, {super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Text('$title\n[ $subtitle ]',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, letterSpacing: 2, height: 1.6)),
      );
}

