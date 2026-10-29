import 'package:flutter/material.dart';
import 'package:spiphoto_app/spi_colors.dart';

/// Barre de navigation basse à trois onglets : Albums · Mes favoris · Club.
///
/// Widget dédié plutôt que BottomNavigationBar : la maquette impose un
/// padding (8 px haut / 10 px bas), un écart icône-libellé de 3 px et un
/// filet olive en haut que le widget Material ne permet pas de régler.
class SpiBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SpiBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // Icônes contour dans les deux états (Material Symbols Outlined) :
  // seules la couleur et la graisse du libellé distinguent l'onglet actif.
  static const List<(IconData, String)> _onglets = [
    (Icons.photo_library_outlined, 'Albums'),
    (Icons.favorite_border, 'Mes favoris'),
    (Icons.groups_outlined, 'Club'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.spi.surface,
      shape: Border(
        top: BorderSide(color: SpiColors.olive.withValues(alpha: 0.25)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (int i = 0; i < _onglets.length; i++)
              Expanded(
                child: _OngletNav(
                  icone: _onglets[i].$1,
                  libelle: _onglets[i].$2,
                  actif: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OngletNav extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final bool actif;
  final VoidCallback onTap;

  const _OngletNav({
    required this.icone,
    required this.libelle,
    required this.actif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color couleur =
        actif ? context.spi.mauve : context.spi.encreSecondaire;

    return Semantics(
      selected: actif,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, color: couleur, size: 24),
              const SizedBox(height: 3),
              Text(
                libelle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: couleur,
                  fontSize: 11,
                  fontWeight: actif ? FontWeight.w700 : FontWeight.w400,
                  letterSpacing: actif ? 0.5 : 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
