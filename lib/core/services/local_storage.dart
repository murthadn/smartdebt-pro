
import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static late Box _box;
  static Future<void> init() async {
    _box = await Hive.openBox('smartdebt_cache');
  }
  static Future<void> set(String key, dynamic value) async => await _box.put(key, value);
  static T? get<T>(String key) => _box.get(key) as T?;
  static Future<void> delete(String key) async => await _box.delete(key);
  static Future<void> clear() async => await _box.clear();
}
