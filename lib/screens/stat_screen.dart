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
  GameData get d => widget.data;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        SizedBox(
          height: 30,
          child: TabBar(
            controller: _tc,
            labelStyle: const TextStyle(fontSize: 13, letterSpacing: 3),
            unselectedLabelColor: const Color(0xFF555555),
            tabs: const [Tab(text: 'СОСТ'), Tab(text: 'НАВЫКИ')],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tc,
            children: [
              _conditionTab(),
              SkillsPanel(data: d, onChanged: widget.onChanged),
            ],
          ),
        ),
      ]),
      floatingActionButton: _tc.index == 1
          ? FloatingActionButton.small(onPressed: _addSkill, child: const Icon(Icons.add))
          : null,
    );
  }

  // ---------- СОСТ: всё помещается без прокрутки ----------
  Widget _conditionTab() {
    final eff = d.effectiveSpecial;
    final base = d.character.special;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Text('${d.character.name}   LV.${d.character.level}',
                style: const TextStyle(fontSize: 13, letterSpacing: 2)),
          ),
          Text('НАГРУЗКА ${d.carryWeight.toStringAsFixed(1)} кг',
              style: const TextStyle(fontSize: 10)),
        ]),
        Expanded(
          child: Row(children: [
            Expanded(
              flex: 3,
              child: Column(children: [
                const Row(children: [
                  SizedBox(width: 22, child: Text('АТР', style: TextStyle(fontSize: 10))),
                  Expanded(child: Center(child: Text('БАЗА', style: TextStyle(fontSize: 10)))),
                  Expanded(child: Center(child: Text('ФАКТ', style: TextStyle(fontSize: 10)))),
                  SizedBox(width: 52),
                ]),
                ...GameData.specialKeys.map((k) => Expanded(
                  child: Row(children: [
                    SizedBox(width: 22, child: Text(k, style: const TextStyle(fontSize: 14))),
                    Expanded(child: Center(child: Text('${base[k]}', style: const TextStyle(fontSize: 14)))),
                    Expanded(child: Center(child: Text(
                      '${eff[k]}${eff[k] != base[k] ? '(${eff[k]! > base[k]! ? '+' : ''}${eff[k]! - base[k]!})' : ''}',
                      style: TextStyle(fontSize: 14,
                          color: eff[k] != base[k] ? Colors.white : null),
                    ))),
                    SizedBox(width: 52, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      InkWell(
                        onTap: base[k]! > 1
                            ? () => setState(() { base[k] = base[k]! - 1; widget.onChanged(); })
                            : null,
                        child: const Padding(padding: EdgeInsets.all(3), child: Icon(Icons.remove, size: 14))),
                      InkWell(
                        onTap: base[k]! < 10
                            ? () => setState(() { base[k] = base[k]! + 1; widget.onChanged(); })
                            : null,
                        child: const Padding(padding: EdgeInsets.all(3), child: Icon(Icons.add, size: 14))),
                    ])),
                  ]),
                )),
              ]),
            ),
            const Expanded(
              flex: 2,
              child: Center(child: Icon(Icons.person, size: 110, color: Color(0xFF3A3A3A))),
            ),
          ]),
        ),
        const Divider(height: 6),
        Row(children: [
          Expanded(child: _miniBar('HP', d.character.hp, d.maxHp)),
          const SizedBox(width: 12),
          Expanded(child: _miniBar('LEVEL', d.character.xp, d.character.xpNext)),
          const SizedBox(width: 12),
          Expanded(child: _miniBar('AP', d.character.ap, d.maxAp)),
        ]),
      ]),
    );
  }

  Widget _miniBar(String label, int value, int max) => Row(children: [
    SizedBox(width: 74,
        child: Text('$label $value/$max', style: const TextStyle(fontSize: 10))),
    Expanded(child: SizedBox(
      height: 8,
      child: LinearProgressIndicator(
          value: max == 0 ? 0 : value / max, minHeight: 5,
          backgroundColor: const Color(0xFF1A1A1A)),
    )),
  ]);

  // ---------- диалог добавления навыка (компактный) ----------
  Future<void> _addSkill() async {
    final name = TextEditingController(), desc = TextEditingController();
    String? attr;
    int value = 1;
    InputDecoration dec(String l) => InputDecoration(
        labelText: l, isDense: true,
        labelStyle: const TextStyle(fontSize: 11));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: const Text('НОВЫЙ НАВЫК', style: TextStyle(fontSize: 14)),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: dec('Название'), style: const TextStyle(fontSize: 13)),
            TextField(controller: desc, decoration: dec('Описание'), style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            Row(children: [
              const Text('Мод. SPECIAL:', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: attr, hint: const Text('—', style: TextStyle(fontSize: 12)),
                items: const [DropdownMenuItem<String>(value: null, child: Text('—'))]
                    .followedBy(GameData.specialKeys.map((k) =>
                        DropdownMenuItem<String>(value: k, child: Text(k, style: const TextStyle(fontSize: 12)))))
                    .toList(),
                onChanged: (v) => setD(() => attr = v),
              ),
              if (attr != null) ...[
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: value,
                  items: [for (var v = -3; v <= 3; v++) v]
                      .map((v) => DropdownMenuItem(value: v,
                          child: Text('${v > 0 ? '+' : ''}$v', style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (v) => setD(() => value = v ?? 1),
                ),
              ],
            ]),
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ОТМЕНА', style: TextStyle(fontSize: 12))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ДОБАВИТЬ', style: TextStyle(fontSize: 12))),
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
}

