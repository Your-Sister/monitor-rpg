import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class Storage {
  static const _key = 'game_data_v1';

  static Future<GameData> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    if (s == null) return GameData();
    try {
      return GameData.fromJson(jsonDecode(s));
    } catch (_) {
      return GameData();
    }
  }

  static Future<void> save(GameData d) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(d.toJson()));
  }
}

