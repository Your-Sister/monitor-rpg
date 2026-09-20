import 'package:flutter/material.dart';
import '../models.dart';

class InvScreen extends StatefulWidget {
  final GameData data;
  final VoidCallback onChanged;
  const InvScreen({super.key, required this.data, required this.onChanged});

  @override
  State<InvScreen> createState() => _InvScreenState();
}

class _InvScreenState extends State<InvScreen> {
  int _sel = 0;
  GameData get d => widget.data;

  @override
  Widget build(BuildContext context) {
    final empty = d.items.isEmpty;
    if (!empty && _sel >= d.items.length) _sel = d.items.length - 1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(children: [
        Expanded(
          flex: 2,
          child: empty
              ? const Center(child: Text('[ ИНВЕНТАРЬ ПУСТ — НАЖМИ + ]',
                  style: TextStyle(letterSpacing: 2, fontSize: 12)))
              : ListView.builder(
                  itemCount: d.items.length,
                  itemBuilder: (_, i) {
                    final it = d.items[i];
                    return ListTile(
                      dense: true,
                      selected: i == _sel,
                      selectedTileColor: const Color(0xFF1E1E1E),
                      leading: Icon(
                          it.equipped ? Icons.check_box
                          : it.equipable ? Icons.check_box_outline_blank
                          : Icons.circle,
                          size: 18),
                      title: Text(it.name, style: const TextStyle(fontSize: 13)),
                      subtitle: Text('${it.weight} кг  ${it.price} капс',
                          style: const TextStyle(fontSize: 10)),
                      onTap: () => setState(() => _sel = i),
                    );
                  },
                ),
        ),
        const VerticalDivider(width: 1, color: Color(0xFF3A3A3A)),
        Expanded(flex: 3, child: empty ? const Center(
            child: Icon(Icons.backpack_outlined, size: 96, color: Color(0xFF3A3A3A)))
            : _detail(d.items[_sel])),
      ]),
      floatingActionButton: FloatingActionButton.small(
          onPressed: _addItem, child: const Icon(Icons.add)),
    );
  }

  Widget _detail(Item it) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(children: [
      Icon(it.equipped ? Icons.check_box
          : it.equipable ? Icons.check_box_outline_blank : Icons.circle,
          size: 72, color: const Color(0xFF555555)),
      const SizedBox(height: 6),
      Text(it.name, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Text('ВЕС: ${it.weight} кг    ЦЕНА: ${it.price} капс',
          style: const TextStyle(fontSize: 11)),
      Text('МОДИФИКАТОРЫ: ${it.specialMods.isEmpty ? 'нет' : modsToString(it.specialMods)}',
          style: const TextStyle(fontSize: 11)),
      const Spacer(),
      if (it.equipable)
        OutlinedButton(
          onPressed: () { setState(() => it.equipped = !it.equipped); widget.onChanged(); },
          child: Text(it.equipped ? 'СНЯТЬ' : 'ЭКИПИРОВАТЬ',
              style: const TextStyle(fontSize: 12)),
        ),
      OutlinedButton(
        onPressed: () {
          setState(() => d.items.remove(it));
          widget.onChanged();
        },
        child: const Text('ВЫБРОСИТЬ', style: TextStyle(fontSize: 12)),
      ),
    ]),
  );

  Future<void> _addItem() async {
    final name = TextEditingController(),
        weight = TextEditingController(),
        price = TextEditingController();
    bool equipable = true;
    String? attr;
    int value = 1;
    InputDecoration dec(String l) => InputDecoration(
        labelText: l, isDense: true, labelStyle: const TextStyle(fontSize: 11));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: const Text('НОВЫЙ ПРЕДМЕТ', style: TextStyle(fontSize: 14)),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: dec('Название'), style: const TextStyle(fontSize: 13)),
            TextField(controller: weight, keyboardType: TextInputType.number,
                decoration: dec('Вес (кг)'), style: const TextStyle(fontSize: 13)),
            TextField(controller: price, keyboardType: TextInputType.number,
                decoration: dec('Цена (капсы)'), style: const TextStyle(fontSize: 13)),
            Row(children: [
              const Text('Экипируемый:', style: TextStyle(fontSize: 11)),
              Switch(value: equipable, onChanged: (v) => setD(() => equipable = v)),
            ]),
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
        d.items.add(Item(
          name: name.text.trim(),
          weight: double.tryParse(weight.text.replaceAll(',', '.')) ?? 0,
          price: int.tryParse(price.text) ?? 0,
          equipable: equipable,
          specialMods: attr == null ? {} : {attr!: value},
        ));
        _sel = d.items.length - 1;
      });
      widget.onChanged();
    }
  }
}

