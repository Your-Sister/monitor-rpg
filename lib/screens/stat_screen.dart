import 'dart:convert';
import 'package:flutter/material.dart';
import '../models.dart';

class StatScreen extends StatefulWidget {
  final GameData data; final VoidCallback onChanged;
  const StatScreen({super.key, required this.data, required this.onChanged});
  @override State<StatScreen> createState() => _StatScreenState();
}

class _StatScreenState extends State<StatScreen> with SingleTickerProviderStateMixin {
  late final TabController _tc;
  GameData get d => widget.data;

  @override void initState() { super.initState(); _tc = TabController(length: 3, vsync: this); }
  @override void dispose() { _tc.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 32,
        child: TabBar(
          controller: _tc,
          labelStyle: const TextStyle(fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold),
          unselectedLabelColor: const Color(0xFF555555), indicatorColor: const Color(0xFFB5B5B5),
          tabs: const [Tab(text: 'ПАРАМ.'), Tab(text: 'НАВЫКИ'), Tab(text: 'ЧЕРТЫ')],
        ),
      ),
      Expanded(
        child: TabBarView(controller: _tc, children: [
          ParamsTab(data: d, onChanged: widget.onChanged),
          SkillsTab(data: d, onChanged: widget.onChanged),
          TraitsTab(data: d, onChanged: widget.onChanged),
        ]),
      ),
    ]);
  }
}

class GameDataProvider extends InheritedWidget {
  final GameData data;
  const GameDataProvider({super.key, required this.data, required super.child});
  static GameData of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GameDataProvider>()!.data;
  @override bool updateShouldNotify(GameDataProvider oldWidget) => oldWidget.data != data;
}

// ==================== ПАРАМ. ====================
class ParamsTab extends StatelessWidget {
  final GameData data; final VoidCallback onChanged;
  const ParamsTab({super.key, required this.data, required this.onChanged});

  void _levelUp() {
    data.character.level++; data.character.xp = 0; data.character.hp = data.maxHp;
    data.character.skillPoints += data.skillRate; onChanged();
  }

