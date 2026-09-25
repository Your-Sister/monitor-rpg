import 'dart:convert';

const Map<String, String> specialRu = {
  'S': 'Сил', 'P': 'Вос', 'E': 'Вын', 'C': 'Хар', 'I': 'Инт', 'A': 'Лов', 'L': 'Уда',
};

String modsToString(Map<String, int> mods) => mods.entries
    .map((e) => '${e.value > 0 ? '+' : ''}${e.value} ${e.key}').join('  ');

String modsToStringF(Map<String, String> mods) =>
    mods.entries.map((e) => '${e.key}:${e.value}').join('  ');

int evalFormula(String src, Map<String, int> vars) {
  final s = src.replaceAll(' ', '').toUpperCase();
  var i = 0;
  late num Function() expr, term, factor;
  expr = () {
    num v = term();
    while (i < s.length && (s[i] == '+' || s[i] == '-')) {
      final op = s[i++]; final r = term(); v = op == '+' ? v + r : v - r;
    } return v;
  };
  term = () {
    num v = factor();
    while (i < s.length && (s[i] == '*' || s[i] == '/')) {
      final op = s[i++]; final r = factor(); v = op == '*' ? v * r : (r == 0 ? 0 : v / r);
    } return v;
  };
  factor = () {
    if (i < s.length && s[i] == '-') { i++; return -factor(); }
    if (i < s.length && s[i] == '(') { i++; final v = expr(); if (i < s.length && s[i] == ')') i++; return v; }
    final n0 = i;
    while (i < s.length && RegExp(r'[0-9.]').hasMatch(s[i])) i++;
    if (i > n0) return num.tryParse(s.substring(n0, i)) ?? 0;
    final a0 = i;
    while (i < s.length && RegExp(r'[A-Z]').hasMatch(s[i])) i++;
    if (i > a0) return vars[s.substring(a0, i)] ?? 0;
    return 0;
  };
  try { return expr().round(); } catch (_) { return 0; }
}

class ItemCategory {
  static const weapon = 'weapon', armor = 'armor', med = 'med', tool = 'tool', junk = 'junk';
  static const all = [weapon, armor, med, tool, junk];
  static const shortLabels = {
    weapon: 'ОРУЖИЕ И БОЕП.', armor: 'БРОНЯ И ОДЕЖДА', med: 'МЕД. И ЕДА', tool: 'ИНСТРУМЕНТЫ', junk: 'ХЛАМ',
  };
}

// ==================== ЕДИНАЯ МОДЕЛЬ НАВЫКА ====================
class Skill {
  String id, name, description, baseFormula;
  int points;
  Map<String, String> specialMods;
  Skill({String? id, this.name = '', this.description = '', this.baseFormula = '0', this.points = 1, Map<String, String>? specialMods})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        specialMods = specialMods ?? {};
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'description': description, 'baseFormula': baseFormula, 'points': points, 'mods': specialMods};
  factory Skill.fromJson(Map<String, dynamic> j) => Skill(
      id: j['id'], name: j['name'], description: j['description'], baseFormula: j['baseFormula'] ?? '0',
      points: j['points'] ?? 1, specialMods: Map<String, dynamic>.from(j['mods'] ?? {}).map((k, v) => MapEntry(k, '$v')));
}

