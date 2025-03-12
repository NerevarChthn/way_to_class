// TransitionTemplate-Klasse ersetzen

import 'dart:developer' show log;

import 'package:way_to_class/constants/node_constants.dart';
import 'package:way_to_class/constants/template_constants.dart';

class TransitionTemplate {
  final int type; // Bitmaske für den Templatetyp
  final String template; // Der eigentliche Textinhalt mit Platzhaltern
  final List<String> requiredParams; // Liste der erforderlichen Parameter

  TransitionTemplate({
    required this.type,
    required this.template,
    this.requiredParams = const [],
  });

  /// Prüft, ob dieses Template für den angegebenen Kontext geeignet ist
  bool matchesContext(int context) =>
      (type & templateTypeMask) == (context & templateTypeMask);

  /// Prüft, ob dieses Template für den angegebenen Knotentyp geeignet ist
  bool matchesNodeType(int nodeType) {
    // Mapping zwischen Knotentyp und Templatetyp
    final int mappedType;
    switch (nodeType & typeMask) {
      case typeRoom:
        mappedType = templateForRoom;
        break;
      case typeCorridor:
        mappedType = templateForCorridor;
        break;
      case typeStaircase:
        mappedType = templateForStairs;
        break;
      case typeElevator:
        mappedType = templateForElevator;
        break;
      case typeDoor:
        mappedType = templateForDoor;
        break;
      case typeToilet:
        mappedType = templateForToilet;
        break;
      default:
        // Spezialbehandlung für Notausgänge
        if ((nodeType & propEmergency) != 0) {
          return (type & templateForDoor) !=
              0; // Notausgänge als Türen behandeln
        }
        return false;
    }

    return (type & mappedType) != 0;
  }

  /// Prüft, ob dieses Template die erforderlichen Eigenschaften hat
  bool hasRequiredProperties(int properties) =>
      (type & properties) == properties;

  // Verbessere die apply-Methode in der TransitionTemplate-Klasse:

  String apply(Map<String, dynamic> params) {
    // Prüfen, ob alle erforderlichen Parameter vorhanden sind
    final missingParams =
        requiredParams
            .where(
              (param) => !params.containsKey(param) || params[param] == null,
            )
            .toList();

    if (missingParams.isNotEmpty) {
      log(
        'WARNUNG: Fehlende Parameter für Template "$template": $missingParams',
      );
    }

    String result = template;

    // Parameter ersetzen
    params.forEach((k, v) {
      if (v != null) {
        // Sicherstellen, dass der Platzhalter wirklich im Text vorkommt
        final placeholder = '{$k}';
        if (result.contains(placeholder)) {
          result = result.replaceAll(placeholder, v.toString());
        } else if (requiredParams.contains(k)) {
          log(
            'WARNUNG: Platzhalter "$placeholder" fehlt im Template, aber Parameter ist vorhanden',
          );
        }
      }
    });

    // Überprüfen, ob noch Platzhalter im Text sind
    final remainingPlaceholders =
        RegExp(
          r'\{[^{}]*\}',
        ).allMatches(result).map((m) => m.group(0)).toList();
    if (remainingPlaceholders.isNotEmpty) {
      log('WARNUNG: Ungelöste Platzhalter im Text: $remainingPlaceholders');

      // Leere Platzhalter entfernen
      result = result.replaceAll(RegExp(r'\{[^{}]*\}'), '');
    }

    return result;
  }
}
