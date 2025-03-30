import 'dart:developer' as dev;
import 'package:way_to_class/constants/types.dart';
import 'package:way_to_class/core/models/campus_graph.dart';

class PathGenerator {
  List<NodeId> calculatePath(
    Path path,
    CampusGraph graph, {
    bool visualize = false,
  }) {
    final startNode = graph.getNodeById(path.$1);
    final endNode = graph.getNodeById(path.$2);

    if (startNode == null || endNode == null) {
      throw Exception("Start- oder Zielknoten nicht gefunden.");
    }

    var forwardVisited = <NodeId, NodeId>{startNode.id: ''};
    var backwardVisited = <NodeId, NodeId>{endNode.id: ''};

    var forwardQueue = <NodeId>[startNode.id];
    var backwardQueue = <NodeId>[endNode.id];

    while (forwardQueue.isNotEmpty && backwardQueue.isNotEmpty) {
      if (visualize) dev.log('→ Vorwärtssuche: ${forwardQueue.join(", ")}');
      final forwardIntersection = _searchStep(
        forwardQueue,
        forwardVisited,
        backwardVisited,
        graph,
        visualize,
        true,
      );
      if (forwardIntersection != null) {
        return _buildPath(forwardVisited, backwardVisited, forwardIntersection);
      }

      if (visualize) dev.log('← Rückwärtssuche: ${backwardQueue.join(", ")}');
      final backwardIntersection = _searchStep(
        backwardQueue,
        backwardVisited,
        forwardVisited,
        graph,
        visualize,
        false,
      );
      if (backwardIntersection != null) {
        return _buildPath(
          forwardVisited,
          backwardVisited,
          backwardIntersection,
        );
      }
    }

    return [];
  }

  NodeId? _searchStep(
    List<NodeId> queue,
    Map<NodeId, NodeId> visited,
    Map<NodeId, NodeId> oppositeVisited,
    CampusGraph graph,
    bool visualize,
    bool isForward,
  ) {
    final current = queue.removeAt(0);
    final currentNode = graph.getNodeById(current);

    if (currentNode == null) return null;

    if (visualize) dev.log('${isForward ? "→" : "←"} Besuch: $current');

    for (var neighborId in currentNode.weights.keys) {
      final neighbor = graph.getNodeById(neighborId);
      if (neighbor == null ||
          neighbor.isLocked ||
          (neighbor.isElevator && hasStaircaseInBuilding(current, graph))) {
        if (visualize) {
          dev.log(
            '${isForward ? "→" : "←"} Ignoriere $neighborId (gesperrt, Treppe verfügbar)',
          );
        }
        continue;
      }

      if (!visited.containsKey(neighborId)) {
        visited[neighborId] = current;
        queue.add(neighborId);

        if (visualize) {
          dev.log(
            '${isForward ? "→" : "←"} Entdeckt: $neighborId durch $current',
          );
        }

        if (oppositeVisited.containsKey(neighborId)) {
          if (visualize) {
            dev.log(
              '${isForward ? "→" : "←"} Schnittpunkt gefunden: $neighborId',
            );
          }
          return neighborId;
        }
      } else if (visualize) {
        dev.log(
          '${isForward ? "→" : "←"} Übersprungen (bereits besucht): $neighborId',
        );
      }
    }
    return null;
  }

  List<NodeId> _buildPath(
    Map<NodeId, NodeId> forwardVisited,
    Map<NodeId, NodeId> backwardVisited,
    NodeId intersection,
  ) {
    var path = <NodeId>[];

    var current = intersection;
    while (current.isNotEmpty) {
      path.add(current);
      current = forwardVisited[current] ?? '';
    }
    path = path.reversed.toList();

    current = backwardVisited[intersection] ?? '';
    while (current.isNotEmpty) {
      path.add(current);
      current = backwardVisited[current] ?? '';
    }

    return path;
  }

  /// Prüft, ob im aktuellen Gebäude Treppen vorhanden sind
  bool hasStaircaseInBuilding(NodeId nodeId, CampusGraph currentGraph) {
    final targetNode = currentGraph.getNodeById(nodeId);
    if (targetNode == null) {
      throw Exception('Knoten nicht gefunden');
    }

    final buildingCode = targetNode.buildingCode;

    // Prüfe, ob es im gleichen Gebäude eine Treppe gibt
    return currentGraph.allNodes.any(
      (node) => node.buildingCode == buildingCode && node.isStaircase,
    );
  }
}