List<Skill> getDefaultSkills() => [
  Skill(id: 'smallGuns', name: 'Лёгкое оружие', description: 'Навыки обращения, ухода и общие знания о лёгком огнестрельном оружии: пистолетах, ПП и винтовках.\n\nБазовый шанс: 5% + (4 x Ловкость)', baseFormula: '5+4*A'),
  Skill(id: 'bigGuns', name: 'Тяжёлое оружие', description: 'Умение обращаться с тяжёлым вооружением: пулемётами, гранатомётами и огнемётами.\n\nБазовый шанс: 2 x Ловкость', baseFormula: '2*A'),
  Skill(id: 'energy', name: 'Энергетическое оружие', description: 'Знание принципов работы и обслуживания энергетического оружия.\n\nБазовый шанс: 2 x Ловкость', baseFormula: '2*A'),
  Skill(id: 'unarmed', name: 'Без оружия', description: 'Навык рукопашного боя: удары кулаками, ногами и использование кастетов.\n\nБазовый шанс: 30% + (2 x (Ловкость + Сила))', baseFormula: '30+2*(A+S)'),
  Skill(id: 'melee', name: 'Холодное оружие', description: 'Умение сражаться холодным оружием: ножами, дубинками, мечами.\n\nБазовый шанс: 20% + (2 x (Ловкость + Сила))', baseFormula: '20+2*(A+S)'),
  Skill(id: 'throwing', name: 'Метание', description: 'Точность и техника метания ножей, гранат, копий.\n\nБазовый шанс: 4 x Ловкость', baseFormula: '4*A'),
  Skill(id: 'firstAid', name: 'Первая помощь', description: 'Базовые медицинские знания для стабилизации раненых.\n\nБазовый шанс: 2 x (Восприятие + Интеллект)', baseFormula: '2*(P+I)'),
  Skill(id: 'doctor', name: 'Доктор', description: 'Продвинутая медицина: лечение болезней, удаление яда.\n\nБазовый шанс: 5% + Восприятие + Интеллект', baseFormula: '5+P+I'),
  Skill(id: 'sneak', name: 'Скрытность', description: 'Умение двигаться бесшумно и прятаться в тенях.\n\nБазовый шанс: 5% + (3 x Ловкость)', baseFormula: '5+3*A'),
  Skill(id: 'lockpick', name: 'Взлом', description: 'Навык вскрытия замков и обхода систем безопасности.\n\nБазовый шанс: 10% + Восприятие + Ловкость', baseFormula: '10+P+A'),
  Skill(id: 'steal', name: 'Кража', description: 'Умение незаметно вытаскивать предметы из карманов.\n\nБазовый шанс: 3 x Ловкость', baseFormula: '3*A'),
  Skill(id: 'traps', name: 'Ловушки', description: 'Знание принципов установки и обезвреживания ловушек.\n\nБазовый шанс: 10% + Восприятие + Ловкость', baseFormula: '10+P+A'),
  Skill(id: 'science', name: 'Наука', description: 'Энциклопедические знания в области компьютеров и технологий.\n\nБазовый шанс: 4 x Интеллект', baseFormula: '4*I'),
  Skill(id: 'repair', name: 'Ремонт', description: 'Умение чинить технику, оружие и роботов.\n\nБазовый шанс: 3 x Интеллект', baseFormula: '3*I'),
  Skill(id: 'speech', name: 'Красноречие', description: 'Искусство убеждения, ведения переговоров и манипуляции.\n\nБазовый шанс: 5 x Харизма', baseFormula: '5*C'),
  Skill(id: 'barter', name: 'Бартер', description: 'Навык выгодной торговли и оценки стоимости товаров.\n\nБазовый шанс: 4 x Харизма', baseFormula: '4*C'),
  Skill(id: 'gambling', name: 'Азартные игры', description: 'Умение играть в азартные игры и подсчитывать шансы.\n\nБазовый шанс: 5 x Удача', baseFormula: '5*L'),
  Skill(id: 'outdoorsman', name: 'Скиталец', description: 'Знания о выживании в дикой природе: охота, поиск воды.\n\nБазовый шанс: 2 x (Выносливость + Интеллект)', baseFormula: '2*(E+I)'),
];

class TraitDef {
  final String id, name, description;
  const TraitDef(this.id, this.name, this.description);
}

