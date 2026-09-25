import 'dart:convert';

// Карта русских сокращений для SPECIAL
const Map<String, String> specialRu = {
  'S': 'Сил',
  'P': 'Вос',
  'E': 'Вын',
  'C': 'Хар',
  'I': 'Инт',
  'A': 'Лов',
  'L': 'Уда',
};

String modsToString(Map<String, int> mods) => mods.entries
    .map((e) => '${e.value > 0 ? '+' : ''}${e.value} ${e.key}')
    .join('  ');

String modsToStringF(Map<String, String> mods) =>
    mods.entries.map((e) => '${e.key}:${e.value}').join('  ');

// ==================== ВЫЧИСЛЕНИЕ ФОРМУЛ ====================
int evalFormula(String src, Map<String, int> vars) {
  final s = src.replaceAll(' ', '').toUpperCase();
  var i = 0;

  late num Function() expr;
  late num Function() term;
  late num Function() factor;

  expr = () {
    num v = term();
    while (i < s.length && (s[i] == '+' || s[i] == '-')) {
      final op = s[i++];
      final r = term();
      v = op == '+' ? v + r : v - r;
    }
    return v;
  };

  term = () {
    num v = factor();
    while (i < s.length && (s[i] == '*' || s[i] == '/')) {
      final op = s[i++];
      final r = factor();
      v = op == '*' ? v * r : (r == 0 ? 0 : v / r);
    }
    return v;
  };

  factor = () {
    if (i < s.length && s[i] == '-') {
      i++;
      return -factor();
    }
    if (i < s.length && s[i] == '(') {
      i++;
      final v = expr();
      if (i < s.length && s[i] == ')') i++;
      return v;
    }
    final n0 = i;
    while (i < s.length && RegExp(r'[0-9.]').hasMatch(s[i])) i++;
    if (i > n0) return num.tryParse(s.substring(n0, i)) ?? 0;
    final a0 = i;
    while (i < s.length && RegExp(r'[A-Z]').hasMatch(s[i])) i++;
    if (i > a0) return vars[s.substring(a0, i)] ?? 0;
    return 0;
  };

  try {
    return expr().round();
  } catch (_) {
    return 0;
  }
}

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
  final String id, name, description, formula;
  final int Function(Map<String, int>) base;
  SkillDef(this.id, this.name, this.description, this.formula, this.base);
}

final skillDefs = <SkillDef>[
  SkillDef('smallGuns', 'Лёгкое оружие', 'Навыки обращения, ухода и общие знания о лёгком огнестрельном оружии: пистолетах, ПП и винтовках.\n\nБазовый шанс: 5% + (4 x Ловкость)', '5+4*A', (s) => 5 + 4 * (s['A'] ?? 5)),
  SkillDef('bigGuns', 'Тяжёлое оружие', 'Умение обращаться с тяжёлым вооружением: пулемётами, гранатомётами и огнемётами. Требует высокой Силы.\n\nБазовый шанс: 2 x Ловкость', '2*A', (s) => 2 * (s['A'] ?? 5)),
  SkillDef('energy', 'Энергетическое оружие', 'Знание принципов работы и обслуживания энергетического оружия: лазерных и плазменных винтовок.\n\nБазовый шанс: 2 x Ловкость', '2*A', (s) => 2 * (s['A'] ?? 5)),
  SkillDef('unarmed', 'Без оружия', 'Навык рукопашного боя: удары кулаками, ногами и использование кастетов или когтей.\n\nБазовый шанс: 30% + (2 x (Ловкость + Сила))', '30+2*(A+S)', (s) => 30 + 2 * ((s['A'] ?? 5) + (s['S'] ?? 5))),
  SkillDef('melee', 'Холодное оружие', 'Умение сражаться холодным оружием: ножами, дубинками, мечами и топорами.\n\nБазовый шанс: 20% + (2 x (Ловкость + Сила))', '20+2*(A+S)', (s) => 20 + 2 * ((s['A'] ?? 5) + (s['S'] ?? 5))),
  SkillDef('throwing', 'Метание', 'Точность и техника метания ножей, гранат, копий и других метаемых предметов.\n\nБазовый шанс: 4 x Ловкость', '4*A', (s) => 4 * (s['A'] ?? 5)),
  SkillDef('firstAid', 'Первая помощь', 'Базовые медицинские знания для стабилизации раненых, лечения простых ран и снятия легких эффектов.\n\nБазовый шанс: 2 x (Восприятие + Интеллект)', '2*(P+I)', (s) => 2 * ((s['P'] ?? 5) + (s['I'] ?? 5))),
  SkillDef('doctor', 'Доктор', 'Продвинутая медицина: лечение болезней, удаление яда, сложных переломов и имплантация.\n\nБазовый шанс: 5% + Восприятие + Интеллект', '5+P+I', (s) => 5 + (s['P'] ?? 5) + (s['I'] ?? 5)),
  SkillDef('sneak', 'Скрытность', 'Умение двигаться бесшумно, прятаться в тенях и оставаться незамеченным для врагов.\n\nБазовый шанс: 5% + (3 x Ловкость)', '5+3*A', (s) => 5 + 3 * (s['A'] ?? 5)),
  SkillDef('lockpick', 'Взлом', 'Навык вскрытия замков, электронных терминалов и обхода механических систем безопасности.\n\nБазовый шанс: 10% + Восприятие + Ловкость', '10+P+A', (s) => 10 + (s['P'] ?? 5) + (s['A'] ?? 5)),
  SkillDef('steal', 'Кража', 'Умение незаметно вытаскивать предметы из карманов NPC или закрытых контейнеров.\n\nБазовый шанс: 3 x Ловкость', '3*A', (s) => 3 * (s['A'] ?? 5)),
  SkillDef('traps', 'Ловушки', 'Знание принципов установки, обнаружения и безопасного обезвреживания ловушек и мин.\n\nБазовый шанс: 10% + Восприятие + Ловкость', '10+P+A', (s) => 10 + (s['P'] ?? 5) + (s['A'] ?? 5)),
  SkillDef('science', 'Наука', 'Энциклопедические знания в области компьютеров, биологии, физики и довоенных технологий.\n\nБазовый шанс: 4 x Интеллект', '4*I', (s) => 4 * (s['I'] ?? 5)),
  SkillDef('repair', 'Ремонт', 'Умение чинить и обслуживать технику, оружие, броню и роботов из подручных средств.\n\nБазовый шанс: 3 x Интеллект', '3*I', (s) => 3 * (s['I'] ?? 5)),
  SkillDef('speech', 'Красноречие', 'Искусство убеждения, ведения переговоров, запугивания и манипуляции собеседником.\n\nБазовый шанс: 5 x Харизма', '5*C', (s) => 5 * (s['C'] ?? 5)),
  SkillDef('barter', 'Бартер', 'Навык выгодной торговли, оценки стоимости товаров и умения сбивать цену у торговцев.\n\nБазовый шанс: 4 x Харизма', '4*C', (s) => 4 * (s['C'] ?? 5)),
  SkillDef('gambling', 'Азартные игры', 'Умение играть в азартные игры (блэкджек, рулетка), подсчитывать карты и шансы на победу.\n\nБазовый шанс: 5 x Удача', '5*L', (s) => 5 * (s['L'] ?? 5)),
  SkillDef('outdoorsman', 'Скиталец', 'Знания о выживании в дикой природе: охота, поиск воды, ориентирование и распознавание следов.\n\nБазовый шанс: 2 x (Выносливость + Интеллект)', '2*(E+I)', (s) => 2 * ((s['E'] ?? 5) + (s['I'] ?? 5))),
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

// ==================== МОДЕЛИ ====================
class Skill {
  String id, name, description;
  int points; // ранги
  Map<String, String> specialMods; // attr -> формула
  Skill({String? id, this.name = '', this.description = '', this.points = 1,
      Map<String, String>? specialMods})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        specialMods = specialMods ?? {};
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'description': description, 'points': points, 'mods': specialMods};
  factory Skill.fromJson(Map<String, dynamic> j) => Skill(
      id: j['id'], name: j['name'], description: j['description'],
      points: j['points'] ?? 1,
      specialMods: Map<String, dynamic>.from(j['mods'] ?? {})
          .map((k, v) => MapEntry(k, '$v')));
}