  Future<void> _export(BuildContext context) async {
    final ctrl = TextEditingController(text: data.exportJson());
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('ЭКСПОРТ JSON', style: TextStyle(fontSize: 13)),
      content: SizedBox(width: 440, height: 250, child: TextField(
        controller: ctrl, maxLines: null, expands: true, readOnly: true, style: const TextStyle(fontSize: 9),
      )),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ЗАКРЫТЬ', style: TextStyle(fontSize: 11)))],
    ));
    ctrl.dispose();
  }

  Future<void> _import(BuildContext context) async {
    final ctrl = TextEditingController();
    var error = '';
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: const Text('ИМПОРТ JSON', style: TextStyle(fontSize: 13)),
        content: SizedBox(width: 440, height: 250, child: Column(children: [
          Expanded(child: TextField(controller: ctrl, maxLines: null, expands: true, textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontSize: 9), decoration: const InputDecoration(labelText: 'Вставь JSON', isDense: true, labelStyle: TextStyle(fontSize: 10)))),
          if (error.isNotEmpty) Text(error, style: const TextStyle(fontSize: 10, color: Colors.red)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ОТМЕНА', style: TextStyle(fontSize: 11))),
          FilledButton(onPressed: () {
            try { final parsed = GameData.fromJson(jsonDecode(ctrl.text)); data.replaceWith(parsed); Navigator.pop(ctx); onChanged(); }
            catch (e) { setD(() => error = 'ОШИБКА ПАРСИНГА: $e'); }
          }, child: const Text('ЗАГРУЗИТЬ', style: TextStyle(fontSize: 11))),
        ],
      ),
    ));
    ctrl.dispose();
  }

  @override Widget build(BuildContext context) {
    final d = data; final eff = d.effectiveSpecial; final base = d.character.special;
    final canLevel = d.character.xp >= d.character.xpNext;
    final rows = <(String, String)>[
      ('ОЧКИ ЗДОРОВЬЯ (MAX)', '${d.maxHp}'), ('ОЧКИ ДЕЙСТВИЙ (MAX)', '${d.maxAp}'),
      ('КЛАСС БРОНИ', '${d.armorClass}'), ('ГРУЗОПОДЪЁМНОСТЬ', '${d.carryWeight}'),
      ('УРОН БЛИЖНЕГО БОЯ', '${d.meleeDamage}'), ('ШАНС КРИТ. УДАРА, %', '${d.critChance}'),
      ('ОЧЕРЁДНОСТЬ', '${d.sequence}'), ('СКОРОСТЬ ЛЕЧЕНИЯ', '${d.healingRate}'),
      ('СРАБ. ЯДАМ, %', '${d.poisonResist}'), ('СРАБ. РАДИАЦИИ, %', '${d.radResist}'),
      ('ОЧКОВ НАВЫКОВ ЗА УРОВЕНЬ', '${d.skillRate}'), ('СВОБОДНЫХ ОЧКОВ НАВЫКОВ', '${d.character.skillPoints}'),
    ];
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 190,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 0, 6),
          child: Column(children: [
            const Row(children: [
              SizedBox(width: 36, child: Text('АТР', style: TextStyle(fontSize: 9))),
              SizedBox(width: 40, child: Center(child: Text('БАЗА', style: TextStyle(fontSize: 9)))),
              SizedBox(width: 60, child: Center(child: Text('ФАКТ', style: TextStyle(fontSize: 9)))),
            ]),
            ...GameData.specialKeys.map((k) => Expanded(
              child: Row(children: [
                SizedBox(width: 36, child: Text(specialRu[k] ?? k, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                SizedBox(width: 40, child: Center(child: Text('${base[k]}', style: const TextStyle(fontSize: 13)))),
                SizedBox(width: 60, child: Center(child: Text(
                  '${eff[k]}${eff[k] != base[k] ? ' (${eff[k]! > base[k]! ? '+' : ''}${eff[k]! - base[k]!})' : ''}',
                  style: TextStyle(fontSize: 13, color: eff[k] != base[k] ? Colors.white : null),
                ))),
              ]),
            )),
          ]),
        ),
      ),
      const VerticalDivider(width: 1, color: Color(0xFF3A3A3A)),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
          child: Column(children: [
            Row(children: [
              Expanded(child: Text('${d.character.name}   LV.${d.character.level}', style: const TextStyle(fontSize: 12, letterSpacing: 2))),
              if (canLevel) InkWell(onTap: _levelUp, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(border: Border.all()), child: const Text('НОВЫЙ УРОВЕНЬ!', style: TextStyle(fontSize: 10)))),
              Text('   НАГР. ${d.loadNow.toStringAsFixed(1)}/${d.carryWeight}', style: const TextStyle(fontSize: 9)),
            ]),
            Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 4), children: [
              for (final (label, value) in rows) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
                Expanded(child: Text(label, style: const TextStyle(fontSize: 11))),
                Text(value, style: const TextStyle(fontSize: 11, color: Colors.white)),
              ])),
            ])),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton(onPressed: () => _export(context), child: const Text('ЭКСПОРТ', style: TextStyle(fontSize: 10))),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () => _import(context), child: const Text('ИМПОРТ', style: TextStyle(fontSize: 10))),
            ]),
            const Divider(height: 6),
            Row(children: [
              Expanded(child: _miniBar('HP', d.character.hp, d.maxHp)),
              const SizedBox(width: 12),
              Expanded(child: _miniBar('LEVEL', d.character.xp, d.character.xpNext)),
              const SizedBox(width: 12),
              Expanded(child: _miniBar('AP', d.character.ap, d.maxAp)),
            ]),
          ]),
        ),
      ),
    ]);
  }
  Widget _miniBar(String label, int value, int max) => Row(children: [
    SizedBox(width: 74, child: Text('$label $value/$max', style: const TextStyle(fontSize: 10))),
    Expanded(child: SizedBox(height: 8, child: LinearProgressIndicator(value: max == 0 ? 0 : value / max, minHeight: 5, backgroundColor: const Color(0xFF1A1A1A)))),
  ]);
}

