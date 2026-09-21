String modsToString(Map<String, int> mods) => mods.entries
    .map((e) => '${e.value > 0 ? '+' : ''}${e.value} ${e.key}')
    .join('  ');

class ItemCategory {
  static const weapon = 'weapon';
  static const armor = 'armor';
  static const med = 'med';
  static const tool = 'tool';
  static const junk = 'junk';
  static const all = [weapon, armor, med, tool, junk];
  static const shortLabels = {
    weapon: 'ОРУЖИЕ И БОЕП.', armor: 'БРОНЯ И ОДЕЖДА',
    med: 'МЕД. И ЕДА', tool: 'ИНСТРУМЕНТЫ', junk: 'ХЛАМ',
  };
}

// ==================== НАВЫКИ FALLOUT 2 ====================
class SkillDef {
  final String id, name, formula;
  final int Function(Map<String, int>) base;
  SkillDef(this.id, this.name, this.formula, this.base);
}

final skillDefs = <SkillDef>[
  SkillDef('smallGuns', 'ЛЁГКОЕ ОРУЖИЕ', '5+4*A', (s) => 5 + 4 * (s['A'] ?? 5)),
  SkillDef('bigGuns', 'ТЯЖЁЛОЕ ОРУЖИЕ', '2*A', (s) => 2 * (s['A'] ?? 5)),
  SkillDef('energy', 'ЭНЕРГЕТИЧЕСКОЕ ОРУЖИЕ', '2*A', (s) => 2 * (s['A'] ?? 5)),
  SkillDef('unarmed', 'БЕЗ ОРУЖИЯ', '30+2*(A+S)', (s) => 30 + 2 * ((s['A'] ?? 5) + (s['S'] ?? 5))),
  SkillDef('melee', 'ХОЛОДНОЕ ОРУЖИЕ', '20+2*(A+S)', (s) => 20 + 2 * ((s['A'] ?? 5) + (s['S'] ?? 5))),
  SkillDef('throwing', 'МЕТАНИЕ', '4*A', (s) => 4 * (s['A'] ?? 5)),
  SkillDef('firstAid', 'ПЕРВАЯ ПОМОЩЬ', '2*(P+I)', (s) => 2 * ((s['P'] ?? 5) + (s['I'] ?? 5))),
  SkillDef('doctor', 'ДОКТОР', '5+P+I', (s) => 5 + (s['P'] ?? 5) + (s['I'] ?? 5)),
  SkillDef('sneak', 'СКРЫТНОСТЬ', '5+3*A', (s) => 5 + 3 * (s['A'] ?? 5)),
  SkillDef('lockpick', 'ВЗЛОМ', '10+P+A', (s) => 10 + (s['P'] ?? 5) + (s['A'] ?? 5)),
  SkillDef('steal', 'КРАЖА', '3*A', (s) => 3 * (s['A'] ?? 5)),
  SkillDef('traps', 'ЛОВУШКИ', '10+P+A', (s) => 10 + (s['P'] ?? 5) + (s['A'] ?? 5)),
  SkillDef('science', 'НАУКА', '4*I', (s) => 4 * (s['I'] ?? 5)),
  SkillDef('repair', 'РЕМОНТ', '3*I', (s) => 3 * (s['I'] ?? 5)),
  SkillDef('speech', 'КРАСНОРЕЧИЕ', '5*C', (s) => 5 * (s['C'] ?? 5)),
  SkillDef('barter', 'БАРТЕР', '4*C', (s) => 4 * (s['C'] ?? 5)),
  SkillDef('gambling', 'АЗАРТНЫЕ ИГРЫ', '5*L', (s) => 5 * (s['L'] ?? 5)),
  SkillDef('outdoorsman', 'СКИТАЛЕЦ', '2*(E+I)', (s) => 2 * ((s['E'] ?? 5) + (s['I'] ?? 5))),
];

int skillCostOf(int value) =>
    value <= 100 ? 1 : value <= 125 ? 2 : value <= 150 ? 3
    : value <= 175 ? 4 : value <= 200 ? 5 : 6;

// ==================== ЧЕРТЫ ====================
class TraitDef {
  final String id, name, description;
  const TraitDef(this.id, this.name, this.description);
}

