import 'dart:convert';

enum SegType {
  roomExit,
  machineExit,
  corridorStraight,
  corridorTurn,
  stairs,
  elevator,
  door,
  destination,
}

enum SegPosition { start, middle, end }

class RouteSegment {
  final SegType type;
  final SegPosition position;
  final Map<String, dynamic> data;

  RouteSegment(this.type, this.position, [this.data = const {}]);

  /// Konvertiert das Segment in eine JSON-Map
  Map<String, dynamic> _toJson() => {
    'type': type.index,
    'position': position.index,
    'data': data,
  };

  /// Erstellt ein Segment aus einer JSON-Map
  static RouteSegment _fromJson(Map<String, dynamic> json) => RouteSegment(
    SegType.values[json['type'] as int],
    SegPosition.values[json['position'] as int],
    Map<String, dynamic>.from(json['data'] as Map),
  );

  /// Konvertiert eine Liste von Segmenten in einen JSON-String
  static String encodeSegmentList(List<RouteSegment> segments) =>
      jsonEncode(segments.map((segment) => segment._toJson()).toList());

  /// Erstellt eine Liste von Segmenten aus einem JSON-String
  static List<RouteSegment> decodeSegmentList(String jsonString) =>
      (jsonDecode(jsonString) as List<Map<String, dynamic>>)
          .map((json) => RouteSegment._fromJson(json))
          .toList();
}
