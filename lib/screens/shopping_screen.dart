import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../utils/dates.dart';
import '../utils/category_helper.dart';
import '../utils/price_helper.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key, required this.state});
  final AppState state;

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = weekDays(now);
    final start = days.first;
    final end = days.last;

    final items = _buildShoppingItems(state: widget.state, days: days);
    final grouped = <IngredientCategory, List<_ShoppingItem>>{};
    double totalEstimated = 0;
    double checkedTotal = 0;

    for (final it in items) {
      grouped.putIfAbsent(it.category, () => []).add(it);
      totalEstimated += it.estimatedPrice;
      if (widget.state.isShoppingChecked(anyDayInWeek: now, itemKey: it.key)) {
        checkedTotal += it.estimatedPrice;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Spesa • ${weekdayShortLabel(start)}-${weekdayShortLabel(end)}'),
        actions: [
          IconButton(
            tooltip: 'Aggiungi voce',
            onPressed: () => _showAddItemDialog(context, now),
            icon: const Icon(Icons.add_shopping_cart),
          ),
          IconButton(
            tooltip: 'Reset spunte',
            onPressed: () async {
              final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Reset spunte'),
                      content: const Text(
                          'Vuoi azzerare tutte le spunte e gli extra di questa settimana?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annulla')),
                        FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Reset')),
                      ],
                    ),
                  ) ??
                  false;
              if (!ok) return;
              await widget.state.resetShoppingChecks(now);
            },
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Lista vuota.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showAddItemDialog(context, now),
                    icon: const Icon(Icons.add),
                    label: const Text('Aggiungi spesa extra'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      ...IngredientCategory.values
                          .where(grouped.containsKey)
                          .map((cat) {
                        final catItems = grouped[cat]!
                          ..sort((a, b) => a.name.compareTo(b.name));
                        return _CategorySection(
                          state: widget.state,
                          weekRef: now,
                          category: cat,
                          items: catItems,
                          onEditExtra: (index, item) => _showAddItemDialog(
                              context, now,
                              editIndex: index, initialItem: item),
                        );
                      }),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'TOTALE STIMATO',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                          Text(
                            '€ ${totalEstimated.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8BA888)),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'GIÀ NEL CARRELLO',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                          Text(
                            '€ ${checkedTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showAddItemDialog(BuildContext context, DateTime weekRef,
      {int? editIndex, Ingredient? initialItem}) {
    String name = initialItem?.name ?? '';
    IngredientCategory category =
        initialItem?.category ?? IngredientCategory.altro;
    String? quantityStr = initialItem?.quantity?.toString();
    String? unit = initialItem?.unit;
    final TextEditingController unitCtrl = TextEditingController(text: unit);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title:
              Text(editIndex == null ? 'Aggiungi alla spesa' : 'Modifica voce'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration:
                      const InputDecoration(labelText: 'Nome ingrediente'),
                  onChanged: (v) {
                    name = v;
                    if (editIndex == null) {
                      final suggestedCat = suggestCategory(v);
                      if (suggestedCat != IngredientCategory.altro) {
                        setDialogState(() => category = suggestedCat);
                      }
                      final suggestedUnit = suggestUnit(v);
                      if (suggestedUnit != null) {
                        setDialogState(() {
                          unit = suggestedUnit;
                          unitCtrl.text = suggestedUnit;
                        });
                      }
                    }
                  },
                  autofocus: editIndex == null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<IngredientCategory>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Reparto'),
                  items: IngredientCategory.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(ingredientCategoryLabel(c))))
                      .toList(),
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: quantityStr,
                        decoration: const InputDecoration(labelText: 'Qtà'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => quantityStr = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(labelText: 'Unità'),
                        onChanged: (v) => unit = v,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  unitCtrl.dispose();
                  Navigator.pop(context);
                },
                child: const Text('Annulla')),
            FilledButton(
              onPressed: () {
                if (name.trim().isEmpty) return;
                final qty = double.tryParse(quantityStr ?? '');
                final newItem = Ingredient(
                  name: name.trim(),
                  category: category,
                  quantity: qty,
                  unit: unit?.trim(),
                );

                if (editIndex == null) {
                  widget.state.addExtraShoppingItem(weekRef, newItem);
                } else {
                  widget.state
                      .updateExtraShoppingItem(weekRef, editIndex, newItem);
                }
                unitCtrl.dispose();
                Navigator.pop(context);
              },
              child: Text(editIndex == null ? 'Aggiungi' : 'Salva'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.state,
    required this.weekRef,
    required this.category,
    required this.items,
    required this.onEditExtra,
  });

  final AppState state;
  final DateTime weekRef;
  final IngredientCategory category;
  final List<_ShoppingItem> items;
  final Function(int index, Ingredient item) onEditExtra;

  Color _getCategoryColor() {
    switch (category) {
      case IngredientCategory.ortofrutta:
        return Colors.green.shade100;
      case IngredientCategory.carne:
        return Colors.red.shade100;
      case IngredientCategory.pesce:
        return Colors.blue.shade100;
      case IngredientCategory.latticini:
        return Colors.orange.shade100;
      case IngredientCategory.panetteria:
        return Colors.brown.shade100;
      case IngredientCategory.surgelati:
        return Colors.cyan.shade100;
      case IngredientCategory.dispensa:
        return Colors.amber.shade100;
      case IngredientCategory.bevande:
        return Colors.purple.shade100;
      case IngredientCategory.altro:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getCategoryColor(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            ingredientCategoryLabel(category).toUpperCase(),
            style: const TextStyle(
                fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
        ),
        ...items.map((it) {
          final checked =
              state.isShoppingChecked(anyDayInWeek: weekRef, itemKey: it.key);
          final qtySubtitle =
              it.displayQuantity.isEmpty ? null : it.displayQuantity;
          final priceSubtitle = it.estimatedPrice > 0
              ? '€ ${it.estimatedPrice.toStringAsFixed(2)}'
              : null;

          return CheckboxListTile(
            value: checked,
            onChanged: (v) => state.setShoppingChecked(
                anyDayInWeek: weekRef, itemKey: it.key, checked: v ?? false),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        it.name,
                        style: TextStyle(
                          decoration:
                              checked ? TextDecoration.lineThrough : null,
                          color: checked ? Colors.grey : null,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (qtySubtitle != null)
                        Text(
                          qtySubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: checked ? Colors.grey : Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
                if (priceSubtitle != null)
                  Text(
                    priceSubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: checked ? Colors.grey : Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (it.extraIndices.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (val) {
                      if (val == 'edit') {
                        // Per semplicità editiamo il primo extra se ce ne sono più di uno con lo stesso nome
                        final idx = it.extraIndices.first;
                        final extras = state.data.extraShoppingItems[
                                isoDate(weekStartMonday(weekRef))] ??
                            [];
                        onEditExtra(idx, extras[idx]);
                      } else if (val == 'delete') {
                        for (final idx in it.extraIndices.reversed) {
                          state.removeExtraShoppingItem(weekRef, idx);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'edit', child: Text('Modifica')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Elimina')),
                    ],
                  ),
              ],
            ),
            controlAffinity: ListTileControlAffinity.leading,
          );
        }),
      ],
    );
  }
}

class _ShoppingItem {
  _ShoppingItem({
    required this.key,
    required this.name,
    required this.category,
    required this.displayQuantity,
    required this.estimatedPrice,
    required this.isPriceReliable,
    this.extraIndices = const [],
  });

  final String key;
  final String name;
  final IngredientCategory category;
  final String displayQuantity;
  final double estimatedPrice;
  final bool isPriceReliable;
  final List<int> extraIndices;
}

List<_ShoppingItem> _buildShoppingItems({
  required AppState state,
  required List<DateTime> days,
}) {
  final recipes = {for (final r in state.data.recipes) r.id: r};
  final agg = <String, _Agg>{};

  // 1. Dalle ricette del piano
  for (final day in days) {
    for (final t in MealType.values) {
      final entry = state.mealEntry(day, t);
      final rid = entry?.recipeId;
      if (rid == null || rid.isEmpty) continue;
      final recipe = recipes[rid];
      if (recipe == null) continue;

      for (final ing in recipe.ingredients) {
        _aggregate(agg, ing);
      }
    }
  }

  // 2. Dagli extra aggiunti manualmente per questa settimana
  final startOfWeek = weekStartMonday(days.first);
  final extras = state.data.extraShoppingItems[isoDate(startOfWeek)] ?? [];
  for (int i = 0; i < extras.length; i++) {
    _aggregate(agg, extras[i], extraIndex: i);
  }

  String fmtQty(double v) {
    if ((v - v.roundToDouble()).abs() < 0.00001) return v.toInt().toString();
    return v.toStringAsFixed(1).replaceAll('.0', '');
  }

  final out = <_ShoppingItem>[];
  for (final entry in agg.entries) {
    final a = entry.value;
    final unit = a.unit.isEmpty ? '' : a.unit;
    String q = '';
    if (a.hasQty) {
      q = '${fmtQty(a.totalQty)}${unit.isEmpty ? '' : ' $unit'}';
      if (a.missingQty) q = '$q (alcune senza quantità)';
    }

    // Calcolo stima prezzo
    final priceEst = estimatePrice(a.name, a.hasQty ? a.totalQty : 1.0, a.unit);

    out.add(_ShoppingItem(
      key: entry.key,
      name: a.name,
      category: a.category,
      displayQuantity: q,
      estimatedPrice: priceEst.amount,
      isPriceReliable: priceEst.isReliable,
      extraIndices: a.extraIndices,
    ));
  }
  return out;
}

void _aggregate(Map<String, _Agg> agg, Ingredient ing, {int? extraIndex}) {
  final name = ing.name.trim();
  if (name.isEmpty) return;
  final norm = name.toLowerCase();
  final unit = (ing.unit ?? '').trim().toLowerCase();
  final key = '${ing.category.name}|$norm|$unit';
  final a = agg.putIfAbsent(
    key,
    () => _Agg(name: name, category: ing.category, unit: unit),
  );
  if (ing.quantity != null) {
    a.hasQty = true;
    a.totalQty += ing.quantity!;
  } else {
    a.missingQty = true;
  }
  if (extraIndex != null) {
    a.extraIndices.add(extraIndex);
  }
}

class _Agg {
  _Agg({required this.name, required this.category, required this.unit});
  final String name;
  final IngredientCategory category;
  final String unit;
  double totalQty = 0;
  bool hasQty = false;
  bool missingQty = false;
  final List<int> extraIndices = [];
}
