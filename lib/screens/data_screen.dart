import 'package:flutter/material.dart';
import '../models.dart';

class DataScreen extends StatefulWidget {
  final GameData data;
  final VoidCallback onChanged;
  const DataScreen({super.key, required this.data, required this.onChanged});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  int _sel = 0;
  GameData get d => widget.data;

  static const _statusLabels = {'active': 'АКТИВЕН', 'done': 'ВЫПОЛНЕН', 'failed': 'ПРОВАЛЕН'};
  static const _statusOrder = ['active', 'done', 'failed'];

  @override
  Widget build(BuildContext context) {
    final empty = d.quests.isEmpty;
    if (!empty && _sel >= d.quests.length) _sel = d.quests.length - 1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(children: [
        Expanded(
          flex: 2,
          child: empty
              ? const Center(child: Text('[ НЕТ ЗАПИСЕЙ — НАЖМИ + ]',
                  style: TextStyle(letterSpacing: 2, fontSize: 12)))
              : ListView(
                  children: [
                    for (final st in _statusOrder) ...[
                      if (d.quests.any((q) => q.status == st))
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                          child: Text('-- ${_statusLabels[st]} --',
                              style: const TextStyle(fontSize: 10, letterSpacing: 2)),
                        ),
                      ...d.quests.asMap().entries
                          .where((e) => e.value.status == st)
                          .map((e) => ListTile(
                                dense: true,
                                selected: e.key == _sel,
                                selectedTileColor: const Color(0xFF1E1E1E),
                                title: Text(e.value.title,
                                    style: const TextStyle(fontSize: 13)),
                                onTap: () => setState(() => _sel = e.key),
                              )),
                    ],
                  ],
                ),
        ),
        const VerticalDivider(width: 1, color: Color(0xFF3A3A3A)),
        Expanded(flex: 3, child: empty ? const Center(
            child: Icon(Icons.description_outlined, size: 96, color: Color(0xFF3A3A3A)))
            : _detail(d.quests[_sel])),
      ]),
      floatingActionButton: FloatingActionButton.small(
          onPressed: _addQuest, child: const Icon(Icons.add)),
    );
  }

  Widget _detail(Quest q) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(children: [
      Icon(q.status == 'done' ? Icons.check_circle_outline
          : q.status == 'failed' ? Icons.cancel_outlined
          : Icons.radio_button_unchecked,
          size: 72, color: const Color(0xFF555555)),
      const SizedBox(height: 6),
      Text(q.title, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
      const SizedBox(height: 4),
      Text('СТАТУС: ${_statusLabels[q.status]}',
          style: const TextStyle(fontSize: 11)),
      const SizedBox(height: 6),
      Expanded(child: SingleChildScrollView(
          child: Text(q.description.isEmpty ? '[ НЕТ ОПИСАНИЯ ]' : q.description,
              style: const TextStyle(fontSize: 12, height: 1.5)))),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        OutlinedButton(
          onPressed: () {
            setState(() {
              q.status = q.status == 'active' ? 'done'
                  : q.status == 'done' ? 'failed' : 'active';
            });
            widget.onChanged();
          },
          child: const Text('СМЕНИТЬ СТАТУС', style: TextStyle(fontSize: 11)),
        ),
        OutlinedButton(
          onPressed: () {
            setState(() => d.quests.remove(q));
            widget.onChanged();
          },
          child: const Text('УДАЛИТЬ', style: TextStyle(fontSize: 11)),
        ),
      ]),
    ]),
  );

  Future<void> _addQuest() async {
    final title = TextEditingController(), desc = TextEditingController();
    InputDecoration dec(String l) => InputDecoration(
        labelText: l, isDense: true, labelStyle: const TextStyle(fontSize: 11));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('НОВАЯ ЗАПИСЬ', style: TextStyle(fontSize: 14)),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title, decoration: dec('Название'), style: const TextStyle(fontSize: 13)),
            TextField(controller: desc, decoration: dec('Описание'), style: const TextStyle(fontSize: 13)),
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ОТМЕНА', style: TextStyle(fontSize: 12))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ДОБАВИТЬ', style: TextStyle(fontSize: 12))),
        ],
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      setState(() {
        d.quests.add(Quest(title: title.text.trim(), description: desc.text.trim()));
        _sel = d.quests.length - 1;
      });
      widget.onChanged();
    }
  }
}

