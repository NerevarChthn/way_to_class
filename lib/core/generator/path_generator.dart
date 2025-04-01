import 'dart:developer' as dev;
import 'package:way_to_class/constants/types.dart';
import 'package:way_to_class/core/models/campus_graph.dart';

class PathGenerator {
  /// Berechnet den kürzesten Weg zwischen zwei Knoten mittels bidirektionaler Breitensuche.
  ///
  /// Diese Methode implementiert eine bidirektionale Breitensuche, die gleichzeitig vom
  /// Start- und Zielknoten aus sucht, um den kürzesten Weg zwischen ihnen zu finden.
  ///
  /// Parameter:
  /// - [path]: Ein Tupel aus Start- und ZielknotenID
  /// - [graph]: Der Campus-Graph, der die Knoten und ihre Verbindungen enthält
  /// - [visualize]: Wenn true, werden Debug-Logs für die Visualisierung ausgegeben
  ///
  /// Returns:
  /// Eine Liste von KnotenIDs, die den kürzesten Weg vom Start zum Ziel darstellen.
  /// Leere Liste, wenn kein Pfad gefunden wurde.
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

    // Initialisiere Besuchsverzeichnisse für beide Suchrichtungen
    // Die Werte speichern jeweils den Vorgängerknoten
    var forwardVisited = <NodeId, NodeId>{startNode.id: ''};
    var backwardVisited = <NodeId, NodeId>{endNode.id: ''};

    // Initialisiere die Suchschlangen für beide Richtungen
    var forwardQueue = <NodeId>[startNode.id];
    var backwardQueue = <NodeId>[endNode.id];

    // Führe bidirektionale Suche durch, bis eine Richtung keine Knoten mehr zu besuchen hat
    while (forwardQueue.isNotEmpty && backwardQueue.isNotEmpty) {
      // Führe einen Suchschritt in Vorwärtsrichtung durch
      final String? forwardIntersection = _searchStep(
        forwardQueue,
        forwardVisited,
        backwardVisited,
        graph,
        visualize,
        true,
      );
      // Wenn ein Schnittpunkt gefunden wurde, baue den Pfad auf und gib ihn zurück
      if (forwardIntersection != null) {
        return _buildPath(forwardVisited, backwardVisited, forwardIntersection);
      }

      // Führe einen Suchschritt in Rückwärtsrichtung durch
      final String? backwardIntersection = _searchStep(
        backwardQueue,
        backwardVisited,
        forwardVisited,
        graph,
        visualize,
        false,
      );
      // Wenn ein Schnittpunkt gefunden wurde, baue den Pfad auf und gib ihn zurück
      if (backwardIntersection != null) {
        return _buildPath(
          forwardVisited,
          backwardVisited,
          backwardIntersection,
        );
      }
    }

    // Kein Pfad gefunden
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
