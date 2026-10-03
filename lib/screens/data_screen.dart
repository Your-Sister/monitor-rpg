import 'package:flutter/material.dart';
import '../models.dart';

class DataScreen extends StatefulWidget {
  final GameData data;
  final VoidCallback onChanged;
  const DataScreen({super.key, required this.data, required this.onChanged});
  @override State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  int _sel = 0;
  Quest? _draft;
  GameData get d => widget.data;

  void _commit() {
    final draft = _draft!;
    if (draft.title.trim().isEmpty) draft.title = '[ БЕЗ НАЗВАНИЯ ]';
    final i = d.quests.indexWhere((q) => q.id == draft.id);
    setState(() {
      if (i >= 0) { d.quests[i] = draft; } else { d.quests.add(draft); }
      _draft = null;
      if (_sel >= d.quests.length) _sel = d.quests.length - 1;
    });
    widget.onChanged();
  }

  void _delete(Quest q) {
    setState(() {
      d.quests.remove(q);
      if (_sel >= d.quests.length) _sel = d.quests.length - 1;
      if (_sel < 0) _sel = 0;
    });
    widget.onChanged();
  }

  Widget _buildTileButton(String text, VoidCallback onPressed, {Color? color}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        splashColor: const Color(0xFF3A3A3A),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          child: Text(text, style: TextStyle(fontSize: 11, letterSpacing: 1, color: color)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    if (d.quests.isNotEmpty && _sel >= d.quests.length) _sel = d.quests.length - 1;
    final quest = d.quests.isEmpty ? null : d.quests[_sel];

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 3, 8, 0),
                child: Row(
                  children: [
                    Text('ВСЕГО: ${d.quests.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(height: 3),
              Expanded(
                child: d.quests.isEmpty
                    ? const Center(child: Text('[ ПУСТО ]', style: TextStyle(fontSize: 12, letterSpacing: 2)))
                    : ListView.builder(
                        itemCount: d.quests.length,
                        itemBuilder: (_, i) {
                          final q = d.quests[i];
                          final isSelected = _sel == i && draft == null;
                          return InkWell(
                            onTap: () => setState(() { _sel = i; _draft = null; }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              color: isSelected ? const Color(0xFF1E1E1E) : Colors.transparent,
                              child: Row(
                                children: [
                                  Icon(
                                    q.status == 'ВЫПОЛНЕН' ? Icons.check_circle : (q.status == 'ПРОВАЛЕН' ? Icons.cancel : Icons.radio_button_unchecked),
                                    size: 16,
                                    color: q.status == 'ВЫПОЛНЕН' ? const Color(0xFF4CAF50) : (q.status == 'ПРОВАЛЕН' ? const Color(0xFFF44336) : const Color(0xFFB5B5B5)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      q.title.isEmpty ? '[ БЕЗ НАЗВАНИЯ ]' : q.title,
                                      style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Expanded(child: _buildTileButton('ДОБАВИТЬ КВЕСТ', () => setState(() => _draft = Quest(status: 'АКТИВЕН')))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: Color(0xFF3A3A3A)),
        Expanded(
          flex: 3,
          child: draft != null
              ? QuestEditor(quest: draft, onDone: _commit, onCancel: () => setState(() => _draft = null))
              : quest == null
                  ? const Center(child: Icon(Icons.description_outlined, size: 96, color: Color(0xFF3A3A3A)))
                  : _questView(quest),
        ),
      ],
    );
  }

  Widget _questView(Quest q) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              q.status == 'ВЫПОЛНЕН' ? Icons.check_circle : (q.status == 'ПРОВАЛЕН' ? Icons.cancel : Icons.description_outlined),
              size: 56,
              color: q.status == 'ВЫПОЛНЕН' ? const Color(0xFF4CAF50) : (q.status == 'ПРОВАЛЕН' ? const Color(0xFFF44336) : const Color(0xFF555555)),
            ),
            const SizedBox(height: 8),
            Text(q.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('СТАТУС: ${q.status}', style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF3A3A3A)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(q.description.isEmpty ? '[ НЕТ ОПИСАНИЯ ]' : q.description, style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFFCCCCCC))),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildTileButton('ИЗМЕНИТЬ', () => setState(() => _draft = Quest(id: q.id, title: q.title, description: q.description, status: q.status)))),
                const SizedBox(width: 4),
                Expanded(child: _buildTileButton('УДАЛИТЬ', () => _delete(q), color: Colors.redAccent)),
              ],
            ),
          ],
        ),
      );
}

class QuestEditor extends StatefulWidget {
  final Quest quest;
  final VoidCallback onDone, onCancel;
  const QuestEditor({super.key, required this.quest, required this.onDone, required this.onCancel});
  @override State<QuestEditor> createState() => _QuestEditorState();
}

class _QuestEditorState extends State<QuestEditor> {
  late final TextEditingController _title, _desc;
  late String _status;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.quest.title);
    _desc = TextEditingController(text: widget.quest.description);
    _status = widget.quest.status;
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Quest get q => widget.quest;
  InputDecoration _dec(String l) => InputDecoration(labelText: l, isDense: true, labelStyle: const TextStyle(fontSize: 10));

  Widget _buildTileButton(String text, VoidCallback onPressed, {Color? color}) {
    return Material(color: Colors.transparent, child: InkWell(onTap: onPressed, splashColor: const Color(0xFF3A3A3A),
        child: Container(height: 36, alignment: Alignment.center, child: Text(text, style: TextStyle(fontSize: 11, letterSpacing: 1, color: color)))));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          const Icon(Icons.description_outlined, size: 36, color: Color(0xFF555555)),
          const SizedBox(height: 8),
          TextField(controller: _title, style: const TextStyle(fontSize: 14), decoration: _dec('НАЗВАНИЕ КВЕСТА'), onChanged: (v) => q.title = v),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: _dec('СТАТУС'),
            items: const ['АКТИВЕН', 'ВЫПОЛНЕН', 'ПРОВАЛЕН'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) {
              setState(() { _status = v!; q.status = _status; });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            minLines: 6,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontSize: 12),
            decoration: _dec('ОПИСАНИЕ / ЦЕЛИ'),
            onChanged: (v) => q.description = v,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTileButton('ГОТОВО', () { widget.onDone(); })),
              Expanded(child: _buildTileButton('ОТМЕНА', widget.onCancel)),
            ],
          ),
        ],
      ),
    );
  }
}
