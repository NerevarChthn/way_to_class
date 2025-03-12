import 'package:way_to_class/constants/types.dart';
import 'package:way_to_class/core/models/node.dart';

/// Enthält die statischen Graphendaten und Hilfsmethoden für die Pathfinding-Funktionalität
class CampusGraph {
  /// Map von NodeId zu Node-Objekten - enthält alle Knoten des Campus
  final Map<NodeId, Node> _nodes;

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
  List<NodeId> getNeighbors(NodeId nodeId) {
    final node = getNodeById(nodeId);
    if (node == null) return [];
    return node.weights.keys.toList();
  }
}
