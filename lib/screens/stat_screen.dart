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
    _tc = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() { _tc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 28,
        child: TabBar(
          controller: _tc,
          isScrollable: true,
          labelStyle: const TextStyle(fontSize: 11, letterSpacing: 2),
          unselectedLabelColor: const Color(0xFF555555),
          tabs: const [
            Tab(text: 'MAIN'), Tab(text: 'ПАРАМ.'), Tab(text: 'НАВЫКИ'),
            Tab(text: 'PERKS'), Tab(text: 'ЧЕРТЫ'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tc,
          children: [
            _mainTab(),
            const ParamsTab(),
            SkillsTab(data: d, onChanged: widget.onChanged),
            PerksPanel(data: d, onChanged: widget.onChanged),
            TraitsTab(data: d, onChanged: widget.onChanged),
          ],
        ),
      ),
    ]);
  }

  void _levelUp() {
    setState(() {
      d.character.level++;
      d.character.xp = 0;
      d.character.hp = d.maxHp;
      d.character.skillPoints += d.skillRate;
    });
    widget.onChanged();
  }

  Widget _mainTab() {
    final eff = d.effectiveSpecial;
    final base = d.character.special;
    final canLevel = d.character.xp >= d.character.xpNext;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Text('${d.character.name}   LV.${d.character.level}',
                style: const TextStyle(fontSize: 12, letterSpacing: 2)),
          ),
          if (canLevel)
            InkWell(
              onTap: _levelUp,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(border: Border.all()),
                child: const Text('НОВЫЙ УРОВЕНЬ!', style: TextStyle(fontSize: 10)),
              ),
            ),
          Text('   НАГРУЗКА ${d.loadNow.toStringAsFixed(1)}/${d.carryWeight}',
              style: const TextStyle(fontSize: 9)),
        ]),
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 200,
              child: Column(children: [
                const Row(children: [
                  SizedBox(width: 20, child: Text('АТР', style: TextStyle(fontSize: 9))),
                  SizedBox(width: 40, child: Center(child: Text('БАЗА', style: TextStyle(fontSize: 9)))),
                  SizedBox(width: 52, child: Center(child: Text('ФАКТ', style: TextStyle(fontSize: 9)))),
                ]),
                ...GameData.specialKeys.map((k) => Expanded(
                  child: Row(children: [
                    SizedBox(width: 20, child: Text(k, style: const TextStyle(fontSize: 13))),
                    SizedBox(width: 40, child: Center(child: Text('${base[k]}', style: const TextStyle(fontSize: 13)))),
                    SizedBox(width: 52, child: Center(child: Text(
                      '${eff[k]}${eff[k] != base[k] ? '(${eff[k]! > base[k]! ? '+' : ''}${eff[k]! - base[k]!})' : ''}',
                      style: TextStyle(fontSize: 13,
                          color: eff[k] != base[k] ? Colors.white : null),
                    ))),
                  ]),
                )),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFF3A3A3A))),
                child: const Center(child: Icon(Icons.person, size: 160, color: Color(0xFF4A4A4A))),
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

// ==================== ПАРАМЕТРЫ ====================
class ParamsTab extends StatelessWidget {
  const ParamsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final d = GameDataProvider.of(context);
    final rows = <(String, String)>[
      ('ОЧКИ ЗДОРОВЬЯ (MAX)', '${d.maxHp}'),
      ('ОЧКИ ДЕЙСТВИЙ (MAX)', '${d.maxAp}'),
      ('КЛАСС БРОНИ', '${d.armorClass}'),
      ('ГРУЗОПОДЪЁМНОСТЬ', '${d.carryWeight}'),
      ('УРОН БЛИЖНЕГО БОЯ', '${d.meleeDamage}'),
      ('ШАНС КРИТ. УДАРА, %', '${d.critChance}'),
      ('ОЧЕРЁДНОСТЬ', '${d.sequence}'),
      ('СКОРОСТЬ ЛЕЧЕНИЯ', '${d.healingRate}'),
      ('СРАБ. ЯДАМ, %', '${d.poisonResist}'),
      ('СРАБ. РАДИАЦИИ, %', '${d.radResist}'),
      ('ОЧКОВ НАВЫКОВ ЗА УРОВЕНЬ', '${d.skillRate}'),
      ('СВОБОДНЫХ ОЧКОВ НАВЫКОВ', '${d.character.skillPoints}'),
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
              Text(value, style: const TextStyle(fontSize: 12, color: Colors.white)),
            ]),
          ),
      ],
    );
  }
}

// хелпер доступа к GameData из контекста (устанавливается в main)
class GameDataProvider extends InheritedWidget {
  final GameData data;
  const GameDataProvider({super.key, required this.data, required super.child});

  static GameData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameDataProvider>()!.data;

  @override
  bool updateShouldNotify(GameDataProvider oldWidget) => oldWidget.data != data;
}

