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
  GameData get d => widget.data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: d.items.isEmpty
          ? const Center(child: Text('[ ИНВЕНТАРЬ ПУСТ — НАЖМИ + ]',
              style: TextStyle(letterSpacing: 2)))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: d.items.length,
              itemBuilder: (_, i) {
                final it = d.items[i];
                return Dismissible(
                  key: Key(it.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) { setState(() => d.items.removeAt(i)); widget.onChanged(); },
                  background: Container(color: Colors.red.shade900),
                  child: ListTile(
                    dense: true,
                    leading: it.equipable
                        ? IconButton(
                            icon: Icon(it.equipped
                                ? Icons.check_box : Icons.check_box_outline_blank),
                            onPressed: () => setState(() { it.equipped = !it.equipped; widget.onChanged(); }),
                          )
                        : const Icon(Icons.circle, size: 12),
                    title: Text('${it.name}${it.equipped ? '  [ЭКИП.]' : ''}'),
                    subtitle: Text('ВЕС ${it.weight}  ЦЕНА ${it.price}'
                        '${it.specialMods.isEmpty ? '' : '   ${modsToString(it.specialMods)}'}'),
                    onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
                      title: Text(it.name),
                      content: Text('ВЕС: ${it.weight}   ЦЕНА: ${it.price}\n'
                          'МОДИФИКАТОРЫ: ${it.specialMods.isEmpty ? 'нет' : modsToString(it.specialMods)}'),
                      actions: [
                        if (it.equipable)
                          TextButton(
                            onPressed: () { setState(() => it.equipped = !it.equipped); widget.onChanged(); Navigator.pop(context); },
                            child: Text(it.equipped ? 'СНЯТЬ' : 'ЭКИПИРОВАТЬ')),
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ЗАКРЫТЬ')),
                      ],
                    )),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addItem() async {
    final name = TextEditingController(),
        weight = TextEditingController(),
        price = TextEditingController();
    bool equipable = true;
    String? attr;
    int value = 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: const Text('НОВЫЙ ПРЕДМЕТ'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Название')),
          TextField(controller: weight, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Вес (кг)')),
          TextField(controller: price, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Цена (капсы)')),
          SwitchListTile(
            title: const Text('Можно экипировать', style: TextStyle(fontSize: 13)),
            value: equipable,
            onChanged: (v) => setD(() => equipable = v),
          ),
          Row(children: [
            const Text('Мод. SPECIAL:', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: attr, hint: const Text('—'),
              items: const [DropdownMenuItem(value: null, child: Text('—'))]
                  .followedBy(GameData.specialKeys.map((k) => DropdownMenuItem(value: k, child: Text(k))))
                  .toList(),
              onChanged: (v) => setD(() => attr = v),
            ),
            if (attr != null) ...[
              const SizedBox(width: 8),
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
        d.items.add(Item(
          name: name.text.trim(),
          weight: double.tryParse(weight.text.replaceAll(',', '.')) ?? 0,
          price: int.tryParse(price.text) ?? 0,
          equipable: equipable,
          specialMods: attr == null ? {} : {attr!: value},
        ));
      });
      widget.onChanged();
    }
  }
}

