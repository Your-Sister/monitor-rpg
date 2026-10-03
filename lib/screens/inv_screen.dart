import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';

class InvScreen extends StatefulWidget {
  final GameData data;
  final VoidCallback onChanged;
  const InvScreen({super.key, required this.data, required this.onChanged});
  @override State<InvScreen> createState() => _InvScreenState();
}

class _InvScreenState extends State<InvScreen> {
  String? _selId;
  Item? _draft;
  GameData get d => widget.data;
  final Set<String> _expanded = {'weapon'};
  final ImagePicker _picker = ImagePicker();

  void _toggleCategory(String cat) {
    setState(() {
      if (_expanded.contains(cat)) {
        _expanded.remove(cat);
      } else {
        _expanded.add(cat);
      }
    });
  }

  void _commit() {
    final draft = _draft!;
    if (draft.name.trim().isEmpty) draft.name = '[ БЕЗ НАЗВАНИЯ ]';
    final i = d.items.indexWhere((it) => it.id == draft.id);
    setState(() {
      if (i >= 0) {
        d.items[i] = draft;
      } else {
        d.items.add(draft);
      }
      _draft = null;
      _selId = draft.id;
      if (!_expanded.contains(draft.category)) _expanded.add(draft.category);
    });
    widget.onChanged();
  }

  void _delete(Item it) {
    setState(() {
      d.items.remove(it);
      if (_selId == it.id) _selId = null;
    });
    widget.onChanged();
  }

  void _useItem(Item it) {
    if (it.type == 'мед' || it.type == 'еда') {
      d.applyItemEffects(it);
      it.count--;
      if (it.count <= 0) {
        d.items.remove(it);
        if (_selId == it.id) _selId = null;
      }
      widget.onChanged();
    } else if (it.equipable) {
      setState(() { it.equipped = !it.equipped; });
      widget.onChanged();
    }
  }

  Future<void> _pickImage() async {
    if (_draft == null) return;
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() { _draft!.imagePath = image.path; });
    }
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
    final selectedItem = _selId != null
        ? d.items.firstWhere((it) => it.id == _selId, orElse: () => Item(id: 'notfound'))
        : null;
    final actualItem = selectedItem?.id != 'notfound' ? selectedItem : null;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: ItemCategory.all.map((cat) {
                    final itemsInCat = d.items.where((i) => i.category == cat).toList();
                    final isExpanded = _expanded.contains(cat);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => _toggleCategory(cat),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            color: const Color(0xFF1A1A1A),
                            child: Row(
                              children: [
                                Icon(isExpanded ? Icons.expand_more : Icons.chevron_right, size: 16, color: const Color(0xFFB5B5B5)),
                                const SizedBox(width: 6),
                                Text(ItemCategory.shortLabels[cat] ?? cat, style: const TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text('${itemsInCat.length}', style: const TextStyle(fontSize: 10, color: Color(0xFF777777))),
                              ],
                            ),
                          ),
                        ),
                        if (isExpanded)
                          ...itemsInCat.map((it) {
                            final isSelected = it.id == _selId;
                            return InkWell(
                              onTap: () => setState(() => _selId = it.id),
                              child: Container(
                                padding: const EdgeInsets.only(left: 32, right: 8, top: 6, bottom: 6),
                                color: isSelected ? const Color(0xFF2A2A2A) : Colors.transparent,
                                child: Row(
                                  children: [
                                    if (it.imagePath != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.file(File(it.imagePath!), width: 24, height: 24, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 24, color: Color(0xFF555555))),
                                      )
                                    else
                                      const SizedBox(width: 24),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(it.name.isEmpty ? '[ БЕЗ НАЗВАНИЯ ]' : it.name,
                                          style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    if (it.count > 1) Text('x${it.count}', style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
                                    if (it.equipped) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.check, size: 12, color: Color(0xFFB5B5B5))),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Expanded(child: _buildTileButton('ДОБАВИТЬ ПРЕДМЕТ', () => setState(() => _draft = Item(category: ItemCategory.weapon)))),
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
              ? ItemEditor(
                  item: draft,
                  onDone: _commit,
                  onCancel: () => setState(() => _draft = null),
                  onPickImage: _pickImage,
                )
              : actualItem == null
                  ? const Center(child: Icon(Icons.inventory_2_outlined, size: 96, color: Color(0xFF3A3A3A)))
                  : _itemView(actualItem),
        ),
      ],
    );
  }

  Widget _itemView(Item it) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: it.imagePath != null
                    ? Image.file(File(it.imagePath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1A1A), child: const Icon(Icons.image, size: 48, color: Color(0xFF555555))))
                    : Container(color: const Color(0xFF1A1A1A), child: const Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFF555555))),
              ),
            ),
            const SizedBox(height: 12),
            Text(it.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(ItemCategory.getFullLabel(it.category, it.type, it.subtype), style: const TextStyle(fontSize: 10, color: Color(0xFF777777))),
            const SizedBox(height: 4),
            Text('КОЛ-ВО: ${it.count}  |  ВЕС: ${it.weight}  |  ЦЕНА: ${it.price}', style: const TextStyle(fontSize: 11)),
            if (it.specialMods.isNotEmpty) Text('МОД.: ${modsToString(it.specialMods)}', style: const TextStyle(fontSize: 11)),
            if (it.effects.isNotEmpty) Text('ЭФФЕКТЫ: ${it.effects.entries.map((e) => '${specialRu[e.key] ?? e.key}: ${e.value > 0 ? "+" : ""}${e.value}').join(", ")}', style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF3A3A3A)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(it.description.isEmpty ? '[ НЕТ ОПИСАНИЯ ]' : it.description, style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFFCCCCCC))),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (it.type == 'мед' || it.type == 'еда') Expanded(child: _buildTileButton('ИСПОЛЬЗОВАТЬ', () => _useItem(it))),
                if (it.equipable && it.type != 'мед' && it.type != 'еда') Expanded(child: _buildTileButton(it.equipped ? 'СНЯТЬ' : 'ЭКИПИРОВАТЬ', () { setState(() => it.equipped = !it.equipped); widget.onChanged(); })),
                if (it.equipable && it.type != 'мед' && it.type != 'еда') const SizedBox(width: 4),
                Expanded(child: _buildTileButton('ИЗМЕНИТЬ', () => setState(() => _draft = Item.fromJson(it.toJson())))),
                const SizedBox(width: 4),
                Expanded(child: _buildTileButton('УДАЛИТЬ', () => _delete(it), color: Colors.redAccent)),
              ],
            ),
          ],
        ),
      );
}

