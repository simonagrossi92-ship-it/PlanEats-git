import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../utils/dates.dart';

Color getMealColor(BuildContext context, MealType type) {
  switch (type) {
    case MealType.colazione:
      return const Color(0xFFFFD54F); // Amber 300
    case MealType.pranzo:
      return const Color(0xFF81D4FA); // Light Blue 200
    case MealType.cena:
      return const Color(0xFF9FA8DA); // Indigo 200
    case MealType.snack:
      return Colors.black87; // Nero per pasti opzionali/snack
  }
}

Color getMealSurfaceColor(BuildContext context, MealType type) {
  switch (type) {
    case MealType.colazione:
    case MealType.pranzo:
    case MealType.cena:
      return Colors.white;
    case MealType.snack:
      return Colors.white; // Anche lo snack bianco come gli altri
  }
}

Color getMealOnColor(BuildContext context, MealType type) {
  switch (type) {
    case MealType.colazione:
      return const Color(0xFF5D4037); // Brown 800
    case MealType.pranzo:
      return const Color(0xFF01579B); // Light Blue 900
    case MealType.cena:
      return const Color(0xFF1A237E); // Indigo 900
    case MealType.snack:
      return Colors.white; // Testo bianco su sfondo nero per l'icona snack
  }
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.state});
  final AppState state;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late final List<DateTime> _days;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _days = weekDays(DateTime.now());
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Menù settimanale',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _days.map((d) => Tab(text: weekdayShortLabel(d))).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _days
            .map((d) => _DayMenuView(state: widget.state, day: d))
            .toList(),
      ),
    );
  }
}

class _DayMenuView extends StatelessWidget {
  const _DayMenuView({required this.state, required this.day});
  final AppState state;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final snack = state.mealEntry(day, MealType.snack);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _MealCard(
            state: state,
            day: day,
            type: MealType.colazione,
            icon: Icons.wb_sunny_outlined),
        _MealCard(
            state: state,
            day: day,
            type: MealType.pranzo,
            icon: Icons.restaurant_outlined),
        _MealCard(
            state: state,
            day: day,
            type: MealType.cena,
            icon: Icons.nightlight_outlined),
        if (snack != null && !snack.isEmpty)
          _MealCard(
              state: state,
              day: day,
              type: MealType.snack,
              icon: Icons.local_cafe_outlined)
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OutlinedButton.icon(
              onPressed: () => _openMealEditor(context,
                  state: state, day: day, type: MealType.snack),
              icon: const Icon(Icons.add, color: Colors.black87),
              label: const Text(
                'Aggiungi snack (opzionale)',
                style: TextStyle(color: Colors.black87),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black26),
              ),
            ),
          ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.state,
    required this.day,
    required this.type,
    required this.icon,
  });

  final AppState state;
  final DateTime day;
  final MealType type;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final entry = state.mealEntry(day, type);
    final recipe =
        (entry?.recipeId != null) ? state.recipeById(entry!.recipeId!) : null;
    final hasValue = entry != null && !entry.isEmpty;
    final title =
        hasValue ? entry.displayTitle(recipe: recipe) : 'Nessuna selezione';

    final surfaceColor = getMealSurfaceColor(context, type);
    final accentColor = getMealColor(context, type);
    final onAccentColor = getMealOnColor(context, type);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: surfaceColor,
      elevation: 4, // Aggiunta ombreggiatura
      shadowColor: Colors.black.withOpacity(0.2), // Colore ombra leggero
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), // Angoli più arrotondati
        side: BorderSide(
          color: hasValue
              ? accentColor.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            20, 20, 20, 20), // Padding interno maggiore
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center, // Centrato verticalmente
          children: [
            Container(
              width: 64, // Dimensione cerchio maggiore
              height: 64,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32, // Icona più grande
                color: onAccentColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mealTypeLabel(type),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: onAccentColor.withValues(alpha: 0.8),
                        ),
                  ),
                  const SizedBox(height: 10), // Aumentato spazio da 6 a 10
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: hasValue
                              ? Colors.black87
                              : Theme.of(context).colorScheme.outline,
                          fontWeight: hasValue ? FontWeight.w500 : null,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              onPressed: () =>
                  _openMealEditor(context, state: state, day: day, type: type),
              icon: Icon(hasValue ? Icons.edit_outlined : Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: accentColor.withValues(alpha: 0.3),
                foregroundColor: onAccentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openMealEditor(
  BuildContext context, {
  required AppState state,
  required DateTime day,
  required MealType type,
}) async {
  final recipes = state.data.recipes;
  final current = state.mealEntry(day, type);

  String mode = (current?.recipeId != null) ? 'recipe' : 'text';
  String? selectedRecipeId = current?.recipeId;
  String customText = current?.customTitle ?? '';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${mealTypeLabel(type)} • ${weekdayShortLabel(day)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: getMealOnColor(context, type),
                      ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: getMealColor(context, type),
                    selectedForegroundColor: getMealOnColor(context, type),
                  ),
                  segments: const [
                    ButtonSegment(value: 'recipe', label: Text('Ricetta')),
                    ButtonSegment(value: 'text', label: Text('Testo')),
                  ],
                  selected: {mode},
                  onSelectionChanged: (val) =>
                      setSheetState(() => mode = val.first),
                ),
                const SizedBox(height: 12),
                if (mode == 'recipe') ...[
                  if (recipes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                          'Nessuna ricetta. Aggiungine una nel Ricettario.'),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selectedRecipeId,
                      decoration: const InputDecoration(
                        labelText: 'Seleziona ricetta',
                        border: OutlineInputBorder(),
                      ),
                      items: recipes
                          .map((r) => DropdownMenuItem<String>(
                                value: r.id,
                                child: Text(r.title,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setSheetState(() => selectedRecipeId = v),
                    ),
                ] else ...[
                  TextFormField(
                    initialValue: customText,
                    decoration: const InputDecoration(
                      labelText: 'Inserisci pasto',
                      hintText: 'Es. Pasta al pesto',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => customText = v,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: (current == null || current.isEmpty)
                          ? null
                          : () async {
                              await state.setMealEntry(day, type, null);
                              if (context.mounted) Navigator.pop(context);
                            },
                      child: const Text('Rimuovi'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () async {
                        MealEntry? entry;
                        if (mode == 'recipe') {
                          if (selectedRecipeId == null ||
                              selectedRecipeId!.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Seleziona una ricetta.')),
                            );
                            return;
                          }
                          entry = MealEntry(recipeId: selectedRecipeId);
                        } else {
                          if (customText.trim().isEmpty) {
                            entry = null;
                          } else {
                            entry = MealEntry(customTitle: customText.trim());
                          }
                        }
                        await state.setMealEntry(day, type, entry);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Salva'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
