import 'package:flutter/material.dart';
import 'package:spiphoto_app/spi_colors.dart';

class ClubScreen extends StatelessWidget {
  const ClubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.groups_outlined, color: SpiColors.olive, size: 64),
          const SizedBox(height: 20),
          Text(
            'Le Club',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Le fil communautaire SPIPHOTO\narrive bientôt',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
