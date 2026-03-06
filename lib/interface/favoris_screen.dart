import 'package:flutter/material.dart';
import 'package:spiphoto_app/spi_colors.dart';

class FavorisScreen extends StatelessWidget {
  const FavorisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, color: SpiColors.mauve, size: 64),
          const SizedBox(height: 20),
          Text(
            'Mes Favoris',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Connectez-vous pour accéder\nà vos photos favorites',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // TODO : navigation vers LoginScreen
            },
            icon: const Icon(Icons.login),
            label: const Text('Se connecter avec Google'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SpiColors.mauve,
              foregroundColor: SpiColors.texte,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
