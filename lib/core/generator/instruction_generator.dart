import 'dart:math' show Random;

import 'package:way_to_class/constants/instruction_templates.dart';
import 'package:way_to_class/constants/metadata_keys.dart';
import 'package:way_to_class/core/models/route_segments.dart';

class InstructionGenerator {
  final Random _random = Random();
  String? _lastUsedMiddleConnector;
  final String _unknown = '{Unbekannt}';
  final String _middleConnectorPlaceholder = '{middleConnector}';
  final String _distanceWeightsPlaceholder = '{distanceWeight}';
  final String _hallSynonymsPlaceholder = '{hallSynonym}';

  final List<String> _initialConnectors = ["zuerst", "als Erstes", "zunächst"];
  final List<String> _middleConnectors = [
    "dann",
    "danach",
    "anschließend",
    "im Anschluss",
    "schließlich",
    "", // nicht immer Konnektor
  ];
  final List<String> _finalConnectors = [
    "zuletzt",
    "als letztes",
    "zum Schluss",
  ];
  final List<String> _distanceWeights = ["etwa", "ungefähr", "ca."];
  final List<String> _hallSynonyms = ["Flur", "Gang", "Korridor"];

  final Map<String, List<String>> _generatedValues = {};

  // Optimierte Hilfsmethoden

  String _getUniqueRandomValue(String category, List<String> options) {
    if (!_generatedValues.containsKey(category)) {
      _generatedValues[category] = [];
    }

    final used = _generatedValues[category]!;

    // Wenn alle Optionen bereits verwendet wurden, Cache leeren
    if (used.length >= options.length - 1) {
      used.clear();
    }

    // Finde eine Option, die noch nicht verwendet wurde
    String value;
    do {
      value = options[_random.nextInt(options.length)];
    } while (used.contains(value));

    used.add(value);
    return value;
  }

  String _getRandomInitialConnector() =>
      _initialConnectors[_random.nextInt(_initialConnectors.length)];

  String _getRandomMiddleConnector() {
    // Wenn wir nur einen Connector haben, haben wir keine Wahl
    if (_middleConnectors.length <= 1) {
      return _middleConnectors.first;
    }

    // Erstelle eine Kopie der Liste ohne den zuletzt verwendeten Connector
    List<String> availableConnectors = List.from(_middleConnectors);
    if (_lastUsedMiddleConnector != null) {
      availableConnectors.remove(_lastUsedMiddleConnector);
    }

    // Wähle zufällig aus den verbleibenden Connectoren
    final connector =
        availableConnectors[_random.nextInt(availableConnectors.length)];

    // Speichere den aktuell verwendeten Connector für die nächste Anfrage
    _lastUsedMiddleConnector = connector;

    return connector;
  }

  String _getRandomFinalConnector() =>
      _finalConnectors[_random.nextInt(_finalConnectors.length)];

  String _getRandomDistanceWeight() =>
      _distanceWeights[_random.nextInt(_distanceWeights.length)];

  String _getRandomHallSynonym() =>
      _hallSynonyms[_random.nextInt(_hallSynonyms.length)];

  // Neue Hilfsmethoden für optimierte String-Operationen

  /// Wählt zufällig ein Template aus einem Set
  String _getRandomTemplate(Set<String> templates) {
    final templateList = templates.toList();
    return templateList[_random.nextInt(templateList.length)];
  }

  /// Optimierte Platzhalterersetzung mit StringBuffer
  String _replacePlaceholders(String text, Map<String, String> replacements) {
    if (!text.contains('{')) return text; // Schneller Pfad ohne Platzhalter

    final buffer = StringBuffer();
    int lastPosition = 0;

    // Einmal regulären Ausdruck kompilieren
    final regex = RegExp(r'\{([^{}]+)\}');

    // Für alle Matches im Text
    for (final match in regex.allMatches(text)) {
      // Füge Text bis zum Platzhalter hinzu
      buffer.write(text.substring(lastPosition, match.start));

      // Finde den Platzhalter
      final placeholder = match.group(0)!;

      // Füge den Ersatzwert oder den ursprünglichen Platzhalter hinzu
      if (replacements.containsKey(placeholder)) {
        buffer.write(replacements[placeholder]);
      } else {
        // Versuche, Standard-Platzhalter zu verarbeiten
        if (placeholder == _middleConnectorPlaceholder) {
          buffer.write(_getRandomMiddleConnector());
        } else if (placeholder == _distanceWeightsPlaceholder) {
          buffer.write(_getRandomDistanceWeight());
        } else if (placeholder == _hallSynonymsPlaceholder) {
          buffer.write(_getRandomHallSynonym());
        } else {
          // Unbekannter Platzhalter - unverändert lassen
          buffer.write(placeholder);
        }
      }

      // Aktualisiere Position
      lastPosition = match.end;
    }

    // Rest des Textes hinzufügen
    buffer.write(text.substring(lastPosition));
    return buffer.toString();
  }

