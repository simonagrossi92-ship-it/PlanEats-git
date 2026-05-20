import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/menu_screen.dart';
import 'screens/recipes_screen.dart';
import 'screens/shopping_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PlanEatsApp());
}

class PlanEatsApp extends StatefulWidget {
  const PlanEatsApp({super.key});

  @override
  State<PlanEatsApp> createState() => _PlanEatsAppState();
}

class _PlanEatsAppState extends State<PlanEatsApp> {
  final AppState _state = AppState();

  @override
  void initState() {
    super.initState();
    _state.init();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlanEats',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8BA888), // Verde Salvia
          primary: const Color(0xFF8BA888),
          surface: const Color(0xFFFDF5E6), // Old Lace (#FDF5E6)
        ),
        scaffoldBackgroundColor: const Color(0xFFFDF5E6), // Sfondo Old Lace
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFDF5E6),
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF8BA888).withValues(alpha: 0.2),
          height: 80, // Altezza fissa per la barra di navigazione
        ),
      ),
      home: AnimatedBuilder(
        animation: _state,
        builder: (context, _) {
          if (!_state.isReady) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return HomeShell(state: _state);
        },
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.state});
  final AppState state;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0; // default: Menù

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      MenuScreen(state: widget.state),
      ShoppingScreen(state: widget.state),
      RecipesScreen(state: widget.state),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('PlanEats'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color(0xFF8BA888),
              ),
              child: const Text(
                'PlanEats',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu_outlined),
              title: const Text('Menu settimanale'),
              onTap: () {
                setState(() => _index = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text('Spesa'),
              onTap: () {
                setState(() => _index = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Ricettario'),
              onTap: () {
                setState(() => _index = 2);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: pages[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: 0.1), // Ombra leggermente più marcata
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          elevation: 8, // Aggiunta elevazione alla NavigationBar stessa
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: 'Menù',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined),
              selectedIcon: Icon(Icons.shopping_cart),
              label: 'Spesa',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Ricettario',
            ),
          ],
        ),
      ),
    );
  }
}
