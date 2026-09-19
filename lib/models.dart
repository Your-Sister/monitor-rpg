String modsToString(Map<String, int> mods) => mods.entries
    .map((e) => '${e.value > 0 ? '+' : ''}${e.value} ${e.key}')
    .join('  ');

class Skill {
  String id, name, description;
  Map<String, int> specialMods;
  Skill({String? id, this.name = '', this.description = '', Map<String, int>? specialMods})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        specialMods = specialMods ?? {};
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'description': description, 'mods': specialMods};
  factory Skill.fromJson(Map<String, dynamic> j) => Skill(
      id: j['id'], name: j['name'], description: j['description'],
      specialMods: Map<String, int>.from(j['mods'] ?? {}));
}

class Item {
  String id, name;
  double weight;
  int price;
  bool equipable, equipped;
  Map<String, int> specialMods;
  Item({String? id, this.name = '', this.weight = 0, this.price = 0,
      this.equipable = true, this.equipped = false, Map<String, int>? specialMods})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        specialMods = specialMods ?? {};
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'weight': weight,
      'price': price, 'equipable': equipable, 'equipped': equipped, 'mods': specialMods};
  factory Item.fromJson(Map<String, dynamic> j) => Item(
      id: j['id'], name: j['name'], weight: (j['weight'] ?? 0).toDouble(),
      price: j['price'] ?? 0, equipable: j['equipable'] ?? true,
      equipped: j['equipped'] ?? false,
      specialMods: Map<String, int>.from(j['mods'] ?? {}));
}

class Quest {
  String id, title, description, status; // active | done | failed
  Quest({String? id, this.title = '', this.description = '', this.status = 'active'})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'description': description, 'status': status};
  factory Quest.fromJson(Map<String, dynamic> j) => Quest(
      id: j['id'], title: j['title'], description: j['description'], status: j['status'] ?? 'active');
}

class Character {
  String name;
  int level, hp, ap, xp;
  Map<String, int> special;
  Character({this.name = 'WANDERER', this.level = 1, this.hp = 35, this.ap = 8,
      this.xp = 0, Map<String, int>? special})
      : special = special ?? {'S': 5, 'P': 5, 'E': 5, 'C': 5, 'I': 5, 'A': 5, 'L': 5};
  int get xpNext => level * 1000;
  Map<String, dynamic> toJson() =>
      {'name': name, 'level': level, 'hp': hp, 'ap': ap, 'xp': xp, 'special': special};
  factory Character.fromJson(Map<String, dynamic> j) => Character(
      name: j['name'] ?? 'WANDERER', level: j['level'] ?? 1, hp: j['hp'] ?? 35,
      ap: j['ap'] ?? 8, xp: j['xp'] ?? 0,
      special: Map<String, int>.from(j['special'] ?? {}));
}

class GameData {
  Character character;
  List<Skill> skills;
  List<Item> items;
  List<Quest> quests;
  static const specialKeys = ['S', 'P', 'E', 'C', 'I', 'A', 'L'];

  GameData({Character? character, List<Skill>? skills, List<Item>? items, List<Quest>? quests})
      : character = character ?? Character(),
        skills = skills ?? [],
        items = items ?? [],
        quests = quests ?? [];

  // ФАКТИЧЕСКИЙ S.P.E.C.I.A.L. = база + экипировка + умения/навыки
  Map<String, int> get effectiveSpecial {
    final m = Map<String, int>.from(character.special);
    void apply(Map<String, int> mods) =>
        mods.forEach((k, v) => m[k] = (m[k] ?? 5) + v);
    for (final it in items) { if (it.equipped) apply(it.specialMods); }
    for (final s in skills) { apply(s.specialMods); }
    return m;
  }

  // Формулы Fallout 1/2
  int get maxHp => 65 + 2 * (effectiveSpecial['E'] ?? 5) + 10 * (character.level - 1);
  int get maxAp => 5 + 2 * (effectiveSpecial['A'] ?? 5);

  void clamp() {
    character.hp = character.hp.clamp(0, maxHp);
    character.ap = character.ap.clamp(0, maxAp);
  }

  double get carryWeight =>
      items.fold(0.0, (sum, it) => sum + it.weight);

  Map<String, dynamic> toJson() => {
        'character': character.toJson(),
        'skills': skills.map((e) => e.toJson()).toList(),
        'items': items.map((e) => e.toJson()).toList(),
        'quests': quests.map((e) => e.toJson()).toList(),
      };

  factory GameData.fromJson(Map<String, dynamic> j) => GameData(
      character: Character.fromJson(Map<String, dynamic>.from(j['character'] ?? {})),
      skills: ((j['skills'] ?? []) as List).map((e) => Skill.fromJson(Map<String, dynamic>.from(e))).toList(),
      items: ((j['items'] ?? []) as List).map((e) => Item.fromJson(Map<String, dynamic>.from(e))).toList(),
      quests: ((j['quests'] ?? []) as List).map((e) => Quest.fromJson(Map<String, dynamic>.from(e))).toList());
}

