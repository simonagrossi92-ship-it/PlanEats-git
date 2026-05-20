import 'package:flutter/material.dart';

import '../app_state.dart';
import 'recipe_editor.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final recipes = state.data.recipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ricettario'),
      ),
      body: recipes.isEmpty
          ? const Center(
              child: Text('Nessuna ricetta. Premi + per aggiungerne una.'))
          : ListView.separated(
              itemCount: recipes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = recipes[i];
                return Dismissible(
                  key: ValueKey(r.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.delete,
                        color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Eliminare ricetta?'),
                            content: Text('Vuoi eliminare "${r.title}"?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Annulla')),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Elimina'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) => state.deleteRecipe(r.id),
                  child: ListTile(
                    title: Text(r.title),
                    subtitle: Text('${r.ingredients.length} ingredienti'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RecipeEditorScreen(state: state, recipe: r),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RecipeEditorScreen(state: state)),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
