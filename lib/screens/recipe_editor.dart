import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../utils/category_helper.dart';

class RecipeEditorScreen extends StatefulWidget {
  const RecipeEditorScreen({super.key, required this.state, this.recipe});
  final AppState state;
  final Recipe? recipe;

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _IngredientDraft {
  _IngredientDraft({
    String name = '',
    IngredientCategory category = IngredientCategory.dispensa,
    String qty = '',
    String unit = '',
    String note = '',
  })  : nameCtrl = TextEditingController(text: name),
        qtyCtrl = TextEditingController(text: qty),
        unitCtrl = TextEditingController(text: unit),
        noteCtrl = TextEditingController(text: note),
        category = category;

  final TextEditingController nameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitCtrl;
  final TextEditingController noteCtrl;
  IngredientCategory category;

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
    noteCtrl.dispose();
  }
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;
  late List<_IngredientDraft> _ingredients;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _noteCtrl = TextEditingController(text: r?.note ?? '');
    _ingredients = (r?.ingredients ?? const [])
        .map(
          (i) => _IngredientDraft(
            name: i.name,
            category: i.category,
            qty: i.quantity?.toString() ?? '',
            unit: i.unit ?? '',
            note: i.note ?? '',
          ),
        )
        .toList();
    if (_ingredients.isEmpty) _ingredients = [_IngredientDraft()];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    for (final d in _ingredients) {
      d.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.recipe != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifica ricetta' : 'Nuova ricetta'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save),
            tooltip: 'Salva',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Titolo',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Inserisci un titolo'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (opzionale)',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Ingredienti',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _ingredients.add(_IngredientDraft())),
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._ingredients
                .asMap()
                .entries
                .map((e) => _ingredientCard(e.key, e.value)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('Salva ricetta'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ingredientCard(int index, _IngredientDraft d) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: d.nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ingrediente',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final suggestedCat = suggestCategory(v);
                      if (suggestedCat != IngredientCategory.altro) {
                        setState(() => d.category = suggestedCat);
                      }
                      final suggestedUnit = suggestUnit(v);
                      if (suggestedUnit != null) {
                        setState(() => d.unitCtrl.text = suggestedUnit);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _ingredients.length <= 1
                      ? null
                      : () {
                          setState(() {
                            d.dispose();
                            _ingredients.removeAt(index);
                          });
                        },
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Rimuovi ingrediente',
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<IngredientCategory>(
              initialValue: d.category,
              decoration: const InputDecoration(
                labelText: 'Reparto',
                border: OutlineInputBorder(),
              ),
              items: IngredientCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(ingredientCategoryLabel(c)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => d.category = v!),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: d.qtyCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Quantità (opz.)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: d.unitCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Unità (opz.)',
                      hintText: 'g, kg, ml...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: d.noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note ingrediente (opz.)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final title = _titleCtrl.text.trim();
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    final ingredients = <Ingredient>[];
    for (final d in _ingredients) {
      final name = d.nameCtrl.text.trim();
      if (name.isEmpty) continue;
      final qtyRaw = d.qtyCtrl.text.trim().replaceAll(',', '.');
      final qty = double.tryParse(qtyRaw);
      final unit =
          d.unitCtrl.text.trim().isEmpty ? null : d.unitCtrl.text.trim();
      final inote =
          d.noteCtrl.text.trim().isEmpty ? null : d.noteCtrl.text.trim();
      ingredients.add(
        Ingredient(
          name: name,
          category: d.category,
          quantity: qty,
          unit: unit,
          note: inote,
        ),
      );
    }

    await widget.state.upsertRecipe(
      id: widget.recipe?.id,
      title: title,
      ingredients: ingredients,
      note: note,
    );

    if (mounted) Navigator.pop(context);
  }
}
