import 'dart:math' show Random;

import 'package:way_to_class/constants/instruction_templates.dart';
import 'package:way_to_class/constants/metadata_keys.dart';
import 'package:way_to_class/core/models/route_segments.dart';

class InstructionGenerator {
  final Random _random = Random();
  String? _lastUsedMiddleConnector;
  final String _unknown = '{Unbekannt}';
  final String _middleConnectorPlaceholder = '{middleConnector}';
  final String _hallSynonymsPlaceholder = '{hallSynonym}';

  final List<String> _initialConnectors = ['zuerst', 'als Erstes', 'zunächst'];
  final List<String> _middleConnectors = [
    'dann',
    'danach',
    'anschließend',
    'im Anschluss',
    'schließlich',
    '', // nicht immer Konnektor
  ];
  final String _destRef = 'von dir';
  final List<String> _hallSynonyms = ['Flur', 'Gang', 'Korridor'];

  final Map<String, List<String>> _generatedValues = {};

  // Optimierte Hilfsmethoden

  final Map<int, List<String>> _distanceVariants = {
    0: ['ein paar Schritte', 'wenige Meter', 'ein kleines Stück'],
    10: ['etwa 10 Meter', 'ungefähr 10 Meter', 'ca. 10 Meter', 'einige Meter'],
    20: ['etwa 20 Meter', 'ungefähr 20 Meter', 'ca. 20 Meter', 'ein Weilchen'],
    50: [
      'etwa 50 Meter',
      'ungefähr 50 Meter',
      'ca. 50 Meter',
      'ein weites Stück',
      'eine Weile',
    ],
    100: ['etwa 100 Meter', 'ungefähr 100 Meter', 'ca. 100 Meter', 'sehr weit'],
  };

  String _getRandomDistance(int distance) {
    for (final threshold in _distanceVariants.keys.toList().reversed) {
      if (distance >= threshold) {
        return _distanceVariants[threshold]![_random.nextInt(
          _distanceVariants[threshold]!.length,
        )];
      }
    }
    return '$distance Meter';
  }

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
      _hallSynonymsPlaceholder: _getRandomHallSynonym(),
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
      _middleConnectorPlaceholder: _getRandomMiddleConnector(),
      _hallSynonymsPlaceholder:
          seg.metadata[MetadataKeys.outside] ?? _getRandomHallSynonym(),

      '{distance}': _getRandomDistance(
        (seg.metadata[MetadataKeys.distance] ?? 0),
      ),
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

  String _generateDestinationInstruction(RouteSegment seg) {
    final template = _getRandomTemplate(InstructionTemplates.destination);
    final replacements = <String, String>{
      '{currentName}': seg.metadata[MetadataKeys.currentName] ?? _unknown,
      '{side}': seg.metadata[MetadataKeys.side] ?? 'in unmittelbarer Nähe',
      '{ref}': _random.nextBool() ? _destRef : '',
    };
    return _replacePlaceholders(template, replacements);
  }

  String _generateStairsInstruction(RouteSegment seg) {
    // Get floor change and determine vertical direction with synonyms
    final int floorChange = seg.metadata[MetadataKeys.floorChange] ?? 0;
    final bool goingUp = floorChange > 0;

    // Randomly select up/down synonym
    final String vertical =
        goingUp
            ? _getUniqueRandomValue('upSynonym', [
              'nach oben',
              'hoch',
              'hinauf',
              'aufwärts',
            ])
            : _getUniqueRandomValue('downSynonym', [
              'nach unten',
              'runter',
              'hinab',
              'abwärts',
            ]);

    // Get absolute floor change and format with floor synonym
    final int absFloorChange = floorChange.abs();
    final String floorSynonym =
        absFloorChange > 1
            ? _getUniqueRandomValue('floorSynonym', [
              'Geschosse',
              'Etagen',
              'Stockwerke',
            ])
            : _getUniqueRandomValue('floorSynonym', [
              'Geschoss',
              'Etage',
              'Stockwerk',
            ]);

    // Check if direction exists and is not straight
    final String? direction = seg.metadata[MetadataKeys.direction];
    final bool hasDirectionChange =
        direction != null &&
        direction != MetadataKeys.straightDirection &&
        direction.isNotEmpty;

    final String template = _getRandomTemplate(InstructionTemplates.stairs);

    final replacements = <String, String>{
      '{middleConnector}': _getRandomMiddleConnector(),
      '{floors}': '$absFloorChange $floorSynonym',
      '{vertical}': vertical,
    };

    // Only add direction if needed
    if (hasDirectionChange) {
      return '${_replacePlaceholders(template, replacements)} und biege $direction ab';
    } else {
      return _replacePlaceholders(template, replacements);
    }
  }

  String _generateSegmentInstruction(RouteSegment seg) {
    switch (seg.type) {
      case SegmentType.origin:
        return _generateOriginInstruction(seg);
      case SegmentType.hallway:
        return _generateHallwayInstruction(seg);
      case SegmentType.destination:
        return _generateDestinationInstruction(seg);
      case SegmentType.stairs:
        return _generateStairsInstruction(seg);
      default:
        return 'Fehler: Segment konnte nicht identifiziert werden. Vorhandene Daten: ${seg.metadata.keys}';
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
    int nonSpaceLength =
        0; // Länge ohne Berücksichtigung von Leerzeichen am Ende

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
      nonSpaceLength =
          buffer
              .length; // Aktualisiere die Länge des Textes ohne Leerzeichen am Ende

      // Prüfe, ob der String bereits mit einem Satzzeichen endet
      if (i == length - 1 && (char == '.' || char == '!' || char == '?')) {
        needsPeriod = false;
      }
    }

    // Entferne Leerzeichen am Ende
    final String result = buffer.toString();
    final String trimmed = result.substring(0, nonSpaceLength);

    // Füge einen Punkt hinzu, falls nötig
    if (needsPeriod) {
      return '$trimmed.';
    }
    return trimmed;
  }
}
