import 'package:flutter/material.dart';
import '../models.dart';

class StatScreen extends StatefulWidget {
  final GameData data;
  final VoidCallback onChanged;
  const StatScreen({super.key, required this.data, required this.onChanged});

  @override
  State<StatScreen> createState() => _StatScreenState();
}

class _StatScreenState extends State<StatScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tc;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 3, vsync: this)
      ..addListener(() => setState(() => _tab = _tc.index));
  }

  @override
  void dispose() { _tc.dispose(); super.dispose(); }

  GameData get d => widget.data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: TabBar(
        controller: _tc,
        tabs: const [
          Tab(text: 'СОСТОЯНИЕ'),
          Tab(text: 'УМЕНИЯ И НАВЫКИ'),
          Tab(text: 'КВЕСТЫ'),
        ],
      ),
      body: TabBarView(
        controller: _tc,
        children: [_conditionTab(), _skillsTab(), _questsTab()],
      ),
      floatingActionButton: _tab == 0 ? null : FloatingActionButton(
        onPressed: _tab == 1 ? _addSkill : _addQuest,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ---------- СОСТОЯНИЕ ----------
  Widget _conditionTab() {
    final eff = d.effectiveSpecial;
    final base = d.character.special;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('${d.character.name}   LV.${d.character.level}',
            style: const TextStyle(fontSize: 20, letterSpacing: 3)),
        const SizedBox(height: 8),
        _bar('HP', d.character.hp, d.maxHp),
        _bar('AP', d.character.ap, d.maxAp),
        _bar('XP', d.character.xp, d.character.xpNext),
        const Divider(height: 28),
        const Row(children: [
          SizedBox(width: 40, child: Text('АТР', style: TextStyle(fontSize: 12))),
          Expanded(child: Center(child: Text('ЗАЯВЛ.', style: TextStyle(fontSize: 12)))),
          Expanded(child: Center(child: Text('ФАКТ.', style: TextStyle(fontSize: 12)))),
          SizedBox(width: 80),
        ]),
        ...GameData.specialKeys.map((k) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                SizedBox(width: 40, child: Text(k, style: const TextStyle(fontSize: 18))),
                Expanded(child: Center(child: Text('${base[k]}', style: const TextStyle(fontSize: 18)))),
                Expanded(child: Center(child: Text(
                  '${eff[k]}${eff[k] != base[k] ? '  (${eff[k]! > base[k]! ? '+' : ''}${eff[k]! - base[k]!})' : ''}',
                  style: TextStyle(
                    fontSize: 18,
                    color: eff[k] != base[k] ? const Color(0xFF7CFC00) : null,
                  ),
                ))),
                SizedBox(
                  width: 80,
                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    IconButton(icon: const Icon(Icons.remove_circle_outline, size: 18),
                        onPressed: base[k]! > 1
                            ? () => setState(() { base[k] = base[k]! - 1; widget.onChanged(); })
                            : null),
                    IconButton(icon: const Icon(Icons.add_circle_outline, size: 18),
                        onPressed: base[k]! < 10
                            ? () => setState(() { base[k] = base[k]! + 1; widget.onChanged(); })
                            : null),
                  ]),
                ),
              ]),
            )),
        const SizedBox(height: 8),
        Text('НАГРУЗКА: ${d.carryWeight.toStringAsFixed(1)} кг',
            style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _bar(String label, int value, int max) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 30, child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(child: LinearProgressIndicator(
              value: max == 0 ? 0 : value / max, minHeight: 14,
              backgroundColor: const Color(0xFF111111))),
          SizedBox(width: 70, child: Text(' $value/$max',
              textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
        ]),
      );

  // ---------- УМЕНИЯ И НАВЫКИ ----------
  Widget _skillsTab() {
    if (d.skills.isEmpty) {
      return const Center(child: Text('[ НЕТ УМЕНИЙ — НАЖМИ + ]',
          style: TextStyle(letterSpacing: 2)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: d.skills.length,
      itemBuilder: (_, i) {
        final s = d.skills[i];
        return Dismissible(
          key: Key(s.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) { setState(() => d.skills.removeAt(i)); widget.onChanged(); },
          background: Container(color: Colors.red.shade900),
          child: ListTile(
            title: Text(s.name.isEmpty ? '—' : s.name),
            subtitle: Text(s.description, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: s.specialMods.isEmpty
                ? null
                : Text(modsToString(s.specialMods), style: const TextStyle(fontSize: 12)),
            onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
              title: Text(s.name),
              content: Text('${s.description}\n\nМОДИФИКАТОРЫ: ${modsToString(s.specialMods)}'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ЗАКРЫТЬ'))],
            )),
          ),
        );
      },
    );
  }

  Future<void> _addSkill() async {
    final name = TextEditingController(), desc = TextEditingController();
    String? attr;
    int value = 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: const Text('НОВОЕ УМЕНИЕ/НАВЫК'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Название')),
          TextField(controller: desc, decoration: const InputDecoration(labelText: 'Описание')),
          const SizedBox(height: 8),
          Row(children: [
            const Text('Мод. SPECIAL:'),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: attr,
              hint: const Text('—'),
              items: const [DropdownMenuItem(value: null, child: Text('—'))]
                  .followedBy(GameData.specialKeys.map((k) =>
                      DropdownMenuItem(value: k, child: Text(k)))).toList(),
              onChanged: (v) => setD(() => attr = v),
            ),
            if (attr != null) ...[
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: value,
                items: [for (var v = -3; v <= 3; v++) v]
                    .map((v) => DropdownMenuItem(value: v, child: Text('${v > 0 ? '+' : ''}$v')))
                    .toList(),
                onChanged: (v) => setD(() => value = v ?? 1),
              ),
            ],
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ОТМЕНА')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ДОБАВИТЬ')),
        ],
      )),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      setState(() {
        d.skills.add(Skill(name: name.text.trim(), description: desc.text.trim(),
            specialMods: attr == null ? {} : {attr!: value}));
      });
      widget.onChanged();
    }
  }

  // ---------- КВЕСТЫ ----------
  Widget _questsTab() {
    const labels = {'active': 'АКТИВНЫЕ', 'done': 'ВЫПОЛНЕННЫЕ', 'failed': 'ПРОВАЛЕННЫЕ'};
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        for (final status in ['active', 'done', 'failed']) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text('— ${labels[status]} (${d.quests.where((q) => q.status == status).length}) —',
                style: const TextStyle(letterSpacing: 2, fontSize: 13)),
          ),
          ...d.quests.where((q) => q.status == status).map((q) => Dismissible(
            key: Key(q.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) { setState(() => d.quests.remove(q)); widget.onChanged(); },
            background: Container(color: Colors.red.shade900),
            child: ListTile(
              dense: true,
              leading: Icon(status == 'done' ? Icons.check_circle_outline
                  : status == 'failed' ? Icons.cancel_outlined : Icons.radio_button_unchecked,
                  size: 20),
              title: Text(q.title),
              subtitle: q.description.isEmpty ? null : Text(q.description, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => setState(() {
                q.status = q.status == 'active' ? 'done' : q.status == 'done' ? 'failed' : 'active';
                widget.onChanged();
              }),
            ),
          )),
        ],
      ],
    );
  }

  Future<void> _addQuest() async {
    final title = TextEditingController(), desc = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('НОВЫЙ КВЕСТ'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Название')),
          TextField(controller: desc, decoration: const InputDecoration(labelText: 'Описание')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ОТМЕНА')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ДОБАВИТЬ')),
        ],
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      setState(() => d.quests.add(Quest(title: title.text.trim(), description: desc.text.trim())));
      widget.onChanged();
    }
  }
}

