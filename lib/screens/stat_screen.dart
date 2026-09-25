import 'package:flutter/material.dart';
import '../models.dart';

class InvScreen extends StatefulWidget {
  final GameData data; final VoidCallback onChanged;
  const InvScreen({super.key, required this.data, required this.onChanged});
  @override State<InvScreen> createState() => _InvScreenState();
}

class _InvScreenState extends State<InvScreen> {
  String? _selId;
  Item? _draft;
  GameData get d => widget.data;
  final Set<String> _expanded = {'weapon'};

  void _toggleCategory(String cat) {
    setState(() {
      if (_expanded.contains(cat)) { _expanded.remove(cat); } else { _expanded.add(cat); }
    });
  }

  void _commit() {
    final draft = _draft!;
    if (draft.name.trim().isEmpty) draft.name = '[ БЕЗ НАЗВАНИЯ ]';
    final i = d.items.indexWhere((it) => it.id == draft.id);
    setState(() {
      if (i >= 0) { d.items[i] = draft; } else { d.items.add(draft); }
      _draft = null; _selId = draft.id;
      if (!_expanded.contains(draft.category)) _expanded.add(draft.category);
    });
    widget.onChanged();
  }

  void _delete(Item it) {
    setState(() { d.items.remove(it); if (_selId == it.id) _selId = null; });
    widget.onChanged();
  }

  Widget _buildTileButton(String text, VoidCallback onPressed, {Color? color}) {
    return Material(color: Colors.transparent, child: InkWell(onTap: onPressed, splashColor: const Color(0xFF3A3A3A),
        child: Container(height: 36, alignment: Alignment.center, child: Text(text, style: TextStyle(fontSize: 11, letterSpacing: 1, color: color)))));
  }

  @override Widget build(BuildContext context) {
    final draft = _draft;
    final selectedItem = _selId != null ? d.items.firstWhere((it) => it.id == _selId, orElse: () => Item(id: 'notfound')) : null;
    final actualItem = selectedItem?.id != 'notfound' ? selectedItem : null;

    return Row(children: [
      Expanded(flex: 2, child: Column(children: [
        Expanded(child: ListView(children: ItemCategory.all.map((cat) {
          final itemsInCat = d.items.where((i) => i.category == cat).toList();
          final isExpanded = _expanded.contains(cat);
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(onTap: () => _toggleCategory(cat), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), color: const Color(0xFF1A1A1A),
                child: Row(children: [
                  Icon(isExpanded ? Icons.expand_more : Icons.chevron_right, size: 16, color: const Color(0xFFB5B5B5)),
                  const SizedBox(width: 6),
                  Text(ItemCategory.shortLabels[cat] ?? cat, style: const TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${itemsInCat.length}', style: const TextStyle(fontSize: 10, color: Color(0xFF777777))),
                ]))),
            if (isExpanded) ...itemsInCat.map((it) {
              final isSelected = it.id == _selId;
              return InkWell(onTap: () => setState(() => _selId = it.id), child: Container(padding: const EdgeInsets.only(left: 32, right: 8, top: 6, bottom: 6),
                  color: isSelected ? const Color(0xFF2A2A2A) : Colors.transparent,
                  child: Row(children: [
                    Expanded(child: Text(it.name.isEmpty ? '[ БЕЗ НАЗВАНИЯ ]' : it.name, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), overflow: TextOverflow.ellipsis)),
                    if (it.count > 1) Text('x${it.count}', style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
                    if (it.equipped) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.check, size: 12, color: Color(0xFFB5B5B5))),
                  ])));
            }),
          ]);
        }).toList())),
        Padding(padding: const EdgeInsets.all(6), child: Row(children: [
          Expanded(child: _buildTileButton('ДОБАВИТЬ ПРЕДМЕТ', () => setState(() => _draft = Item(category: ItemCategory.junk)))),
        ])),
      ])),
      const VerticalDivider(width: 1, color: Color(0xFF3A3A3A)),
      Expanded(flex: 3, child: draft != null ? ItemEditor(item: draft, onDone: _commit, onCancel: () => setState(() => _draft = null))
          : actualItem == null ? const Center(child: Icon(Icons.inventory_2_outlined, size: 96, color: Color(0xFF3A3A3A))) : _itemView(actualItem)),
    ]);
  }

  Widget _itemView(Item it) => Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(it.equipped ? Icons.check_box : it.equipable ? Icons.check_box_outline_blank : Icons.circle, size: 56, color: const Color(0xFF555555)),
    const SizedBox(height: 8),
    Text(it.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 4),
    Text('КОЛ-ВО: ${it.count}  |  ВЕС: ${it.weight}  |  ЦЕНА: ${it.price}', style: const TextStyle(fontSize: 11)),
    Text('МОД.: ${it.specialMods.isEmpty ? 'нет' : modsToString(it.specialMods)}', style: const TextStyle(fontSize: 11)),
    const SizedBox(height: 12), const Divider(color: Color(0xFF3A3A3A)), const SizedBox(height: 8),
    Expanded(child: SingleChildScrollView(child: Text(it.description.isEmpty ? '[ НЕТ ОПИСАНИЯ ]' : it.description, style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFFCCCCCC))))),
    const SizedBox(height: 8),
    Row(children: [
      if (it.equipable) Expanded(child: _buildTileButton(it.equipped ? 'СНЯТЬ' : 'ЭКИПИРОВАТЬ', () { setState(() => it.equipped = !it.equipped); widget.onChanged(); })),
      if (it.equipable) const SizedBox(width: 4),
      Expanded(child: _buildTileButton('ИЗМЕНИТЬ', () => setState(() => _draft = Item.fromJson(it.toJson())))),
      const SizedBox(width: 4),
      Expanded(child: _buildTileButton('ВЫБРОСИТЬ', () => _delete(it), color: Colors.redAccent)),
    ]),
  ]));
}