// ==================== НАВЫКИ (ЕДИНЫЙ СПИСОК) ====================
class SkillsTab extends StatefulWidget {
  final GameData data; final VoidCallback onChanged;
  const SkillsTab({super.key, required this.data, required this.onChanged});
  @override State<SkillsTab> createState() => _SkillsTabState();
}

class _SkillsTabState extends State<SkillsTab> {
  int _sel = 0;
  Skill? _draft;
  GameData get d => widget.data;

  void _commit() {
    final draft = _draft!;
    if (draft.name.trim().isEmpty) draft.name = '[ БЕЗ НАЗВАНИЯ ]';
    final i = d.skills.indexWhere((s) => s.id == draft.id);
    setState(() { if (i >= 0) { d.skills[i] = draft; } else { d.skills.add(draft); } _draft = null; });
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

  Widget _buildTileButton(String text, VoidCallback onPressed, {Color? color}) {
    return Material(color: Colors.transparent, child: InkWell(onTap: onPressed, splashColor: const Color(0xFF3A3A3A),
        child: Container(height: 36, alignment: Alignment.center, child: Text(text, style: TextStyle(fontSize: 11, letterSpacing: 1, color: color)))));
  }

  @override Widget build(BuildContext context) {
    final draft = _draft;
    if (d.skills.isNotEmpty && _sel >= d.skills.length) _sel = d.skills.length - 1;
    final skill = d.skills.isEmpty ? null : d.skills[_sel];
    
    return Row(children: [
      Expanded(flex: 2, child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(8, 3, 8, 0), child: Row(children: [
          Text('ОЧКОВ: ${d.character.skillPoints}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          const Spacer(),
          InkWell(onTap: () { d.skillSpent.clear(); d.character.skillPoints = d.skillRate; widget.onChanged(); },
              child: const Padding(padding: EdgeInsets.all(4), child: Text('СБРОС', style: TextStyle(fontSize: 9, color: Colors.redAccent)))),
        ])),
        const Divider(height: 3),
        Expanded(child: ListView.builder(itemCount: d.skills.length, itemBuilder: (_, i) {
          final s = d.skills[i]; final v = d.skillValue(s);
          final tagged = d.skillTags.contains(s.id); final cost = d.nextCost(s);
          final canBuy = d.character.skillPoints >= cost && v < 300;
          final isSelected = _sel == i && draft == null;
          return InkWell(onTap: () => setState(() { _sel = i; _draft = null; }), child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: isSelected ? const Color(0xFF1E1E1E) : Colors.transparent,
            child: Row(children: [
              Expanded(child: Text(s.name, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
              Text('$v%', style: const TextStyle(fontSize: 11, color: Colors.white)), const SizedBox(width: 6),
              InkWell(onTap: () { if (tagged) { d.skillTags.remove(s.id); } else if (d.skillTags.length < 3) { d.skillTags.add(s.id); } widget.onChanged(); },
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(border: Border.all(), color: tagged ? Colors.white12 : Colors.transparent),
                      child: Text('TAG', style: TextStyle(fontSize: 8, color: tagged ? Colors.white : const Color(0xFF777777))))),
              const SizedBox(width: 6),
              InkWell(onTap: canBuy ? () { d.character.skillPoints -= cost; d.skillSpent[s.id] = (d.skillSpent[s.id] ?? 0) + 1; widget.onChanged(); } : null,
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(border: Border.all(color: canBuy ? Colors.white54 : const Color(0xFF333333))),
                      child: Text('+$cost%', style: TextStyle(fontSize: 8, color: canBuy ? null : const Color(0xFF444444))))),
            ]),
          ));
        })),
        Padding(padding: const EdgeInsets.all(6), child: Row(children: [
          Expanded(child: _buildTileButton('ДОБАВИТЬ НОВЫЙ', () => setState(() => _draft = Skill()))),
        ])),
      ])),
      const VerticalDivider(width: 1, color: Color(0xFF3A3A3A)),
      Expanded(flex: 3, child: draft != null ? PerkEditor(skill: draft, onDone: _commit, onCancel: () => setState(() => _draft = null))
          : skill == null ? const Center(child: Icon(Icons.star_outline, size: 96, color: Color(0xFF3A3A3A))) : _skillView(skill)),
    ]);
  }

  Widget _skillView(Skill s) => Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Icon(Icons.star, size: 48, color: Color(0xFF555555)), const SizedBox(height: 8),
    Text(s.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 4),
    Text('РАНГОВ: ${s.points}', style: const TextStyle(fontSize: 11)),
    Text('МОД. SPECIAL: ${s.specialMods.isEmpty ? 'нет' : modsToStringF(s.specialMods)}', style: const TextStyle(fontSize: 11)),
    Text('ФОРМУЛА БАЗЫ: ${s.baseFormula}', style: const TextStyle(fontSize: 11, color: Color(0xFF777777))),
    const SizedBox(height: 12), const Divider(color: Color(0xFF3A3A3A)), const SizedBox(height: 8),
    Expanded(child: SingleChildScrollView(child: Text(s.description.isEmpty ? '[ НЕТ ОПИСАНИЯ ]' : s.description, style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFFCCCCCC))))),
    const SizedBox(height: 8),
    Row(children: [
      Expanded(child: _buildTileButton('ИЗМЕНИТЬ', () => setState(() => _draft = Skill.fromJson(s.toJson())))),
      Expanded(child: _buildTileButton('УДАЛИТЬ', () => _delete(s), color: Colors.redAccent)),
    ]),
  ]));
}