// ==================== НАВЫКИ ====================
class SkillsTab extends StatelessWidget {
  final GameData data;
  final VoidCallback onChanged;
  const SkillsTab({super.key, required this.data, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final d = data;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
        child: Row(children: [
          Text('ОЧКОВ НАВЫКОВ: ${d.character.skillPoints}',
              style: const TextStyle(fontSize: 11)),
          const Spacer(),
          InkWell(
            onTap: () { d.character.skillPoints = d.skillRate; onChanged(); },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Text('ОБНОВИТЬ ДО ${''}', style: TextStyle(fontSize: 10)),
            ),
          ),
        ]),
      ),
      const Divider(height: 4),
      Expanded(
        child: ListView.builder(
          itemCount: skillDefs.length,
          itemBuilder: (_, i) {
            final def = skillDefs[i];
            final v = d.skillValue(def);
            final tagged = d.skillTags.contains(def.id);
            final cost = d.nextCost(def.id);
            final canBuy = d.character.skillPoints >= cost && v < 300;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Row(children: [
                Expanded(child: Text(def.name, style: const TextStyle(fontSize: 11))),
                Text('${def.formula}  ', style: const TextStyle(fontSize: 9, color: Color(0xFF555555))),
                Text('$v%', style: const TextStyle(fontSize: 12, color: Colors.white)),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    if (tagged) { d.skillTags.remove(def.id); }
                    else if (d.skillTags.length < 3) { d.skillTags.add(def.id); }
                    onChanged();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(),
                      color: tagged ? Colors.white12 : Colors.transparent,
                    ),
                    child: Text('TAG', style: TextStyle(fontSize: 9,
                        color: tagged ? Colors.white : const Color(0xFF777777))),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: canBuy ? () {
                    d.character.skillPoints -= cost;
                    d.skillSpent[def.id] = (d.skillSpent[def.id] ?? 0) + 1;
                    onChanged();
                  } : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(border: Border.all(
                        color: canBuy ? Colors.white54 : const Color(0xFF333333))),
                    child: Text('+$cost%', style: TextStyle(fontSize: 9,
                        color: canBuy ? null : const Color(0xFF444444))),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

// ==================== ЧЕРТЫ ====================
class TraitsTab extends StatelessWidget {
  final GameData data;
  final VoidCallback onChanged;
  const TraitsTab({super.key, required this.data, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final d = data;
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: traitDefs.length,
      itemBuilder: (_, i) {
        final t = traitDefs[i];
        final sel = d.hasTrait(t.id);
        final disabled = !sel && d.traits.length >= 2;
        return InkWell(
          onTap: () {
            if (sel) { d.traits.remove(t.id); }
            else if (!disabled) { d.traits.add(t.id); }
            onChanged();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(sel ? Icons.check_box : Icons.check_box_outline_blank, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${t.name}  (${d.traits.length}/2)',
                    style: TextStyle(fontSize: 12, color: disabled && !sel ? const Color(0xFF444444) : null)),
                Text(t.description, style: const TextStyle(fontSize: 9, color: Color(0xFF777777))),
              ])),
            ]),
          ),
        );
      },
    );
  }
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
  Skill? _draft;
  GameData get d => widget.data;

  void _commit() {
    final draft = _draft!;
    if (draft.name.trim().isEmpty) draft.name = '[ БЕЗ НАЗВАНИЯ ]';
    final i = d.skills.indexWhere((s) => s.id == draft.id);
    setState(() {
      if (i >= 0) { d.skills[i] = draft; } else { d.skills.add(draft); }
      _draft = null;
    });
    widget.onChanged();
  }

