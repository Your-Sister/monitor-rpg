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
    return Column(children: [
      SizedBox(
        height: 30,
        child: TabBar(
          controller: _tc,
          labelStyle: const TextStyle(fontSize: 13, letterSpacing: 3),
          unselectedLabelColor: const Color(0xFF555555),
          tabs: const [Tab(text: 'MAIN'), Tab(text: 'PERKS')],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tc,
          children: [
            _mainTab(),
            PerksPanel(data: d, onChanged: widget.onChanged),
          ],
        ),
      ),
    ]);
  }

  // ---------- MAIN: SPECIAL слева узкой колонкой, персонаж — основная область ----------
  Widget _mainTab() {
    final eff = d.effectiveSpecial;
    final base = d.character.special;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Text('${d.character.name}   LV.${d.character.level}',
                style: const TextStyle(fontSize: 12, letterSpacing: 2)),
          ),
          Text('НАГРУЗКА ${d.carryWeight.toStringAsFixed(1)} кг',
              style: const TextStyle(fontSize: 9)),
        ]),
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 210,
              child: Column(children: [
                const Row(children: [
                  SizedBox(width: 20, child: Text('АТР', style: TextStyle(fontSize: 9))),
                  SizedBox(width: 34, child: Center(child: Text('БАЗА', style: TextStyle(fontSize: 9)))),
                  SizedBox(width: 44, child: Center(child: Text('ФАКТ', style: TextStyle(fontSize: 9)))),
                  Spacer(),
                ]),
                ...GameData.specialKeys.map((k) => Expanded(
                  child: Row(children: [
                    SizedBox(width: 20, child: Text(k, style: const TextStyle(fontSize: 13))),
                    SizedBox(width: 34, child: Center(child: Text('${base[k]}', style: const TextStyle(fontSize: 13)))),
                    SizedBox(width: 44, child: Center(child: Text(
                      '${eff[k]}${eff[k] != base[k] ? '(${eff[k]! > base[k]! ? '+' : ''}${eff[k]! - base[k]!})' : ''}',
                      style: TextStyle(fontSize: 13,
                          color: eff[k] != base[k] ? Colors.white : null),
                    ))),
                    const Spacer(),
                    InkWell(
                      onTap: base[k]! > 1
                          ? () => setState(() { base[k] = base[k]! - 1; widget.onChanged(); })
                          : null,
                      child: const Padding(padding: EdgeInsets.all(2), child: Icon(Icons.remove, size: 13))),
                    InkWell(
                      onTap: base[k]! < 10
                          ? () => setState(() { base[k] = base[k]! + 1; widget.onChanged(); })
                          : null,
                      child: const Padding(padding: EdgeInsets.all(2), child: Icon(Icons.add, size: 13))),
                  ]),
                )),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF3A3A3A)),
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 170, color: Color(0xFF4A4A4A)),
                ),
              ),
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
}

// ==================== PERKS ====================
class PerksPanel extends StatefulWidget {
  final GameData data;
  final VoidCallback onChanged;
  const PerksPanel({super.key, required this.data, required this.onChanged});

  @override
  State<PerksPanel> createState() => _PerksPanelState();
}

class _PerksPanelState extends State<PerksPanel> {
  int _sel = 0;
  GameData get d => widget.data;

  void _add() {
    setState(() {
      d.skills.add(Skill());
      _sel = d.skills.length - 1;
    });
    widget.onChanged();
  }