class ItemEditor extends StatefulWidget {
  final Item item; final VoidCallback onDone, onCancel;
  const ItemEditor({super.key, required this.item, required this.onDone, required this.onCancel});
  @override State<ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<ItemEditor> {
  late final TextEditingController _name, _desc, _weight, _price, _count;
  late bool _equipable;
  late List<MapEntry<String, String>> _mods;
  late List<TextEditingController> _modCtrls;

  @override void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item.name);
    _desc = TextEditingController(text: widget.item.description);
    _weight = TextEditingController(text: widget.item.weight.toString());
    _price = TextEditingController(text: widget.item.price.toString());
    _count = TextEditingController(text: widget.item.count.toString());
    _equipable = widget.item.equipable;
    _mods = widget.item.specialMods.entries.map((e) => MapEntry(e.key, e.value.toString())).toList();
    _modCtrls = _mods.map((e) => TextEditingController(text: e.value)).toList();
  }
  @override void dispose() {
    _name.dispose(); _desc.dispose(); _weight.dispose(); _price.dispose(); _count.dispose();
    for (final c in _modCtrls) { c.dispose(); }
    super.dispose();
  }
  Item get it => widget.item;
  InputDecoration _dec(String l) => InputDecoration(labelText: l, isDense: true, labelStyle: const TextStyle(fontSize: 10));

  void _addMod() { setState(() { _mods.add(const MapEntry('S', '1')); _modCtrls.add(TextEditingController(text: '1')); }); }

  Widget _buildTileButton(String text, VoidCallback onPressed, {Color? color}) {
    return Material(color: Colors.transparent, child: InkWell(onTap: onPressed, splashColor: const Color(0xFF3A3A3A),
        child: Container(height: 36, alignment: Alignment.center, child: Text(text, style: TextStyle(fontSize: 11, letterSpacing: 1, color: color)))));
  }

  @override Widget build(BuildContext context) {
    return SingleChildScrollView( // ИСПРАВЛЕНИЕ ПЕРЕПОЛНЕНИЯ
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        const Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xFF555555)),
        TextField(controller: _name, style: const TextStyle(fontSize: 14), decoration: _dec('НАЗВАНИЕ'), onChanged: (v) => it.name = v),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: TextField(controller: _weight, keyboardType: TextInputType.number, decoration: _dec('ВЕС'), onChanged: (v) => it.weight = double.tryParse(v) ?? 0)),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _price, keyboardType: TextInputType.number, decoration: _dec('ЦЕНА'), onChanged: (v) => it.price = int.tryParse(v) ?? 0)),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _count, keyboardType: TextInputType.number, decoration: _dec('КОЛ-ВО'), onChanged: (v) => it.count = int.tryParse(v) ?? 1)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Checkbox(value: _equipable, onChanged: (v) => setState(() { _equipable = v ?? false; it.equipable = _equipable; })),
          const Text('МОЖНО ЭКИПИРОВАТЬ', style: TextStyle(fontSize: 10)),
        ]),
        Align(alignment: Alignment.centerLeft, child: InkWell(onTap: _addMod, child: const Padding(padding: EdgeInsets.all(4), child: Text('+ МОД. SPECIAL (формула)', style: TextStyle(fontSize: 10))))),
        for (var i = 0; i < _mods.length; i++)
          Row(children: [
            DropdownButton<String>(value: _mods[i].key, items: GameData.specialKeys.map((k) => DropdownMenuItem(value: k, child: Text(specialRu[k] ?? k, style: const TextStyle(fontSize: 11)))).toList(),
                onChanged: (v) => setState(() => _mods[i] = MapEntry(v ?? 'S', _mods[i].value))),
            const SizedBox(width: 6),
            Expanded(child: TextField(controller: _modCtrls[i], style: const TextStyle(fontSize: 11), decoration: const InputDecoration(isDense: true, hintText: '1, 2*rank', hintStyle: TextStyle(fontSize: 9, color: Color(0xFF555555))), onChanged: (v) => _mods[i] = MapEntry(_mods[i].key, v))),
            InkWell(onTap: () => setState(() { _mods.removeAt(i); _modCtrls.removeAt(i).dispose(); }), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 14))),
          ]),
        const SizedBox(height: 4),
        TextField(controller: _desc, minLines: 4, maxLines: null, textAlignVertical: TextAlignVertical.top, style: const TextStyle(fontSize: 12), decoration: _dec('ОПИСАНИЕ'), onChanged: (v) => it.description = v),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _buildTileButton('ГОТОВО', () { it.specialMods = Map.fromEntries(_mods.map((e) => MapEntry(e.key, int.tryParse(e.value) ?? 0))); widget.onDone(); })),
          Expanded(child: _buildTileButton('ОТМЕНА', widget.onCancel)),
        ]),
      ]),
    );
  }
}