class PerkEditor extends StatefulWidget {
  final Skill skill; final VoidCallback onDone, onCancel;
  const PerkEditor({super.key, required this.skill, required this.onDone, required this.onCancel});
  @override State<PerkEditor> createState() => _PerkEditorState();
}

class _PerkEditorState extends State<PerkEditor> {
  late final TextEditingController _name, _desc, _formula;
  late List<MapEntry<String, String>> _mods;
  late List<TextEditingController> _modCtrls;

  @override void initState() {
    super.initState();
    _name = TextEditingController(text: widget.skill.name);
    _desc = TextEditingController(text: widget.skill.description);
    _formula = TextEditingController(text: widget.skill.baseFormula);
    _mods = widget.skill.specialMods.entries.toList();
    _modCtrls = _mods.map((e) => TextEditingController(text: e.value)).toList();
  }
  @override void dispose() {
    _name.dispose(); _desc.dispose(); _formula.dispose();
    for (final c in _modCtrls) { c.dispose(); }
    super.dispose();
  }
  Skill get s => widget.skill;
  InputDecoration _dec(String l) => InputDecoration(labelText: l, isDense: true, labelStyle: const TextStyle(fontSize: 10));

  void _addMod() { setState(() { _mods.add(const MapEntry('S', '1')); _modCtrls.add(TextEditingController(text: '1')); }); }

