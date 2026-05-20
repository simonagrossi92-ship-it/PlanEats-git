import 'dart:convert';

enum IngredientCategory {
  ortofrutta,
  carne,
  pesce,
  latticini,
  panetteria,
  surgelati,
  dispensa,
  bevande,
  altro,
}

String ingredientCategoryLabel(IngredientCategory c) {
  switch (c) {
    case IngredientCategory.ortofrutta:
      return 'Ortofrutta';
    case IngredientCategory.carne:
      return 'Carne';
    case IngredientCategory.pesce:
      return 'Pesce';
    case IngredientCategory.latticini:
      return 'Latticini';
    case IngredientCategory.panetteria:
      return 'Panetteria';
    case IngredientCategory.surgelati:
      return 'Surgelati';
    case IngredientCategory.dispensa:
      return 'Dispensa';
    case IngredientCategory.bevande:
      return 'Bevande';
    case IngredientCategory.altro:
      return 'Altro';
  }
}

IngredientCategory ingredientCategoryFromString(String? s) {
  if (s == null) return IngredientCategory.altro;
  return IngredientCategory.values.firstWhere(
    (e) => e.name == s,
    orElse: () => IngredientCategory.altro,
  );
}

class Ingredient {
  Ingredient({
    required this.name,
    required this.category,
    this.quantity,
    this.unit,
    this.note,
  });

  final String name;
  final IngredientCategory category;
  final double? quantity;
  final String? unit;
  final String? note;

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category.name,
        'quantity': quantity,
        'unit': unit,
        'note': note,
      };

  static Ingredient fromJson(Map<String, dynamic> json) => Ingredient(
        name: (json['name'] as String?) ?? '',
        category: ingredientCategoryFromString(json['category'] as String?),
        quantity: (json['quantity'] is num) ? (json['quantity'] as num).toDouble() : null,
        unit: json['unit'] as String?,
        note: json['note'] as String?,
      );
}

class Recipe {
  Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    this.note,
  });

  final String id;
  final String title;
  final List<Ingredient> ingredients;
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'note': note,
      };

  static Recipe fromJson(Map<String, dynamic> json) => Recipe(
        id: (json['id'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        ingredients: ((json['ingredients'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Ingredient.fromJson(e.cast<String, dynamic>()))
            .toList(),
        note: json['note'] as String?,
      );
}

enum MealType { colazione, pranzo, cena, snack }

String mealTypeLabel(MealType t) {
  switch (t) {
    case MealType.colazione:
      return 'Colazione';
    case MealType.pranzo:
      return 'Pranzo';
    case MealType.cena:
      return 'Cena';
    case MealType.snack:
      return 'Extra / Snack';
  }
}

class MealEntry {
  MealEntry({this.recipeId, this.customTitle});

  final String? recipeId;
  final String? customTitle;

  bool get isEmpty => (recipeId == null || recipeId!.isEmpty) && (customTitle == null || customTitle!.trim().isEmpty);

  String displayTitle({Recipe? recipe}) {
    if (recipeId != null && recipe != null) return recipe.title;
    if (customTitle != null && customTitle!.trim().isNotEmpty) return customTitle!.trim();
    return '';
  }

  Map<String, dynamic> toJson() => {
        'recipeId': recipeId,
        'customTitle': customTitle,
      };

  static MealEntry fromJson(Map<String, dynamic> json) => MealEntry(
        recipeId: json['recipeId'] as String?,
        customTitle: json['customTitle'] as String?,
      );
}

class PlanEatsData {
  PlanEatsData({
    required this.recipes,
    required this.weekPlans,
    required this.shoppingChecks,
    this.extraShoppingItems = const {},
  });

  final List<Recipe> recipes;

  /// weekPlans: { "YYYY-MM-DD" : { "colazione": {..}, "pranzo": {..}, ... } }
  final Map<String, Map<String, MealEntry>> weekPlans;

  /// shoppingChecks: { "YYYY-MM-DD" (lunedì) : { "itemKey": true/false } }
  final Map<String, Map<String, bool>> shoppingChecks;

  /// extraShoppingItems: { "YYYY-MM-DD" (lunedì) : [Ingredient, Ingredient, ...] }
  final Map<String, List<Ingredient>> extraShoppingItems;

  factory PlanEatsData.empty() => PlanEatsData(
        recipes: <Recipe>[],
        weekPlans: <String, Map<String, MealEntry>>{},
        shoppingChecks: <String, Map<String, bool>>{},
        extraShoppingItems: <String, List<Ingredient>>{},
      );

  Map<String, dynamic> toJson() => {
        'recipes': recipes.map((e) => e.toJson()).toList(),
        'weekPlans': weekPlans.map(
          (day, meals) => MapEntry(day, meals.map((k, v) => MapEntry(k, v.toJson()))),
        ),
        'shoppingChecks': shoppingChecks.map((week, checks) => MapEntry(week, checks)),
        'extraShoppingItems': extraShoppingItems.map(
          (week, items) => MapEntry(week, items.map((e) => e.toJson()).toList()),
        ),
      };

  static PlanEatsData fromJson(Map<String, dynamic> json) {
    final recipes = ((json['recipes'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Recipe.fromJson(e.cast<String, dynamic>()))
        .toList();

    final weekPlansRaw = (json['weekPlans'] as Map?) ?? {};
    final weekPlans = <String, Map<String, MealEntry>>{};
    for (final entry in weekPlansRaw.entries) {
      final day = entry.key.toString();
      final mealsRaw = entry.value;
      if (mealsRaw is Map) {
        weekPlans[day] = mealsRaw.map((k, v) => MapEntry(k.toString(), MealEntry.fromJson((v as Map).cast<String, dynamic>())));
      }
    }

    final shoppingChecksRaw = (json['shoppingChecks'] as Map?) ?? {};
    final shoppingChecks = <String, Map<String, bool>>{};
    for (final entry in shoppingChecksRaw.entries) {
      final week = entry.key.toString();
      final checksRaw = entry.value;
      if (checksRaw is Map) {
        shoppingChecks[week] = checksRaw.map((k, v) => MapEntry(k.toString(), v == true));
      }
    }

    final extraShoppingItemsRaw = (json['extraShoppingItems'] as Map?) ?? {};
    final extraShoppingItems = <String, List<Ingredient>>{};
    for (final entry in extraShoppingItemsRaw.entries) {
      final week = entry.key.toString();
      final itemsRaw = entry.value;
      if (itemsRaw is List) {
        extraShoppingItems[week] = itemsRaw
            .whereType<Map>()
            .map((e) => Ingredient.fromJson(e.cast<String, dynamic>()))
            .toList();
      }
    }

    return PlanEatsData(
      recipes: recipes,
      weekPlans: weekPlans,
      shoppingChecks: shoppingChecks,
      extraShoppingItems: extraShoppingItems,
    );
  }

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

