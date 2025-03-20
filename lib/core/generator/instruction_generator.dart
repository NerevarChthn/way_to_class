import 'dart:math' show Random;

import 'package:way_to_class/constants/metadata_keys.dart';
import 'package:way_to_class/core/models/route_segments.dart';

class InstructionGenerator {
  final Random _random = Random();
  String?
  _lastUsedMiddleConnector; // Speichert den zuletzt verwendeten Connector

  final List<String> _initialConnectors = ["zuerst", "als Erstes", "zunächst"];
  final List<String> _middleConnectors = [
    "dann",
    "danach",
    "anschließend",
    "im Anschluss",
    "als Nächstes",
    "",
  ];
  final List<String> _finalConnectors = ["zuletzt"];
  final List<String> _distanceWeights = ["etwa", "ungefähr", "ca."];

  String getRandomInitialConnector() =>
      _initialConnectors[_random.nextInt(_initialConnectors.length)];

  String getRandomMiddleConnector() {
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

  String getRandomFinalConnector() =>
      _finalConnectors[_random.nextInt(_finalConnectors.length)];

  String getRandomDistanceWeight() =>
      _distanceWeights[_random.nextInt(_distanceWeights.length)];

  // Reset-Methode für neue Navigationspfade
  void reset() {
    _lastUsedMiddleConnector = null;
  }

  /// noch überlegen [TODO] vllt mit GPT deep reasoning segmentcode mit beispielen geben und ideen erfragen wie templates machen
  List<String> generateInstructions(List<RouteSegment> route) {
    reset();
    return route.map((e) => _generateSegmentInstruction(e)).toList();
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
        return "Folgen Sie dem Weg.";
    }
  }

  String _generateOriginInstruction(RouteSegment seg) {
    final List<String> templates = [
      "Starten Sie in {originName} ({building}, Etage {floor}) und verlassen Sie den Raum über {currentName}.",
      "Ihr Weg beginnt im {originName}. Folgen Sie {currentName} in den Flur ({building}, Etage {floor}).",
    ];
    String template = templates[_random.nextInt(templates.length)];
    template = template.replaceAll(
      "{originName}",
      seg.metadata["originName"] ?? "dem Raum",
    );
    template = template.replaceAll(
      "{currentName}",
      seg.metadata["currentName"] ?? "dem Flur",
    );
    template = template.replaceAll(
      "{building}",
      seg.metadata["building"] ?? "unbekanntem Gebäude",
    );
    template = template.replaceAll(
      "{floor}",
      seg.metadata["floor"]?.toString() ?? "?",
    );
    return template;
  }

  // Generiert eine Anweisung für einen Flurabschnitt
  String _generateHallwayInstruction(RouteSegment seg) {
    final synonyms = ["Flur", "Gang", "Korridor"];
    final templates = [
      "gehe ${getRandomDistanceWeight()} {distance} Meter den ${synonyms[_random.nextInt(synonyms.length)]} entlang",
      "folge dem ${synonyms[_random.nextInt(synonyms.length)]} für ${getRandomDistanceWeight()} {distance} Meter",
    ];
    String template =
        "${getRandomMiddleConnector()} ${templates[_random.nextInt(templates.length)]}"
            .replaceAll(
              "{currentName}",
              seg.metadata["currentName"] ?? "dem Flur",
            )
            .replaceAll(
              "{distance}",
              (seg.metadata[MetadataKeys.distance] ?? 0).toStringAsFixed(1),
            );

    if (seg.metadata[MetadataKeys.direction] != null) {
      template += ' und biege dann {direction} ab';
      template = template.replaceAll(
        "{direction}",
        seg.metadata[MetadataKeys.direction] ?? "unbekannter Richtung",
      );
    }
    return template.addPeriod().capitalize();
  }

  String _generateDoorInstruction(RouteSegment seg) {
    final templates = [
      "Passieren Sie die Tür {name}.",
      "Öffnen Sie {name} und setzen Sie Ihren Weg fort.",
    ];
    String template = templates[_random.nextInt(templates.length)];
    template = template.replaceAll("{name}", seg.metadata["name"] ?? "der Tür");
    return template;
  }

  String _generateDestinationInstruction(RouteSegment seg) {
    final templates = [
      "Ihr Ziel, {currentName}, befindet sich auf der {side} Seite.",
      "Am Ende erwartet Sie {currentName} – der Raum liegt auf der {side} Seite des Flurs.",
    ];
    String template = templates[_random.nextInt(templates.length)];
    template = template.replaceAll(
      "{currentName}",
      seg.metadata["currentName"] ?? "dem Raum",
    );
    template = template.replaceAll(
      "{side}",
      seg.metadata["side"] ?? "unbekannter",
    );
    return template;
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  String addPeriod() {
    if (isEmpty) return this;
    final trimmed = trim();
    if (trimmed.endsWith('.') ||
        trimmed.endsWith('!') ||
        trimmed.endsWith('?')) {
      return this;
    }
    return '$trimmed.';
  }
}