  void _delete(Skill s) {
    setState(() {
      d.skills.remove(s);
      if (_sel >= d.skills.length) _sel = d.skills.length - 1;
      if (_sel < 0) _sel = 0;
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final empty = d.skills.isEmpty;
    if (!empty && _sel >= d.skills.length) _sel = d.skills.length - 1;
    final skill = empty ? null : d.skills[_sel];
    return Row(children: [
      Expanded(
        flex: 2,
        child: Column(children: [
          Expanded(
            child: draft == null && empty
                ? const Center(child: Text('[ НЕТ ПЕРКОВ ]',
                    style: TextStyle(letterSpacing: 2, fontSize: 12)))
                : ListView.builder(
                    itemCount: d.skills.length,
                    itemBuilder: (_, i) {
                      final s = d.skills[i];
                      return ListTile(
                        dense: true,
                        selected: i == _sel && draft == null,
                        selectedTileColor: const Color(0xFF1E1E1E),
                        title: Text(s.name.isEmpty ? '[ БЕЗ НАЗВАНИЯ ]' : s.name,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                        trailing: Text('x${s.points}', style: const TextStyle(fontSize: 11)),
                        onTap: () => setState(() { _sel = i; _draft = null; }),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _draft = Skill()),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('ДОБАВИТЬ', style: TextStyle(fontSize: 11)),
            ),
          ),
        ]),
      ),
      const VerticalDivider(width: 1, color: Color(0xFF3A3A3A)),
      Expanded(
        flex: 3,
        child: draft != null
            ? PerkEditor(
                key: ValueKey(draft.id),
                skill: draft,
                onDone: _commit,
                onCancel: () => setState(() => _draft = null),
              )
            : skill == null
                ? const Center(child: Icon(Icons.star_outline, size: 96, color: Color(0xFF3A3A3A)))
                : _perkView(skill),
      ),
    ]);
  }

  Widget _perkView(Skill s) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(children: [
      const Icon(Icons.star, size: 64, color: Color(0xFF555555)),
      const SizedBox(height: 6),
      Text(s.name, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
      Text('РАНГОВ: ${s.points}', style: const TextStyle(fontSize: 11)),
      Text('МОД.: ${s.specialMods.isEmpty ? 'нет' : modsToString(s.specialMods)}',
          style: const TextStyle(fontSize: 11)),
      const SizedBox(height: 6),
      Expanded(child: SingleChildScrollView(
          child: Text(s.description.isEmpty ? '[ НЕТ ОПИСАНИЯ ]' : s.description,
              style: const TextStyle(fontSize: 12, height: 1.5)))),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        OutlinedButton(
          onPressed: () => setState(() => _draft = Skill.fromJson(s.toJson())),
          child: const Text('ИЗМЕНИТЬ', style: TextStyle(fontSize: 11))),
        OutlinedButton(
          onPressed: () => _delete(s),
          child: const Text('УДАЛИТЬ', style: TextStyle(fontSize: 11))),
      ]),
    ]),
  );
}

// ---------- редактор перка (черновик, кнопка ГОТОВО) ----------
class PerkEditor extends StatefulWidget {
  final Skill skill;
  final VoidCallback onDone;
  final VoidCallback onCancel;
  const PerkEditor({super.key, required this.skill, required this.onDone, required this.onCancel});

  @override
  State<PerkEditor> createState() => _PerkEditorState();
}

class _PerkEditorState extends State<PerkEditor> {
  late final TextEditingController _name, _desc;
  late List<MapEntry<String, int>> _mods;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.skill.name);
    _desc = TextEditingController(text: widget.skill.description);
    _mods = widget.skill.specialMods.entries.toList();
  }

  @override
  void dispose() { _name.dispose(); _desc.dispose(); super.dispose(); }

  Skill get s => widget.skill;
  InputDecoration _dec(String l) => InputDecoration(
      labelText: l, isDense: true, labelStyle: const TextStyle(fontSize: 10));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        const Icon(Icons.star_outline, size: 40, color: Color(0xFF555555)),
        TextField(
          controller: _name, style: const TextStyle(fontSize: 14),
          decoration: _dec('НАЗВАНИЕ'),
          onChanged: (v) => s.name = v,
        ),
        const SizedBox(height: 4),
        Row(children: [
          const Text('РАНГОВ:', style: TextStyle(fontSize: 10)),
          InkWell(onTap: () => setState(() => s.points = (s.points - 1).clamp(1, 5)),
              child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.remove, size: 14))),
          Text('${s.points}', style: const TextStyle(fontSize: 14)),
          InkWell(onTap: () => setState(() => s.points = (s.points + 1).clamp(1, 5)),
              child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.add, size: 14))),
        ]),
        Align(alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => setState(() => _mods.add(const MapEntry('S', 1))),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Text('+ МОД. SPECIAL', style: TextStyle(fontSize: 10)),
              ),
            )),
        for (var i = 0; i < _mods.length; i++)
          Row(children: [
            DropdownButton<String>(
              value: _mods[i].key,
              items: GameData.specialKeys.map((k) => DropdownMenuItem(
                  value: k, child: Text(k, style: const TextStyle(fontSize: 11)))).toList(),
              onChanged: (v) => setState(() => _mods[i] = MapEntry(v ?? 'S', _mods[i].value)),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _mods[i].value,
              items: [for (var v = -3; v <= 3; v++) v].map((v) => DropdownMenuItem(
                  value: v, child: Text('${v > 0 ? '+' : ''}$v',
                      style: const TextStyle(fontSize: 11)))).toList(),
              onChanged: (v) => setState(() => _mods[i] = MapEntry(_mods[i].key, v ?? 1)),
            ),
            InkWell(
              onTap: () => setState(() => _mods.removeAt(i)),
              child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 14)),
            ),
          ]),
        const SizedBox(height: 4),
        Expanded(child: TextField(
          controller: _desc, maxLines: null, expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: const TextStyle(fontSize: 12),
          decoration: _dec('ОПИСАНИЕ'),
          onChanged: (v) => s.description = v,
        )),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          OutlinedButton(
            onPressed: () {
              s.specialMods = Map.fromEntries(_mods);
              widget.onDone();
            },
            child: const Text('ГОТОВО', style: TextStyle(fontSize: 11))),
          OutlinedButton(
            onPressed: widget.onCancel,
            child: const Text('ОТМЕНА', style: TextStyle(fontSize: 11))),
        ]),
      ]),
    );
  }
}

