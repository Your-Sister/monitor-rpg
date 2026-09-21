import 'package:flutter/material.dart';
import '../models.dart';

class InvScreen extends StatefulWidget {
  final GameData data;
  final VoidCallback onChanged;
  const InvScreen({super.key, required this.data, required this.onChanged});

  @override
  State<InvScreen> createState() => _InvScreenState();
}

class _InvScreenState extends State<InvScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tc;
  int _sel = 0;
  Item? _draft;
  GameData get d => widget.data;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: ItemCategory.all.length, vsync: this);
  }

  @override
  void dispose() { _tc.dispose(); super.dispose(); }

  List<Item> get _list => d.itemsByCategory(ItemCategory.all[_tc.index]);

  IconData _icon(String c) => switch (c) {
    ItemCategory.weapon => Icons.gavel,
    ItemCategory.armor => Icons.shield_outlined,
    ItemCategory.med => Icons.healing,
    ItemCategory.tool => Icons.build,
    _ => Icons.recycling,
  };

  void _commit() {
    final draft = _draft!;
    if (draft.name.trim().isEmpty) draft.name = '[ БЕЗ НАЗВАНИЯ ]';
    final i = d.items.indexWhere((it) => it.id == draft.id);
    setState(() {
      if (i >= 0) { d.items[i] = draft; } else { d.items.add(draft); }
      _draft = null;
    });
    widget.onChanged();
  }

  void _delete(Item it) {
    setState(() {
      d.items.remove(it);
      if (_sel >= _list.length) _sel = _list.length - 1;
      if (_sel < 0) _sel = 0;
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final list = _list;
    if (list.isNotEmpty && _sel >= list.length) _sel = list.length - 1;
    final item = list.isEmpty ? null : list[_sel];
    return Column(children: [
      SizedBox(
        height: 28,
        child: TabBar(
          controller: _tc,
          isScrollable: true,
          labelStyle: const TextStyle(fontSize: 11, letterSpacing: 1),
          unselectedLabelColor: const Color(0xFF555555),
          tabs: ItemCategory.all.map((c) => Tab(text: ItemCategory.shortLabels[c])).toList(),
        ),
      ),
      Expanded(
        child: Row(children: [
          Expanded(
            flex: 2,
            child: Column(children: [
              Expanded(
                child: draft == null && list.isEmpty
                    ? const Center(child: Text('[ ПУСТО ]',
                        style: TextStyle(letterSpacing: 2, fontSize: 12)))
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) => ListTile(
                          dense: true,
                          selected: i == _sel && draft == null,
                          selectedTileColor: const Color(0xFF1E1E1E),
                          title: Text(
                            list[i].name.isEmpty ? '[ БЕЗ НАЗВАНИЯ ]' : list[i].name,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                          trailing: list[i].equipped
                              ? const Icon(Icons.check, size: 14) : null,
                          onTap: () => setState(() { _sel = i; _draft = null; }),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _draft = Item(category: ItemCategory.all[_tc.index])),
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
                ? ItemEditor(
                    key: ValueKey(draft.id),
                    item: draft,
                    onDone: _commit,
                    onCancel: () => setState(() => _draft = null),
                  )
                : item == null
                    ? Center(child: Icon(_icon(ItemCategory.all[_tc.index]),
                        size: 96, color: const Color(0xFF3A3A3A)))
                    : _itemView(item),
          ),
        ]),
      ),
    ]);
  }

  Widget _itemView(Item it) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(children: [
      Icon(it.equipped ? Icons.check_box
          : it.equipable ? Icons.check_box_outline_blank : Icons.circle,
          size: 64, color: const Color(0xFF555555)),
      const SizedBox(height: 6),
      Text(it.name, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
      Text('ВЕС: ${it.weight}    ЦЕНА: ${it.price}',
          style: const TextStyle(fontSize: 11)),
      Text('МОД.: ${it.specialMods.isEmpty ? 'нет' : modsToString(it.specialMods)}',
          style: const TextStyle(fontSize: 11)),
      const SizedBox(height: 6),
      Expanded(child: SingleChildScrollView(
          child: Text(it.description.isEmpty ? '[ НЕТ ОПИСАНИЯ ]' : it.description,
              style: const TextStyle(fontSize: 12, height: 1.5)))),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        if (it.equipable)
          OutlinedButton(
            onPressed: () { setState(() => it.equipped = !it.equipped); widget.onChanged(); },
            child: Text(it.equipped ? 'СНЯТЬ' : 'ЭКИПИРОВАТЬ', style: const TextStyle(fontSize: 11))),
        OutlinedButton(
          onPressed: () => setState(() => _draft = Item.fromJson(it.toJson())),
          child: const Text('ИЗМЕНИТЬ', style: TextStyle(fontSize: 11))),
        OutlinedButton(
          onPressed: () => _delete(it),
          child: const Text('ВЫБРОСИТЬ', style: TextStyle(fontSize: 11))),
      ]),
    ]),
  );
}

// ---------- редактор предмета (черновик, кнопка ГОТОВО, несколько модов) ----------
class ItemEditor extends StatefulWidget {
  final Item item;
  final VoidCallback onDone;
  final VoidCallback onCancel;
  const ItemEditor({super.key, required this.item, required this.onDone, required this.onCancel});

  @override
  State<ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<ItemEditor> {
  late final TextEditingController _name, _weight, _price, _desc;
  late List<MapEntry<String, int>> _mods;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _name = TextEditingController(text: it.name);
    _weight = TextEditingController(text: it.weight == 0 ? '' : '${it.weight}');
    _price = TextEditingController(text: it.price == 0 ? '' : '${it.price}');
    _desc = TextEditingController(text: it.description);
    _mods = it.specialMods.entries.toList();
  }

  @override
  void dispose() { _name.dispose(); _weight.dispose(); _price.dispose(); _desc.dispose(); super.dispose(); }

  Item get it => widget.item;
  InputDecoration _dec(String l) => InputDecoration(
      labelText: l, isDense: true, labelStyle: const TextStyle(fontSize: 10));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        TextField(
          controller: _name, style: const TextStyle(fontSize: 14),
          decoration: _dec('НАЗВАНИЕ'),
          onChanged: (v) => it.name = v,
        ),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: TextField(
            controller: _weight, keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 12), decoration: _dec('ВЕС'),
            onChanged: (v) => it.weight = double.tryParse(v.replaceAll(',', '.')) ?? 0,
          )),
          const SizedBox(width: 8),
          Expanded(child: TextField(
            controller: _price, keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 12), decoration: _dec('ЦЕНА'),
            onChanged: (v) => it.price = int.tryParse(v) ?? 0,
          )),
          const SizedBox(width: 8),
          Column(children: [
            const Text('ЭКИП.', style: TextStyle(fontSize: 9)),
            Switch(value: it.equipable, onChanged: (v) =>
                setState(() { it.equipable = v; if (!v) it.equipped = false; })),
          ]),
          const SizedBox(width: 8),
          Column(children: [
            const Text('ТИП:', style: TextStyle(fontSize: 9)),
            DropdownButton<String>(
              value: it.category,
              items: ItemCategory.all.map((c) => DropdownMenuItem(
                  value: c, child: Text(ItemCategory.shortLabels[c]!,
                      style: const TextStyle(fontSize: 10)))).toList(),
              onChanged: (v) => setState(() => it.category = v ?? ItemCategory.junk),
            ),
          ]),
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
          onChanged: (v) => it.description = v,
        )),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          OutlinedButton(
            onPressed: () {
              it.specialMods = Map.fromEntries(_mods);
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