  /// Generiert eine Anweisung für einen Ursprungsabschnitt (optimiert)
  String _generateOriginInstruction(RouteSegment seg) {
    // Prüfe auf Richtungsangabe
    final hasDirection =
        seg.metadata.containsKey(MetadataKeys.direction) &&
        seg.metadata[MetadataKeys.direction] != MetadataKeys.straightDirection;

    // Wähle passendes Template-Set
    final templates =
        hasDirection
            ? InstructionTemplates.originWithDirection
            : InstructionTemplates.origin;

    // Template zufällig auswählen
    final template = _getRandomTemplate(templates);

    // Platzhalter-Map erstellen
    final replacements = <String, String>{
      '{initialConnector}': _getRandomInitialConnector(),
      '{originName}': seg.metadata[MetadataKeys.originName] ?? _unknown,
      '{hallSynonym}': _getRandomHallSynonym(),
    };

    // Richtungsangabe hinzufügen, falls vorhanden
    if (hasDirection) {
      replacements['{direction}'] =
          seg.metadata[MetadataKeys.direction] ?? _unknown;
    }

    // Platzhalter ersetzen
    return _replacePlaceholders(template, replacements);
  }

  /// Generiert eine Anweisung für einen Flurabschnitt (optimiert)
  String _generateHallwayInstruction(RouteSegment seg) {
    // Prüfe auf Abbiegung
    final hasTurn =
        seg.metadata.containsKey(MetadataKeys.direction) &&
        seg.metadata[MetadataKeys.direction] != MetadataKeys.straightDirection;

    // Platzhalter-Map erstellen
    final replacements = <String, String>{
      '{middleConnector}': _getRandomMiddleConnector(),
      '{distanceWeight}': _getRandomDistanceWeight(),
      '{hallSynonym}': _getRandomHallSynonym(),
      '{distance}': (seg.metadata[MetadataKeys.distance] ?? 0).toString(),
    };

    // Wähle Basistemplate für geraden Flur
    String instruction = _replacePlaceholders(
      _getRandomTemplate(InstructionTemplates.hallway),
      replacements,
    );

    // Für Abbiegungen
    if (hasTurn) {
      // Landmark-Informationen vorbereiten
      final String landmark = seg.metadata[MetadataKeys.landmark] ?? _unknown;
      String formattedLandmark = landmark;

      if (landmark.toLowerCase().contains('treppe')) {
        formattedLandmark = 'der $landmark';
      } else if (landmark.toLowerCase().contains('aufzug')) {
        formattedLandmark = 'dem $landmark';
      }

      // Turn-Template-Ersetzungen
      final turnReplacements = <String, String>{
        '{landmarkConnector}': _getUniqueRandomValue('landmarkConnector', [
          'auf Höhe von',
          'bei',
        ]),
        '{landmark}': formattedLandmark,
        '{direction}': seg.metadata[MetadataKeys.direction] ?? _unknown,
      };

      // Abbiegungsanweisung hinzufügen
      instruction +=
          ' und ${_replacePlaceholders(_getRandomTemplate(InstructionTemplates.hallwayWithTurn), turnReplacements)}';
    }

    return instruction;
  }

  String _generateDoorInstruction(RouteSegment seg) {
    // Implementierung folgt ähnlichem Muster
    return "Unimplemented, available data: ${seg.metadata.keys}";
  }

  String _generateDestinationInstruction(RouteSegment seg) {
    // Implementierung folgt ähnlichem Muster
    return "Unimplemented, available data: ${seg.metadata.keys}";
  }

  String _generateSegmentInstruction(RouteSegment seg) {
    switch (seg.type) {
      case SegmentType.origin:
        return _generateOriginInstruction(seg);
      case SegmentType.hallway:
        return _generateHallwayInstruction(seg);
      case SegmentType.door:
        return _generateDoorInstruction(seg);
      case SegmentType.destination:
        return _generateDestinationInstruction(seg);
      default:
        return "{Segment noch unbekannt}";
    }
  }

  // Reset-Methode für neue Navigationspfade
  void reset() {
    _lastUsedMiddleConnector = null;
    _generatedValues.clear();
  }

  List<String> generateInstructions(List<RouteSegment> route) {
    reset();
    return List.generate(
      route.length,
      (index) =>
          _generateSegmentInstruction(route[index]).optimizeInstruction(),
    );
  }
}

extension StringExtension on String {
  /// Optimiert einen Anweisungstext durch Formatierung in einem Durchgang:
  /// - Entfernt doppelte Leerzeichen
  /// - Kapitalisiert den ersten Buchstaben
  /// - Fügt einen Schlusspunkt hinzu, falls nicht vorhanden
  String optimizeInstruction() {
    if (isEmpty) return this;

    // StringBuffer für effiziente Manipulation
    final buffer = StringBuffer();
    bool lastWasSpace =
        true; // Startet true, um führende Leerzeichen zu entfernen
    bool needsPeriod = true;

    // Durchlaufe den String einmal und führe alle Optimierungen durch
    for (int i = 0; i < length; i++) {
      final char = this[i];

      // Verarbeite Leerzeichen: überspringe, wenn das vorherige Zeichen auch ein Leerzeichen war
      if (char == ' ') {
        if (!lastWasSpace) {
          buffer.write(' ');
          lastWasSpace = true;
        }
        continue;
      }

      // Kapitalisiere den ersten Nicht-Leerzeichen-Buchstaben
      if (buffer.isEmpty && lastWasSpace) {
        buffer.write(char.toUpperCase());
      } else {
        buffer.write(char);
      }

      lastWasSpace = false;

      // Prüfe, ob der String bereits mit einem Satzzeichen endet
      if (i == length - 1 && (char == '.' || char == '!' || char == '?')) {
        needsPeriod = false;
      }
    }

    // Füge einen Punkt hinzu, falls nötig
    if (needsPeriod && buffer.isNotEmpty) {
      buffer.write('.');
    }

    return buffer.toString();
  }
}