const traitDefs = [
  TraitDef('fastMetabolism', 'БЫСТРЫЙ МЕТАБОЛИЗМ', '+2 к скорости лечения; сопротивления ядам и радиации = 0'),
  TraitDef('bruiser', 'ГРОМИЛА', '+2 к Силе; −2 к Очкам действий'),
  TraitDef('smallFrame', 'ХРУПКОЕ ТЕЛОСЛОЖЕНИЕ', '+1 к Ловкости; грузоподъёмность = 25 + 15×Сила'),
  TraitDef('oneHander', 'ОДНОРУКИЙ', '+20% к точности одноручного оружия; −40% к двуручному'),
  TraitDef('finesse', 'ТОЧНОСТЬ', '+10% к шансу крита; +30% к получаемому урону'),
  TraitDef('kamikaze', 'КАМИКАДЗЕ', '+5 к Очерёдности; Класс брони = 0'),
  TraitDef('heavyHanded', 'ТЯЖЁЛАЯ РУКА', '+4 к урону в ближнем бою; −30 к таблице критов'),
  TraitDef('fastShot', 'БЫСТРЫЙ СТРЕЛОК', '−1 ОД на атаку; нельзя целиться'),
  TraitDef('bloodyMess', 'КРОВАВАЯ БАНЯ', 'Все смерти максимально кровавые'),
  TraitDef('jinxed', 'НЕУДАЧНИК', 'Промахи могут стать критическими провалами'),
  TraitDef('goodNatured', 'ДОБРОДУШНЫЙ', '+15 к Первой помощи, Доктору, Красноречию, Бартеру; −10 к боевым навыкам'),
  TraitDef('chemReliant', 'ХИМ. ЗАВИСИМОСТЬ', 'Зависимость чаще, но проходит быстрее'),
  TraitDef('chemResistant', 'УСТОЙЧИВОСТЬ К ХИМИИ', 'Эффекты химии и риск зависимости снижены вдвое'),
  TraitDef('sexAppeal', 'СЕКСУАЛЬНОСТЬ', 'Бонус к реакции противоположного пола; штраф к своему'),
  TraitDef('skilled', 'ОПЫТНЫЙ', '+5 очков навыков за уровень; перки каждые 4 уровня'),
  TraitDef('gifted', 'ОДАРЁННЫЙ', '+1 ко всем SPECIAL; −10 ко всем навыкам; −5 очков навыков за уровень'),
];

// ==================== МОДЕЛИ ====================
class Skill {
  String id, name, description;
  int points; // ранги перка
  Map<String, int> specialMods;
  Skill({String? id, this.name = '', this.description = '', this.points = 1,
      Map<String, int>? specialMods})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        specialMods = specialMods ?? {};
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'description': description, 'points': points, 'mods': specialMods};
  factory Skill.fromJson(Map<String, dynamic> j) => Skill(
      id: j['id'], name: j['name'], description: j['description'],
      points: j['points'] ?? 1,
      specialMods: Map<String, int>.from(j['mods'] ?? {}));
}

class Item {
  String id, name, category, description;
  double weight;
  int price;
  bool equipable, equipped;
  Map<String, int> specialMods;
  Item({String? id, this.name = '', this.category = ItemCategory.junk,
      this.description = '', this.weight = 0, this.price = 0,
      this.equipable = false, this.equipped = false, Map<String, int>? specialMods})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        specialMods = specialMods ?? {};
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'category': category,
      'description': description, 'weight': weight, 'price': price,
      'equipable': equipable, 'equipped': equipped, 'mods': specialMods};
  factory Item.fromJson(Map<String, dynamic> j) => Item(
      id: j['id'], name: j['name'], category: j['category'] ?? ItemCategory.junk,
      description: j['description'] ?? '', weight: (j['weight'] ?? 0).toDouble(),
      price: j['price'] ?? 0, equipable: j['equipable'] ?? false,
      equipped: j['equipped'] ?? false,
      specialMods: Map<String, int>.from(j['mods'] ?? {}));
}

class Quest {
  String id, title, description, status;
  Quest({String? id, this.title = '', this.description = '', this.status = 'active'})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'description': description, 'status': status};
  factory Quest.fromJson(Map<String, dynamic> j) => Quest(
      id: j['id'], title: j['title'], description: j['description'],
      status: j['status'] ?? 'active');
}

class Character {
  String name;
  int level, hp, ap, xp, skillPoints;
  Map<String, int> special;
  Character({this.name = 'WANDERER', this.level = 1, this.hp = 35, this.ap = 8,
      this.xp = 0, this.skillPoints = 0, Map<String, int>? special})
      : special = special ?? {'S': 5, 'P': 5, 'E': 5, 'C': 5, 'I': 5, 'A': 5, 'L': 5};
  int get xpNext => level * 1000;
  Map<String, dynamic> toJson() => {'name': name, 'level': level, 'hp': hp, 'ap': ap,
      'xp': xp, 'skillPoints': skillPoints, 'special': special};
  factory Character.fromJson(Map<String, dynamic> j) => Character(
      name: j['name'] ?? 'WANDERER', level: j['level'] ?? 1, hp: j['hp'] ?? 35,
      ap: j['ap'] ?? 8, xp: j['xp'] ?? 0, skillPoints: j['skillPoints'] ?? 0,
      special: Map<String, int>.from(j['special'] ?? {}));
}

class GameData {
  Character character;
  List<Skill> skills;
  List<Item> items;
  List<Quest> quests;
  Map<String, int> skillSpent;   // id навыка -> вложенные %
  List<String> skillTags;        // отмеченные навыки (max 3)
  List<String> traits;           // выбранные черты (max 2)
  bool characterConfirmed;
  static const specialKeys = ['S', 'P', 'E', 'C', 'I', 'A', 'L'];

