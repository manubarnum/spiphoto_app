import 'package:flutter/material.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/service/auth_service.dart';

/// Écran affiché à la place d'un contenu réservé aux membres connectés
/// (Mes favoris, Le Club). En cas de succès, l'écran parent, qui écoute
/// AuthService.authStateChanges, bascule de lui-même sur le contenu.
class ConnexionRequise extends StatefulWidget {
  final IconData icone;
  final String titre;
  final String message;

  const ConnexionRequise({
    super.key,
    required this.icone,
    required this.titre,
    required this.message,
  });

  @override
  State<ConnexionRequise> createState() => _ConnexionRequiseState();
}

class _ConnexionRequiseState extends State<ConnexionRequise> {
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    final ScaffoldMessengerState messager = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    final String? erreur = await AuthService.instance.connecterAvecGoogle();
    if (erreur != null) {
      messager.showSnackBar(SnackBar(content: Text(erreur)));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icone, color: context.spi.mauve, size: 64),
          const SizedBox(height: 20),
          Text(
            widget.titre,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleSignIn,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: SpiColors.texte,
                    ),
                  )
                : const Icon(Icons.login),
            label:
                Text(_isLoading ? 'Connexion...' : 'Se connecter avec Google'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SpiColors.olive,
              foregroundColor: SpiColors.texte,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
