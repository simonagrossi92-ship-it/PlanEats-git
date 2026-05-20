import 'package:flutter/material.dart';
import 'package:planeats/app_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required AppState state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
      ),
      body: const Center(
        child: Text('Placeholder: preferenze (porzioni, allergie)'),
      ),
    );
  }
}
