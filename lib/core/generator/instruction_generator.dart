import 'dart:math' show Random;

import 'package:way_to_class/core/models/route_segments.dart';

class InstructionGenerator {
  final Random _random = Random();

  final List<String> _initialConnectors = ["zuerst", "als Erstes", "zunächst"];
  final List<String> _middleConnectors = [
    "Dann",
    "Danach",
    "Anschließend",
    "Im Anschluss",
    "Als Nächstes",
  ];
  final List<String> _finalConnectors = ["Zuletzt"];

  String getRandomInitialConnector() =>
      _initialConnectors[_random.nextInt(_initialConnectors.length)];

  String getRandomMiddleConnector() =>
      _middleConnectors[_random.nextInt(_middleConnectors.length)];

  String getRandomFinalConnector() =>
      _finalConnectors[_random.nextInt(_finalConnectors.length)];

  /// noch überlegen [TODO] vllt mit GPT deep reasoning segmentcode mit beispielen geben und ideen erfragen wie templates machen
  List<String> generateInstructions(List<RouteSegment> route) =>
      route.map((e) => _generateSegmentInstruction(e)).toList();

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

  String _generateHallwayInstruction(RouteSegment seg) {
    final templates = [
      "Folgen Sie {currentName} für ca. {distance} Meter.",
      "Gehen Sie entlang des Flurs {currentName} – etwa {distance} Meter lang.",
    ];

    final templatesTurn = [
      "Folge {currentName} für ca. {distance} Meter und biege dann {direction} ab.",
      "Gehen Sie entlang des Flurs {currentName} – etwa {distance} Meter lang. An der nächsten Abzweigung {direction} abbiegen.",
    ];
    String template;
    if (seg.metadata["direction"] != null) {
      template = templatesTurn[_random.nextInt(templatesTurn.length)];
      template = template.replaceAll(
        "{direction}",
        seg.metadata["direction"] ?? "unbekannter Richtung",
      );
    } else {
      template = templates[_random.nextInt(templates.length)];
    }
    template = template.replaceAll(
      "{currentName}",
      seg.metadata["currentName"] ?? "dem Flur",
    );
    template = template.replaceAll(
      "{distance}",
      (seg.metadata["distance"] ?? 0).toStringAsFixed(1),
    );
    return template;
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
}