const traitDefs = [
  TraitDef('fastMetabolism', 'Быстрый метаболизм', '+2 к скорости лечения; сопротивления ядам и радиации равны 0.'),
  TraitDef('bruiser', 'Громила', '+2 к Силе; −2 к Очкам действий (ОД).'),
  TraitDef('smallFrame', 'Хрупкое телосложение', '+1 к Ловкости; грузоподъёмность = 25 + (15 × Сила).'),
  TraitDef('oneHander', 'Однорукий', '+20% к точности одноручного оружия; −40% к точности двуручного.'),
  TraitDef('finesse', 'Точность', '+10% к шансу критического удара; +30% к получаемому урону.'),
  TraitDef('kamikaze', 'Камикадзе', '+5 к Очерёдности; Класс брони (КБ) всегда равен 0.'),
  TraitDef('heavyHanded', 'Тяжёлая рука', '+4 к урону в ближнем бою; −30 к таблице критических ударов.'),
  TraitDef('fastShot', 'Быстрый стрелок', '−1 ОД на любую атаку; невозможно использовать прицельный выстрел.'),
  TraitDef('bloodyMess', 'Кровавая баня', 'Все смерти врагов максимально кровавые и зрелищные.'),
  TraitDef('jinxed', 'Неудачник', 'Промахи (ваши и врагов) с большей вероятностью становятся критическими провалами.'),
  TraitDef('goodNatured', 'Добродушный', '+15 к Первой помощи, Доктору, Красноречию и Бартеру; −10 ко всем боевым навыкам.'),
  TraitDef('chemReliant', 'Хим. зависимость', 'Зависимость от препаратов наступает чаще, но проходит значительно быстрее.'),
  TraitDef('chemResistant', 'Устойчивость к химии', 'Эффекты химии и риск развития зависимости снижены вдвое.'),
  TraitDef('sexAppeal', 'Сексуальность', 'Бонус к реакции противоположного пола; штраф к реакции на свой пол.'),
  TraitDef('skilled', 'Опытный', '+5 очков навыков за каждый уровень; новые перки доступны каждые 4 уровня.'),
  TraitDef('gifted', 'Одарённый', '+1 ко всем параметрам SPECIAL; −10 ко всем навыкам; −5 очков навыков за уровень.'),
];

class Item {
  String id, name, category, description;
  double weight; int price, count; bool equipable, equipped;
  Map<String, int> specialMods;
  Item({String? id, this.name = '', this.category = ItemCategory.junk, this.description = '', this.weight = 0, this.price = 0, this.count = 1, this.equipable = false, this.equipped = false, Map<String, int>? specialMods})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(), specialMods = specialMods ?? {};
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'category': category, 'description': description, 'weight': weight, 'price': price, 'count': count, 'equipable': equipable, 'equipped': equipped, 'mods': specialMods};
  factory Item.fromJson(Map<String, dynamic> j) => Item(
      id: j['id'], name: j['name'], category: j['category'] ?? ItemCategory.junk, description: j['description'] ?? '',
      weight: (j['weight'] ?? 0).toDouble(), price: j['price'] ?? 0, count: j['count'] ?? 1, equipable: j['equipable'] ?? false,
      equipped: j['equipped'] ?? false, specialMods: Map<String, int>.from(j['mods'] ?? {}));
}

class Quest {
  String id, title, description, status;
  Quest({String? id, this.title = '', this.description = '', this.status = 'active'}) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'description': description, 'status': status};
  factory Quest.fromJson(Map<String, dynamic> j) => Quest(id: j['id'], title: j['title'], description: j['description'], status: j['status'] ?? 'active');
}

class Character {
  String name; int level, hp, ap, xp, skillPoints; Map<String, int> special;
  Character({this.name = 'WANDERER', this.level = 1, this.hp = 35, this.ap = 8, this.xp = 0, this.skillPoints = 0, Map<String, int>? special})
      : special = special ?? {'S': 5, 'P': 5, 'E': 5, 'C': 5, 'I': 5, 'A': 5, 'L': 5};
  int get xpNext => level * 1000;
  Map<String, dynamic> toJson() => {'name': name, 'level': level, 'hp': hp, 'ap': ap, 'xp': xp, 'skillPoints': skillPoints, 'special': special};
  factory Character.fromJson(Map<String, dynamic> j) => Character(
      name: j['name'] ?? 'WANDERER', level: j['level'] ?? 1, hp: j['hp'] ?? 35, ap: j['ap'] ?? 8, xp: j['xp'] ?? 0, skillPoints: j['skillPoints'] ?? 0,
      special: Map<String, int>.from(j['special'] ?? {}));
}

class GameData {
  Character character;
  List<Skill> skills;
  List<Item> items;
  List<Quest> quests;
  Map<String, int> skillSpent;
  List<String> skillTags;
  List<String> traits;
  bool characterConfirmed;
  static const specialKeys = ['S', 'P', 'E', 'C', 'I', 'A', 'L'];