class Item {
  String id, name, category, description;
  double weight;
  int price, count;
  bool equipable, equipped;
  Map<String, int> specialMods;
  Item({String? id, this.name = '', this.category = ItemCategory.junk,
      this.description = '', this.weight = 0, this.price = 0, this.count = 1,
      this.equipable = false, this.equipped = false, Map<String, int>? specialMods})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        specialMods = specialMods ?? {};
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'category': category,
      'description': description, 'weight': weight, 'price': price, 'count': count,
      'equipable': equipable, 'equipped': equipped, 'mods': specialMods};
  factory Item.fromJson(Map<String, dynamic> j) => Item(
      id: j['id'], name: j['name'], category: j['category'] ?? ItemCategory.junk,
      description: j['description'] ?? '', weight: (j['weight'] ?? 0).toDouble(),
      price: j['price'] ?? 0, count: j['count'] ?? 1,
      equipable: j['equipable'] ?? false, equipped: j['equipped'] ?? false,
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
  Map<String, int> skillSpent;
  List<String> skillTags;
  List<String> traits;
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

  Map<String, int> get effectiveSpecial {
    final m = Map<String, int>.from(character.special);
    void apply(Map<String, int> mods) =>
        mods.forEach((k, v) => m[k] = (m[k] ?? 5) + v);
    for (final it in items) { if (it.equipped) apply(it.specialMods); }
    if (hasTrait('gifted')) { for (final k in specialKeys) m[k] = (m[k] ?? 5) + 1; }
    if (hasTrait('smallFrame')) m['A'] = (m['A'] ?? 5) + 1;
    if (hasTrait('bruiser')) m['S'] = (m['S'] ?? 5) + 2;
    for (final s in skills) {
      final ctx = Map<String, int>.from(m)
        ..['RANK'] = s.points
        ..['LEVEL'] = character.level;
      s.specialMods.forEach((k, f) {
        m[k] = (m[k] ?? 5) + evalFormula(f, ctx);
      });
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

  void clamp() {
    character.hp = character.hp.clamp(0, maxHp);
    character.ap = character.ap.clamp(0, maxAp);
  }

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

  void replaceWith(GameData o) {
    character = o.character;
    skills = o.skills;
    items = o.items;
    quests = o.quests;
    skillSpent = o.skillSpent;
    skillTags = o.skillTags;
    traits = o.traits;
    characterConfirmed = o.characterConfirmed;
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

  String exportJson() => const JsonEncoder.withIndent('  ').convert(toJson());

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