class ItemEditor extends StatefulWidget {
  final Item item;
  final VoidCallback onDone, onCancel;
  final VoidCallback onPickImage;
  const ItemEditor({super.key, required this.item, required this.onDone, required this.onCancel, required this.onPickImage});
  @override State<ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<ItemEditor> {
  late final TextEditingController _name, _desc, _weight, _price, _count;
  late bool _equipable;
  late List<MapEntry<String, String>> _mods;
  late List<TextEditingController> _modCtrls;
  late List<MapEntry<String, String>> _effects;
  late List<TextEditingController> _effectCtrls;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item.name);
    _desc = TextEditingController(text: widget.item.description);
    _weight = TextEditingController(text: widget.item.weight.toString());
    _price = TextEditingController(text: widget.item.price.toString());
    _count = TextEditingController(text: widget.item.count.toString());
    _equipable = widget.item.equipable;
    _mods = widget.item.specialMods.entries.map((e) => MapEntry(e.key, e.value.toString())).toList();
    _modCtrls = _mods.map((e) => TextEditingController(text: e.value)).toList();
    _effects = widget.item.effects.entries.map((e) => MapEntry(e.key, e.value.toString())).toList();
    _effectCtrls = _effects.map((e) => TextEditingController(text: e.value)).toList();
  }

  @override
  void dispose() {
    _name.dispose(); _desc.dispose(); _weight.dispose(); _price.dispose(); _count.dispose();
    for (final c in _modCtrls) c.dispose();
    for (final c in _effectCtrls) c.dispose();
    super.dispose();
  }

  Item get it => widget.item;
  InputDecoration _dec(String l) => InputDecoration(labelText: l, isDense: true, labelStyle: const TextStyle(fontSize: 10));

  void _addMod() { setState(() { _mods.add(const MapEntry('S', '1')); _modCtrls.add(TextEditingController(text: '1')); }); }
  void _addEffect() { setState(() { _effects.add(const MapEntry('hp', '10')); _effectCtrls.add(TextEditingController(text: '10')); }); }

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
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: it.imagePath != null
                  ? Image.file(File(it.imagePath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1A1A), child: const Icon(Icons.image, size: 48, color: Color(0xFF555555))))
                  : Container(color: const Color(0xFF1A1A1A), child: const Icon(Icons.add_a_photo, size: 48, color: Color(0xFF555555))),
            ),
          ),
          const SizedBox(height: 8),
          _buildTileButton('ПРИКРЕПИТЬ КАРТИНКУ', widget.onPickImage),
          const SizedBox(height: 12),
          TextField(controller: _name, style: const TextStyle(fontSize: 14), decoration: _dec('НАЗВАНИЕ'), onChanged: (v) => it.name = v),
          const SizedBox(height: 8),
          
          // ВЫБОР КАТЕГОРИИ, ТИПА И ПОДТИПА
          DropdownButtonFormField<String>(
            value: it.category,
            decoration: _dec('КАТЕГОРИЯ'),
            items: ItemCategory.all.map((c) => DropdownMenuItem(value: c, child: Text(ItemCategory.shortLabels[c]!))).toList(),
            onChanged: (v) {
              setState(() {
                it.category = v!;
                it.type = '';
                it.subtype = '';
              });
            },
          ),
          const SizedBox(height: 8),
          if (ItemCategory.types[it.category]!.isNotEmpty)
            DropdownButtonFormField<String>(
              value: it.type.isEmpty ? null : it.type,
              decoration: _dec('ТИП'),
              items: ItemCategory.types[it.category]!.map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
              onChanged: (v) {
                setState(() {
                  it.type = v ?? '';
                  it.subtype = '';
                });
              },
            ),
          if (ItemCategory.types[it.category]!.isNotEmpty) const SizedBox(height: 8),
          if (it.type.isNotEmpty && ItemCategory.subtypes[it.type]!.isNotEmpty)
            DropdownButtonFormField<String>(
              value: it.subtype.isEmpty ? null : it.subtype,
              decoration: _dec('ПОДТИП'),
              items: ItemCategory.subtypes[it.type]!.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
              onChanged: (v) { setState(() { it.subtype = v ?? ''; }); },
            ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: TextField(controller: _weight, keyboardType: TextInputType.number, decoration: _dec('ВЕС'), onChanged: (v) => it.weight = double.tryParse(v) ?? 0)),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _price, keyboardType: TextInputType.number, decoration: _dec('ЦЕНА'), onChanged: (v) => it.price = int.tryParse(v) ?? 0)),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _count, keyboardType: TextInputType.number, decoration: _dec('КОЛ-ВО'), onChanged: (v) => it.count = int.tryParse(v) ?? 1)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Checkbox(value: _equipable, onChanged: (v) => setState(() { _equipable = v ?? false; it.equipable = _equipable; })),
              const Text('МОЖНО ЭКИПИРОВАТЬ', style: TextStyle(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: InkWell(onTap: _addMod, child: const Padding(padding: EdgeInsets.all(4), child: Text('+ МОД. SPECIAL (формула)', style: TextStyle(fontSize: 10))))),
          for (var i = 0; i < _mods.length; i++)
            Row(
              children: [
                DropdownButton<String>(value: _mods[i].key, items: GameData.specialKeys.map((k) => DropdownMenuItem(value: k, child: Text(specialRu[k] ?? k, style: const TextStyle(fontSize: 11)))).toList(), onChanged: (v) => setState(() => _mods[i] = MapEntry(v ?? 'S', _mods[i].value))),
                const SizedBox(width: 6),
                Expanded(child: TextField(controller: _modCtrls[i], style: const TextStyle(fontSize: 11), decoration: const InputDecoration(isDense: true, hintText: '1, 2*rank', hintStyle: TextStyle(fontSize: 9, color: Color(0xFF555555))), onChanged: (v) => _mods[i] = MapEntry(_mods[i].key, v))),
                InkWell(onTap: () => setState(() { _mods.removeAt(i); _modCtrls.removeAt(i).dispose(); }), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 14))),
              ],
            ),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: InkWell(onTap: _addEffect, child: const Padding(padding: EdgeInsets.all(4), child: Text('+ ЭФФЕКТ ПРИ ИСПОЛЬЗОВАНИИ', style: TextStyle(fontSize: 10))))),
          for (var i = 0; i < _effects.length; i++)
            Row(
              children: [
                DropdownButton<String>(value: _effects[i].key, items: const ['hp', 'ap', 'S', 'P', 'E', 'C', 'I', 'A', 'L'].map((k) => DropdownMenuItem(value: k, child: Text(specialRu[k] ?? k, style: const TextStyle(fontSize: 11)))).toList(), onChanged: (v) => setState(() => _effects[i] = MapEntry(v ?? 'hp', _effects[i].value))),
                const SizedBox(width: 6),
                Expanded(child: TextField(controller: _effectCtrls[i], keyboardType: TextInputType.number, style: const TextStyle(fontSize: 11), decoration: const InputDecoration(isDense: true, hintText: '10', hintStyle: TextStyle(fontSize: 9, color: Color(0xFF555555))), onChanged: (v) => _effects[i] = MapEntry(_effects[i].key, v))),
                InkWell(onTap: () => setState(() { _effects.removeAt(i); _effectCtrls.removeAt(i).dispose(); }), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 14))),
              ],
            ),
          const SizedBox(height: 4),
          TextField(controller: _desc, minLines: 4, maxLines: null, textAlignVertical: TextAlignVertical.top, style: const TextStyle(fontSize: 12), decoration: _dec('ОПИСАНИЕ'), onChanged: (v) => it.description = v),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTileButton('ГОТОВО', () {
                it.specialMods = Map.fromEntries(_mods.map((e) => MapEntry(e.key, int.tryParse(e.value) ?? 0)));
                it.effects = Map.fromEntries(_effects.map((e) => MapEntry(e.key, int.tryParse(e.value) ?? 0)));
                widget.onDone();
              })),
              Expanded(child: _buildTileButton('ОТМЕНА', widget.onCancel)),
            ],
          ),
        ],
      ),
    );
  }
}