// ==================== НАВЫКИ: список слева, детали справа ====================
class SkillsPanel extends StatefulWidget {
  final GameData data;
  final VoidCallback onChanged;
  const SkillsPanel({super.key, required this.data, required this.onChanged});

  @override
  State<SkillsPanel> createState() => _SkillsPanelState();
}

class _SkillsPanelState extends State<SkillsPanel> {
  int _sel = 0;
  GameData get d => widget.data;

  @override
  Widget build(BuildContext context) {
    final empty = d.skills.isEmpty;
    if (!empty && _sel >= d.skills.length) _sel = d.skills.length - 1;
    return Row(children: [
      Expanded(
        flex: 2,
        child: empty
            ? const Center(child: Text('[ НЕТ НАВЫКОВ — НАЖМИ + ]',
                style: TextStyle(letterSpacing: 2, fontSize: 12)))
            : ListView.builder(
                itemCount: d.skills.length,
                itemBuilder: (_, i) => ListTile(
                  dense: true,
                  selected: i == _sel,
                  selectedTileColor: const Color(0xFF1E1E1E),
                  title: Text(d.skills[i].name.isEmpty ? '—' : d.skills[i].name,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: d.skills[i].specialMods.isEmpty ? null
                      : Text(modsToString(d.skills[i].specialMods),
                          style: const TextStyle(fontSize: 10)),
                  onTap: () => setState(() => _sel = i),
                ),
              ),
      ),
      const VerticalDivider(width: 1, color: Color(0xFF3A3A3A)),
      Expanded(
        flex: 3,
        child: empty || _sel >= d.skills.length
            ? const Center(child: Icon(Icons.star_outline, size: 96, color: Color(0xFF3A3A3A)))
            : _detail(d.skills[_sel]),
      ),
    ]);
  }

  Widget _detail(Skill s) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(children: [
      const Icon(Icons.star, size: 72, color: Color(0xFF555555)),
      const SizedBox(height: 6),
      Text(s.name, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Text('МОДИФИКАТОРЫ: ${s.specialMods.isEmpty ? 'нет' : modsToString(s.specialMods)}',
          style: const TextStyle(fontSize: 11)),
      const SizedBox(height: 6),
      Expanded(child: SingleChildScrollView(
          child: Text(s.description.isEmpty ? '[ НЕТ ОПИСАНИЯ ]' : s.description,
              style: const TextStyle(fontSize: 12, height: 1.5)))),
      OutlinedButton(
        onPressed: () {
          setState(() => d.skills.remove(s));
          widget.onChanged();
        },
        child: const Text('УДАЛИТЬ', style: TextStyle(fontSize: 12)),
      ),
    ]),
  );
}