  GameData({Character? character, List<Skill>? skills, List<Item>? items, List<Quest>? quests, Map<String, int>? skillSpent, List<String>? skillTags, List<String>? traits, this.characterConfirmed = false})
      : character = character ?? Character(),
        skills = skills ?? getDefaultSkills(), // УНИФИКАЦИЯ: сразу загружаем стандартные навыки
        items = items ?? [], quests = quests ?? [], skillSpent = skillSpent ?? {}, skillTags = skillTags ?? [], traits = traits ?? [];

  bool hasTrait(String t) => traits.contains(t);
  List<Item> itemsByCategory(String c) => items.where((i) => i.category == c).toList();

  Map<String, int> get effectiveSpecial {
    final m = Map<String, int>.from(character.special);
    void apply(Map<String, int> mods) => mods.forEach((k, v) => m[k] = (m[k] ?? 5) + v);
    for (final it in items) { if (it.equipped) apply(it.specialMods); }
    if (hasTrait('gifted')) { for (final k in specialKeys) m[k] = (m[k] ?? 5) + 1; }
    if (hasTrait('smallFrame')) m['A'] = (m['A'] ?? 5) + 1;
    if (hasTrait('bruiser')) m['S'] = (m['S'] ?? 5) + 2;
    for (final s in skills) {
      final ctx = Map<String, int>.from(m)..['RANK'] = s.points..['LEVEL'] = character.level;
      s.specialMods.forEach((k, f) { m[k] = (m[k] ?? 5) + evalFormula(f, ctx); });
    }
    return m;
  }

  int _sp(String k) => effectiveSpecial[k] ?? 5;
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
  double get loadNow => items.fold(0.0, (sum, it) => sum + it.weight * it.count);

  void clamp() { character.hp = character.hp.clamp(0, maxHp); character.ap = character.ap.clamp(0, maxAp); }

  int traitSkillMod(String id) {
    var m = 0;
    if (hasTrait('gifted')) m -= 10;
    if (hasTrait('goodNatured')) {
      if (['firstAid', 'doctor', 'speech', 'barter'].contains(id)) m += 15;
      if (['smallGuns', 'bigGuns', 'energy', 'unarmed', 'melee', 'throwing'].contains(id)) m -= 10;
    }
    return m;
  }

  // УНИФИКАЦИЯ: расчёт для любого объекта Skill
  int skillValue(Skill skill) {
    int v = evalFormula(skill.baseFormula, effectiveSpecial);
    if (skillTags.contains(skill.id)) v += 20;
    v += skillSpent[skill.id] ?? 0;
    v += traitSkillMod(skill.id);
    return v.clamp(0, 300);
  }

  int nextCost(Skill skill) {
    final c = _skillCostOf(skillValue(skill));
    return skillTags.contains(skill.id) ? (c / 2).ceil() : c;
  }

  int _skillCostOf(int value) => value <= 100 ? 1 : value <= 125 ? 2 : value <= 150 ? 3 : value <= 175 ? 4 : value <= 200 ? 5 : 6;

  void replaceWith(GameData o) {
    character = o.character; skills = o.skills; items = o.items; quests = o.quests;
    skillSpent = o.skillSpent; skillTags = o.skillTags; traits = o.traits; characterConfirmed = o.characterConfirmed;
  }

  Map<String, dynamic> toJson() => {'character': character.toJson(), 'skills': skills.map((e) => e.toJson()).toList(),
      'items': items.map((e) => e.toJson()).toList(), 'quests': quests.map((e) => e.toJson()).toList(),
      'skillSpent': skillSpent, 'skillTags': skillTags, 'traits': traits, 'confirmed': characterConfirmed};
  String exportJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory GameData.fromJson(Map<String, dynamic> j) => GameData(
      character: Character.fromJson(Map<String, dynamic>.from(j['character'] ?? {})),
      skills: ((j['skills'] ?? []) as List).map((e) => Skill.fromJson(Map<String, dynamic>.from(e))).toList(),
      items: ((j['items'] ?? []) as List).map((e) => Item.fromJson(Map<String, dynamic>.from(e))).toList(),
      quests: ((j['quests'] ?? []) as List).map((e) => Quest.fromJson(Map<String, dynamic>.from(e))).toList(),
      skillSpent: Map<String, int>.from(j['skillSpent'] ?? {}), skillTags: List<String>.from(j['skillTags'] ?? []),
      traits: List<String>.from(j['traits'] ?? []), characterConfirmed: j['confirmed'] ?? false);
}
