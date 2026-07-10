import 'package:flutter/material.dart';
import '../models/niveau.dart';

/// Couleur et icône associées, pour un repère visuel
/// cohérent partout où un niveau est affiché. Centralisé ici plutôt que dans le modèle
extension NiveauTypeStyle on NiveauType {
  Color get couleur {
    switch (this) {
      case NiveauType.debutant:
        return const Color(0xFF16A34A); // vert
      case NiveauType.intermediaire:
        return const Color(0xFFD97706); // orange
      case NiveauType.expert:
        return const Color(0xFFDC2626); // rouge
    }
  }

  IconData get icone {
    switch (this) {
      case NiveauType.debutant:
        return Icons.emoji_objects_outlined;
      case NiveauType.intermediaire:
        return Icons.trending_up_rounded;
      case NiveauType.expert:
        return Icons.local_fire_department_rounded;
    }
  }
}
