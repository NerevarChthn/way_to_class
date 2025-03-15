import 'package:way_to_class/constants/types.dart';
import 'package:way_to_class/core/models/node.dart';

/// Enthält die statischen Graphendaten und Hilfsmethoden für die Pathfinding-Funktionalität
class CampusGraph {
  /// Map von NodeId zu Node-Objekten - enthält alle Knoten des Campus
  final Map<NodeId, Node> _nodes;

  /// Landmark Cache
  final Map<NodeId, String> _landmarkCache = {};

  /// Konstruktor erfordert eine vorbereitete Node-Map
  CampusGraph(this._nodes);

  /// Hilfsmethode zum Abrufen eines Knotens anhand seiner ID
  Node? getNodeById(NodeId id) => _nodes[id];

  /// Hilfsmethode zum Abrufen eines Knotens anhand seines Namens
  Node? getNodeByName(String name) {
    for (var node in _nodes.values) {
      if (node.name == name) {
        return node;
      }
    }

    return null;
  }

  /// Liefert die ID eines Knotens anhand seines Namens
  NodeId? getNodeIdByName(String name) {
    for (var entry in _nodes.values) {
      if (entry.name == name) {
        return entry.id;
      }
    }
    return null;
  }

  /// Liefert eine Liste aller Knoten-IDs
  List<NodeId> get allNodeIds => _nodes.keys.toList();

  /// Liefert eine Liste aller Raum-IDs (nützlich für die Suche)
  List<NodeId> get allRoomIds =>
      _nodes.entries
          .where((entry) => entry.value.isRoom)
          .map((entry) => entry.key)
          .toList();

  /// Prüft, ob eine Verbindung zwischen zwei Knoten existiert
  bool hasConnection(NodeId fromId, NodeId toId) {
    final fromNode = getNodeById(fromId);
    return fromNode?.weights.keys.any((id) => id == toId) ?? false;
  }

  /// Gibt alle direkt verbundenen Knoten-IDs zurück
  List<NodeId> _getNeighbors(NodeId nodeId) {
    final node = getNodeById(nodeId);
    if (node == null) return [];
    return node.weights.keys.toList();
  }

  /// Findet den nächstgelegenen nicht-Flurknoten von einem gegebenen Knoten aus
  /// Gibt null zurück, falls kein solcher Knoten gefunden werden kann
  String? findNearestNonHallwayNode(
    NodeId startId, {
    double maxDistance = 12.0,
  }) {
    // Cache Prüfung
    if (_landmarkCache.containsKey(startId)) return _landmarkCache[startId];

    // Prüfe, ob der Startknoten existiert
    final startNode = getNodeById(startId);
    if (startNode == null) return null;

    // Verwende Breadth-First-Search, um den nächstgelegenen Knoten zu finden
    final Set<NodeId> visited = {startId};
    // Queue mit Tupeln aus (nodeId, bisheriger Distanz)
    final List<(NodeId, double)> queue = [];

    // Füge die Nachbarn des Startknotens zur Queue hinzu
    for (var neighborId in _getNeighbors(startId)) {
      final weight = startNode.weights[neighborId] ?? 1.0;
      queue.add((neighborId, weight));
    }

    Node? nearest;
    double nearestDistance = double.infinity;

    while (queue.isNotEmpty) {
      final (NodeId nodeId, double distanceSoFar) = queue.removeAt(0); // FIFO

      // Überspringe, wenn bereits besucht oder die Distanz den Maximalwert überschreitet
      if (visited.contains(nodeId) || distanceSoFar > maxDistance) continue;
      visited.add(nodeId);

      // Prüfe, ob dieser Knoten ein gültiger Nicht-Flurknoten ist
      final node = getNodeById(nodeId);
      if (node == null) continue;

      // Wenn wir einen Raum, eine Treppe, einen Aufzug oder eine Toilette gefunden haben
      if (!node.isCorridor) {
        // Gefundener gültiger Knoten als potenziellen nächsten betrachten
        if (nearest == null || distanceSoFar < nearestDistance) {
          nearest = node;
          nearestDistance = distanceSoFar;
          // Wir suchen weiter, um den nächstgelegenen zu finden
        }
      }

      // Nachbarn zur Queue hinzufügen
      for (var neighborId in _getNeighbors(nodeId)) {
        if (!visited.contains(neighborId)) {
          final weight = node.weights[neighborId] ?? 1.0;
          queue.add((neighborId, distanceSoFar + weight));
        }
      }
    }

    // Cache aktualisieren
    if (nearest != null) {
      _landmarkCache[startId] = nearest.name;
    }

    return nearest?.name;
  }
}