  @override Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        const Icon(Icons.star_outline, size: 36, color: Color(0xFF555555)),
        TextField(controller: _name, style: const TextStyle(fontSize: 14), decoration: _dec('НАЗВАНИЕ'), onChanged: (v) => s.name = v),
        const SizedBox(height: 4),
        TextField(controller: _formula, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'), decoration: _dec('ФОРМУЛА БАЗОВОГО ШАНСА (напр. 5+4*A)'), onChanged: (v) => s.baseFormula = v),
        const SizedBox(height: 4),
        Row(children: [
          const Text('РАНГОВ:', style: TextStyle(fontSize: 10)),
          InkWell(onTap: () => setState(() => s.points = (s.points - 1).clamp(1, 5)), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.remove, size: 14))),
          Text('${s.points}', style: const TextStyle(fontSize: 14)),
          InkWell(onTap: () => setState(() => s.points = (s.points + 1).clamp(1, 5)), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.add, size: 14))),
        ]),
        Align(alignment: Alignment.centerLeft, child: InkWell(onTap: _addMod, child: const Padding(padding: EdgeInsets.all(4), child: Text('+ МОД. SPECIAL (формула)', style: TextStyle(fontSize: 10))))),
        for (var i = 0; i < _mods.length; i++)
          Row(children: [
            DropdownButton<String>(value: _mods[i].key, items: GameData.specialKeys.map((k) => DropdownMenuItem(value: k, child: Text(specialRu[k] ?? k, style: const TextStyle(fontSize: 11)))).toList(),
                onChanged: (v) => setState(() => _mods[i] = MapEntry(v ?? 'S', _mods[i].value))),
            const SizedBox(width: 6),
            Expanded(child: TextField(controller: _modCtrls[i], style: const TextStyle(fontSize: 11), decoration: const InputDecoration(isDense: true, hintText: '1, rank, L/2', hintStyle: TextStyle(fontSize: 9, color: Color(0xFF555555))), onChanged: (v) => _mods[i] = MapEntry(_mods[i].key, v))),
            InkWell(onTap: () => setState(() { _mods.removeAt(i); _modCtrls.removeAt(i).dispose(); }), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 14))),
          ]),
        const SizedBox(height: 4),
        TextField(controller: _desc, minLines: 4, maxLines: null, textAlignVertical: TextAlignVertical.top, style: const TextStyle(fontSize: 12), decoration: _dec('ОПИСАНИЕ'), onChanged: (v) => s.description = v),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _buildTileButton('ГОТОВО', () { s.specialMods = Map.fromEntries(_mods); widget.onDone(); })),
          Expanded(child: _buildTileButton('ОТМЕНА', widget.onCancel)),
        ]),
      ]),
    );
  }
  
  Widget _buildTileButton(String text, VoidCallback onPressed, {Color? color}) {
    return Material(color: Colors.transparent, child: InkWell(onTap: onPressed, splashColor: const Color(0xFF3A3A3A),
        child: Container(height: 36, alignment: Alignment.center, child: Text(text, style: TextStyle(fontSize: 11, letterSpacing: 1, color: color)))));
  }
}

// ==================== ЧЕРТЫ ====================
class TraitsTab extends StatefulWidget {
  final GameData data; final VoidCallback onChanged;
  const TraitsTab({super.key, required this.data, required this.onChanged});
  @override State<TraitsTab> createState() => _TraitsTabState();
}

class _TraitsTabState extends State<TraitsTab> {
  int _sel = 0;
  GameData get d => widget.data;

  @override Widget build(BuildContext context) {
    if (_sel >= traitDefs.length) _sel = traitDefs.length - 1;
    if (_sel < 0) _sel = 0;
    final selectedTrait = traitDefs[_sel];

    return Row(children: [
      Expanded(flex: 2, child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(8, 3, 8, 0), child: Row(children: [
          Text('ВЫБРАНО: ${d.traits.length}/2', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ])),
        const Divider(height: 3),
        Expanded(child: ListView.builder(itemCount: traitDefs.length, itemBuilder: (_, i) {
          final t = traitDefs[i]; final isSelected = _sel == i; final hasTrait = d.hasTrait(t.id);
          final disabled = !hasTrait && d.traits.length >= 2;
          return InkWell(onTap: () {
            setState(() { _sel = i; });
            if (hasTrait) { d.traits.remove(t.id); } else if (!disabled) { d.traits.add(t.id); }
            widget.onChanged();
          }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), color: isSelected ? const Color(0xFF1E1E1E) : Colors.transparent,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(hasTrait ? Icons.check_box : Icons.check_box_outline_blank, size: 16, color: disabled && !hasTrait ? const Color(0xFF444444) : null),
                const SizedBox(width: 8),
                Expanded(child: Text(t.name, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: disabled && !hasTrait ? const Color(0xFF444444) : null))),
              ])));
        })),
      ])),
      const VerticalDivider(width: 1, color: Color(0xFF3A3A3A)),
      Expanded(flex: 3, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline, size: 48, color: Color(0xFF555555)), const SizedBox(height: 8),
        Text(selectedTrait.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12), const Divider(color: Color(0xFF3A3A3A)), const SizedBox(height: 8),
        Expanded(child: SingleChildScrollView(child: Text(selectedTrait.description, style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFFCCCCCC))))),
      ]))),
    ]);
  }
}
