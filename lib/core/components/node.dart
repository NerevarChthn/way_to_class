import 'package:way_to_class/constants/node_constants.dart';

class Node {
  final String id;
  final String name;
  final int data;
  final int x;
  final int y;
  final Map<String, double> weights;

  Node({
    required this.id,
    required this.name,
    required this.data,
    required this.x,
    required this.y,
    required this.weights,
  });

  factory Node.fromJson(String id, Map<String, dynamic> json) {
    // Extrahiere die weights Map
    Map<String, double> weightsMap = {};
    if (json.containsKey('weights') && json['weights'] is Map) {
      final weightsJson = json['weights'] as Map<String, dynamic>;
      weightsMap = weightsJson.map(
        (key, value) => MapEntry(key, value is num ? value.toDouble() : 0.0),
      );
    }

    return Node(
      id: id, // ID kommt jetzt aus dem Map-Schlüssel
      name: json['name'] as String? ?? id,
      data: json['data'] as int,
      x: json['x'] as int? ?? 0,
      y: json['y'] as int? ?? 0,
      weights: weightsMap,
    );
  }

  // Gebäude- und Etageninformationen extrahieren
  int get buildingCode => data & buildingMask;
  int get floorCode => data & floorMask;

  String get buildingName {
    switch (buildingCode) {
      case buildingA:
        return 'Haus A';
      case buildingB:
        return 'Haus B';
      case buildingC:
        return 'Haus C';
      case buildingD:
        return 'Haus D';
      case buildingE:
        return 'Haus E';
      default:
        return 'Unbekannt';
    }
  }

  int get floorNumber => (floorCode >> floorShift) - 1;

  // Hilfsmethoden für Typ-Prüfungen
  bool isType(int baseType) => (data & typeMask) == baseType;
  bool hasProperty(int prop) => (data & prop) == prop;

  // In der Node-Klasse:
  bool get isRoom => isType(typeRoom);
  bool get isCorridor => isType(typeCorridor);
  bool get isStaircase => isType(typeStaircase);
  bool get isElevator => isType(typeElevator);
  bool get isDoor => isType(typeDoor);
  bool get isToilet => isType(typeToilet);
  bool get isMachine => isType(typeMachine);

  int get type => data & typeMask;

  bool get isEmergencyExit =>
      hasProperty(propEmergency) && hasProperty(propExit);
  bool get isAccessible => hasProperty(propAccessible);
  bool get isLocked => hasProperty(propLocked);
}
