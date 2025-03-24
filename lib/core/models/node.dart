import 'package:way_to_class/constants/node_data.dart';
import 'package:way_to_class/constants/types.dart';

enum NodeType {
  room,
  corridor,
  staircase,
  elevator,
  door,
  entranceExit,
  emergencyExit,
  toilet,
  machine,
}

class Node {
  final NodeId id;
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

  int get floorNumber => (floorCode >> floorShift) - 2;

  // Hilfsmethoden für Typ-Prüfungen
  bool isType(int baseType) => (data & nodeMask) == baseType;
  bool hasProperty(int prop) => (data & prop) == prop;

  // In der Node-Klasse:
  bool get isRoom => isType(nodeRoom);
  bool get isCorridor => isType(nodeCorridor);
  bool get isStaircase => isType(nodeStaircase);
  bool get isElevator => isType(nodeElevator);
  bool get isDoor => isType(nodeDoor);
  bool get isToilet => isType(nodeToilet);
  bool get isMachine => isType(nodeMachine);

  int get type => data & nodeMask;

  bool get isEmergencyExit => hasProperty(propEmergencyExit);
  bool get isAccessible => hasProperty(propAccessible);
  bool get isLocked => hasProperty(propLocked);
}
