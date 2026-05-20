import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';
import 'storage/local_store.dart';
import 'utils/dates.dart';

class AppState extends ChangeNotifier {
  final LocalStore _store = LocalStore();
  final Uuid _uuid = const Uuid();

  bool _ready = false;
  bool get isReady => _ready;

  PlanEatsData _data = PlanEatsData.empty();
  PlanEatsData get data => _data;

  Future<void> init() async {
    _data = await _store.load();
    _ready = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _store.save(_data);
  }

  // --- Ricette ---
  Recipe? recipeById(String id) {
    for (final r in _data.recipes) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<void> upsertRecipe({
    String? id,
    required String title,
    required List<Ingredient> ingredients,
    String? note,
  }) async {
    final rid = (id == null || id.isEmpty) ? _uuid.v4() : id;
    final recipe =
        Recipe(id: rid, title: title, ingredients: ingredients, note: note);
    final idx = _data.recipes.indexWhere((r) => r.id == rid);
    if (idx >= 0) {
      _data.recipes[idx] = recipe;
    } else {
      _data.recipes.add(recipe);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> deleteRecipe(String id) async {
    _data.recipes.removeWhere((r) => r.id == id);
    // Rimuove eventuali riferimenti nel piano pasti
    _data.weekPlans.forEach((day, meals) {
      for (final entry in meals.entries) {
        final m = entry.value;
        if (m.recipeId == id) {
          meals[entry.key] = MealEntry(customTitle: m.customTitle);
        }
      }
    });
    await _persist();
    notifyListeners();
  }

  // --- Piano pasti (per giorno) ---
  Map<String, MealEntry> mealsForDay(DateTime day) {
    final key = isoDate(day);
    return _data.weekPlans[key] ?? <String, MealEntry>{};
  }

  MealEntry? mealEntry(DateTime day, MealType type) {
    final meals = mealsForDay(day);
    return meals[type.name];
  }

  Future<void> setMealEntry(
      DateTime day, MealType type, MealEntry? entry) async {
    final dayKey = isoDate(day);
    final meals = Map<String, MealEntry>.from(
        _data.weekPlans[dayKey] ?? <String, MealEntry>{});
    if (entry == null || entry.isEmpty) {
      meals.remove(type.name);
    } else {
      meals[type.name] = entry;
    }
    if (meals.isEmpty) {
      _data.weekPlans.remove(dayKey);
    } else {
      _data.weekPlans[dayKey] = meals;
    }
    await _persist();
    notifyListeners();
  }

  // --- Spesa / Checkbox ---
  String _weekKey(DateTime anyDayInWeek) =>
      isoDate(weekStartMonday(anyDayInWeek));

  bool isShoppingChecked(
      {required DateTime anyDayInWeek, required String itemKey}) {
    final wk = _weekKey(anyDayInWeek);
    return _data.shoppingChecks[wk]?[itemKey] == true;
  }

  Future<void> setShoppingChecked({
    required DateTime anyDayInWeek,
    required String itemKey,
    required bool checked,
  }) async {
    final wk = _weekKey(anyDayInWeek);
    final current =
        Map<String, bool>.from(_data.shoppingChecks[wk] ?? <String, bool>{});
    current[itemKey] = checked;
    _data.shoppingChecks[wk] = current;
    await _persist();
    notifyListeners();
  }

  Future<void> resetShoppingChecks(DateTime anyDayInWeek) async {
    final wk = _weekKey(anyDayInWeek);
    _data.shoppingChecks.remove(wk);
    _data.extraShoppingItems
        .remove(wk); // Rimuove anche gli extra quando si resetta
    await _persist();
    notifyListeners();
  }

  Future<void> addExtraShoppingItem(
      DateTime anyDayInWeek, Ingredient item) async {
    final wk = _weekKey(anyDayInWeek);
    final current =
        List<Ingredient>.from(_data.extraShoppingItems[wk] ?? <Ingredient>[]);
    current.add(item);
    _data.extraShoppingItems[wk] = current;
    await _persist();
    notifyListeners();
  }

  Future<void> removeExtraShoppingItem(DateTime anyDayInWeek, int index) async {
    final wk = _weekKey(anyDayInWeek);
    final current =
        List<Ingredient>.from(_data.extraShoppingItems[wk] ?? <Ingredient>[]);
    if (index >= 0 && index < current.length) {
      current.removeAt(index);
      _data.extraShoppingItems[wk] = current;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> updateExtraShoppingItem(
      DateTime anyDayInWeek, int index, Ingredient newItem) async {
    final wk = _weekKey(anyDayInWeek);
    final current =
        List<Ingredient>.from(_data.extraShoppingItems[wk] ?? <Ingredient>[]);
    if (index >= 0 && index < current.length) {
      current[index] = newItem;
      _data.extraShoppingItems[wk] = current;
      await _persist();
      notifyListeners();
    }
  }
}