  void _delete(Skill s) {
    setState(() {
      final i = d.skills.indexOf(s);
      d.skills.remove(s);
      if (_sel >= d.skills.length) _sel = d.skills.length - 1;
      if (_sel < 0) _sel = 0;
      if (i >= 0 && i < d.skills.length) _sel = i;
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final empty = d.skills.isEmpty;
    if (!empty && _sel >= d.skills.length) _sel = d.skills.length - 1;
    final skill = empty ? null : d.skills[_sel];
    return Row(children: [
      Expanded(
        flex: 2,
        child: Column(children: [
          Expanded(
            child: empty
                ? const Center(child: Text('[ НЕТ НАВЫКОВ ]',
                    style: TextStyle(letterSpacing: 2, fontSize: 12)))
                : ListView.builder(
                    itemCount: d.skills.length,
                    itemBuilder: (_, i) {
                      final s = d.skills[i];
                      return ListTile(
                        dense: true,
                        selected: i == _sel,
                        selectedTileColor: const Color(0xFF1E1E1E),
                        title: Text(
                          s.name.isEmpty ? '[ БЕЗ НАЗВАНИЯ ]' : s.name,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text('x${s.points}',
                            style: const TextStyle(fontSize: 11)),
                        onTap: () => setState(() => _sel = i),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: OutlinedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('ДОБАВИТЬ', style: TextStyle(fontSize: 11)),
            ),
          ),
        ]),
      ),
      const VerticalDivider(width: 1, color: Color(0xFF3A3A3A)),
      Expanded(
        flex: 3,
        child: skill == null
            ? const Center(child: Icon(Icons.star_outline, size: 96, color: Color(0xFF3A3A3A)))
            : PerkEditor(
                key: ValueKey(skill.id),
                skill: skill,
                onChanged: widget.onChanged,
                onDelete: () => _delete(skill),
              ),
      ),
    ]);
  }
}

// ---------- редактор навыка: правая половина ----------
class PerkEditor extends StatefulWidget {
  final Skill skill;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  const PerkEditor({super.key, required this.skill, required this.onChanged, required this.onDelete});

  @override
  State<PerkEditor> createState() => _PerkEditorState();
}

class _PerkEditorState extends State<PerkEditor> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  String? _attr;
  int _value = 1;

  @override
  void initState() {
    super.initState();
    final s = widget.skill;
    _name = TextEditingController(text: s.name);
    _desc = TextEditingController(text: s.description);
    _attr = s.specialMods.isEmpty ? null : s.specialMods.keys.first;
    _value = s.specialMods.isEmpty ? 1 : s.specialMods.values.first;
  }

  @override
  void dispose() { _name.dispose(); _desc.dispose(); super.dispose(); }

  Skill get s => widget.skill;
  InputDecoration _dec(String l) => InputDecoration(
      labelText: l, isDense: true, labelStyle: const TextStyle(fontSize: 10));

  void _saveMod() {
    s.specialMods = _attr == null ? {} : {_attr!: _value};
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        const Icon(Icons.star, size: 52, color: Color(0xFF555555)),
        const SizedBox(height: 4),
        TextField(
          controller: _name,
          style: const TextStyle(fontSize: 15),
          decoration: _dec('НАЗВАНИЕ'),
          onChanged: (v) { s.name = v; widget.onChanged(); },
        ),
        const SizedBox(height: 6),
        Row(children: [
          const Text('ОЧКОВ НАВЫКА:', style: TextStyle(fontSize: 10)),
          InkWell(
            onTap: () { setState(() => s.points = (s.points - 1).clamp(1, 5)); widget.onChanged(); },
            child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.remove, size: 14))),
          Text('${s.points}', style: const TextStyle(fontSize: 14)),
          InkWell(
            onTap: () { setState(() => s.points = (s.points + 1).clamp(1, 5)); widget.onChanged(); },
            child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.add, size: 14))),
          const SizedBox(width: 12),
          const Text('МОД.:', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          DropdownButton<String>(
            value: _attr, hint: const Text('—', style: TextStyle(fontSize: 11)),
            items: const [DropdownMenuItem<String>(value: null, child: Text('—'))]
                .followedBy(GameData.specialKeys.map((k) =>
                    DropdownMenuItem<String>(value: k, child: Text(k, style: const TextStyle(fontSize: 11)))))
                .toList(),
            onChanged: (v) { setState(() => _attr = v); _saveMod(); },
          ),
          if (_attr != null) ...[
            const SizedBox(width: 4),
            DropdownButton<int>(
              value: _value,
              items: [for (var v = -3; v <= 3; v++) v]
                  .map((v) => DropdownMenuItem(value: v,
                      child: Text('${v > 0 ? '+' : ''}$v', style: const TextStyle(fontSize: 11))))
                  .toList(),
              onChanged: (v) { setState(() => _value = v ?? 1); _saveMod(); },
            ),
          ],
        ]),
        const SizedBox(height: 6),
        Expanded(child: TextField(
          controller: _desc,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: const TextStyle(fontSize: 12),
          decoration: _dec('ОПИСАНИЕ'),
          onChanged: (v) { s.description = v; widget.onChanged(); },
        )),
        const SizedBox(height: 6),
        OutlinedButton(
          onPressed: widget.onDelete,
          child: const Text('УДАЛИТЬ', style: TextStyle(fontSize: 11)),
        ),
      ]),
    );
  }
}