  GameData({Character? character, List<Skill>? skills, List<Item>? items,
      List<Quest>? quests, Map<String, int>? skillSpent, List<String>? skillTags,
      List<String>? traits, this.characterConfirmed = false})
      : character = character ?? Character(),
        skills = skills ?? [],
        items = items ?? [],
        quests = quests ?? [],
        skillSpent = skillSpent ?? {},
        skillTags = skillTags ?? [],
        traits = traits ?? [];

  bool hasTrait(String t) => traits.contains(t);

  List<Item> itemsByCategory(String c) => items.where((i) => i.category == c).toList();

  // ФАКТ. SPECIAL = база + экипировка + перки + черты
  Map<String, int> get effectiveSpecial {
    final m = Map<String, int>.from(character.special);
    void apply(Map<String, int> mods) =>
        mods.forEach((k, v) => m[k] = (m[k] ?? 5) + v);
    for (final it in items) { if (it.equipped) apply(it.specialMods); }
    for (final s in skills) { apply(s.specialMods); }
    if (hasTrait('gifted')) { for (final k in specialKeys) m[k] = (m[k] ?? 5) + 1; }
    if (hasTrait('smallFrame')) m['A'] = (m['A'] ?? 5) + 1;
    if (hasTrait('bruiser')) m['S'] = (m['S'] ?? 5) + 2;
    return m;
  }

  int _sp(String k) => effectiveSpecial[k] ?? 5;

  // ---- производные (формулы Fallout 2) ----
  int get maxHp => 15 + _sp('S') + 2 * _sp('E') + (character.level - 1) * (2 + _sp('E') ~/ 2);
  int get maxAp => (5 + _sp('A') ~/ 2 + (hasTrait('bruiser') ? -2 : 0)).clamp(1, 10);
  int get armorClass => hasTrait('kamikaze') ? 0 : _sp('A');
  int get carryWeight => hasTrait('smallFrame') ? 25 + 15 * _sp('S') : 25 + 25 * _sp('S');
  int get meleeDamage => (_sp('S') - 5 + (hasTrait('heavyHanded') ? 4 : 0)).clamp(1, 99);
  int get critChance => _sp('L') + (hasTrait('finesse') ? 10 : 0);
  int get sequence => 2 * _sp('P') + (hasTrait('kamikaze') ? 5 : 0);
  int get healingRate => (_sp('E') ~/ 3 + (hasTrait('fastMetabolism') ? 2 : 0)).clamp(1, 99);
  int get poisonResist => hasTrait('fastMetabolism') ? 0 : _sp('E') * 5;
  int get radResist => hasTrait('fastMetabolism') ? 0 : _sp('E') * 2;
  int get skillRate => 5 + 2 * _sp('I') + (hasTrait('skilled') ? 5 : 0) + (hasTrait('gifted') ? -5 : 0);
  double get loadNow => items.fold(0.0, (sum, it) => sum + it.weight);

  void clamp() {
    character.hp = character.hp.clamp(0, maxHp);
    character.ap = character.ap.clamp(0, maxAp);
  }

  // ---- навыки ----
  int traitSkillMod(String id) {
    var m = 0;
    if (hasTrait('gifted')) m -= 10;
    if (hasTrait('goodNatured')) {
      if (['firstAid', 'doctor', 'speech', 'barter'].contains(id)) m += 15;
      if (['smallGuns', 'bigGuns', 'energy', 'unarmed', 'melee', 'throwing'].contains(id)) m -= 10;
    }
    return m;
  }

  int skillValue(SkillDef def) {
    var v = def.base(effectiveSpecial);
    if (skillTags.contains(def.id)) v += 20;
    v += skillSpent[def.id] ?? 0;
    v += traitSkillMod(def.id);
    return v.clamp(0, 300);
  }

  int nextCost(String id) {
    final def = skillDefs.firstWhere((d) => d.id == id);
    final c = skillCostOf(skillValue(def));
    return skillTags.contains(id) ? (c / 2).ceil() : c;
  }

  Map<String, dynamic> toJson() => {
        'character': character.toJson(),
        'skills': skills.map((e) => e.toJson()).toList(),
        'items': items.map((e) => e.toJson()).toList(),
        'quests': quests.map((e) => e.toJson()).toList(),
        'skillSpent': skillSpent,
        'skillTags': skillTags,
        'traits': traits,
        'confirmed': characterConfirmed,
      };

  factory GameData.fromJson(Map<String, dynamic> j) => GameData(
      character: Character.fromJson(Map<String, dynamic>.from(j['character'] ?? {})),
      skills: ((j['skills'] ?? []) as List).map((e) => Skill.fromJson(Map<String, dynamic>.from(e))).toList(),
      items: ((j['items'] ?? []) as List).map((e) => Item.fromJson(Map<String, dynamic>.from(e))).toList(),
      quests: ((j['quests'] ?? []) as List).map((e) => Quest.fromJson(Map<String, dynamic>.from(e))).toList(),
      skillSpent: Map<String, int>.from(j['skillSpent'] ?? {}),
      skillTags: List<String>.from(j['skillTags'] ?? []),
      traits: List<String>.from(j['traits'] ?? []),
      characterConfirmed: j['confirmed'] ?? false);
}

