import 'package:flutter/material.dart';
import '../models.dart';

class CharacterCreation extends StatefulWidget {
  final GameData data;
  const CharacterCreation({super.key, required this.data});

  @override
  State<CharacterCreation> createState() => _CharacterCreationState();
}

class _CharacterCreationState extends State<CharacterCreation> {
  static const startPoints = 5;
  late final Map<String, int> base;
  late final TextEditingController name;

  @override
  void initState() {
    super.initState();
    base = Map<String, int>.from(widget.data.character.special);
    name = TextEditingController(text: widget.data.character.name);
  }

  @override
  void dispose() { name.dispose(); super.dispose(); }

  int get _spentAbove => base.values.fold(0, (a, v) => a + (v > 5 ? v - 5 : 0));
  int get _gainedBelow => base.values.fold(0, (a, v) => a + (v < 5 ? 5 - v : 0));
  int get remaining => startPoints + _gainedBelow - _spentAbove;

  void _finish() {
    final d = widget.data;
    d.character.special = Map<String, int>.from(base);
    d.character.name = name.text.trim().isEmpty ? 'WANDERER' : name.text.trim();
    d.character.skillPoints = d.skillRate;
    d.character.hp = d.maxHp;
    d.character.ap = d.maxAp;
    d.characterConfirmed = true;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0C0C0C),
      insetPadding: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Text('РЕГИСТРАЦИЯ ПЕРСОНАЖА',
                style: TextStyle(fontSize: 13, letterSpacing: 2)),
            const Spacer(),
            Text('ОЧКОВ: $remaining', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => Navigator.of(context).pop(false), // X — закрыть до след. запуска
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 18),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          TextField(
            controller: name,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
                labelText: 'ИМЯ', isDense: true,
                labelStyle: TextStyle(fontSize: 10)),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Column(children: [
                    for (final k in GameData.specialKeys)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          SizedBox(width: 20,
                              child: Text(k, style: const TextStyle(fontSize: 14))),
                          Expanded(child: Center(child: Text('${base[k]}',
                              style: const TextStyle(fontSize: 15)))),
                          InkWell(
                            onTap: base[k]! > 1
                                ? () => setState(() => base[k] = base[k]! - 1) : null,
                            child: const Padding(padding: EdgeInsets.all(3),
                                child: Icon(Icons.remove, size: 16))),
                          InkWell(
                            onTap: (remaining > 0 && base[k]! < 10)
                                ? () => setState(() => base[k] = base[k]! + 1) : null,
                            child: const Padding(padding: EdgeInsets.all(3),
                                child: Icon(Icons.add, size: 16))),
                        ]),
                      ),
                  ]),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                flex: 4,
                child: Text(
                  'ВСЕ ХАРАКТЕРИСТИКИ = 5.\n'
                  'РАСПРЕДЕЛИ $startPoints ОЧКОВ.\n'
                  'СНИЖЕНИЕ НИЖЕ 5 ВОЗВРАЩАЕТ ОЧКО.\n'
                  'ДИАПАЗОН: 1..10.\n\n'
                  'ПОСЛЕ ПОДТВЕРЖДЕНИЯ SPECIAL\n'
                  'МЕНЯЕТ ТОЛЬКО МАСТЕР.\n\n'
                  'НАВЫКИ И ЧЕРТЫ НАСТРАИВАЮТСЯ\n'
                  'ВО ВКЛАДКЕ STAT.',
                  style: TextStyle(fontSize: 10, height: 1.6),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: _finish,
              child: const Text('ГОТОВО', style: TextStyle(fontSize: 12)),
            ),
          ),
        ]),
      ),
    );
  }
}

