import 'dart:math';
import 'dart:developer' as dev;
import 'package:way_to_class/constants/types.dart';
import 'package:way_to_class/core/models/campus_graph.dart';
import 'package:way_to_class/core/models/node.dart';

/// Generator für optimale Pfade zwischen zwei Knoten
class PathGenerator {
  /// Debug-Flag für detailliertes Logging
  bool enableLogging = false;

  /// A*-Algorithmus mit Visualisierung und Logging
  List<NodeId> findPathWithVisualization(
    Path path,
    CampusGraph graph, {
    bool visualize = true,
  }) {
    enableLogging = true;
    final result = calculatePath(path, graph);
    enableLogging = false;
    return result;
  }

  /// Algorithmus-Prozess als String-Darstellung
  String getAlgorithmVisualization(Path path, CampusGraph graph) {
    final NodeId startId = path.$1;
    final NodeId endId = path.$2;

    final Node? start = graph.getNodeById(startId);
    final Node? end = graph.getNodeById(endId);

    if (start == null || end == null) {
      return "Fehler: Start- oder Zielknoten nicht gefunden.";
    }

    final buffer = StringBuffer();
    buffer.writeln("=== A* ALGORITHMUS VISUALISIERUNG ===");
    buffer.writeln("Start: $startId (${start.x}, ${start.y})");
    buffer.writeln("Ziel:  $endId (${end.x}, ${end.y})");
    buffer.writeln("Euklidische Distanz: ${_euclideanDistance(start, end)}");
    buffer.writeln("======================================\n");

    // A*-Algorithmus mit Logging ausführen
    _visualizeAStarSearch(startId, endId, graph, buffer);

    return buffer.toString();
  }

  // A*-Algorithmus mit Logging für Visualisierung
  void _visualizeAStarSearch(
    NodeId startId,
    NodeId endId,
    CampusGraph graph,
    StringBuffer buffer,
  ) {
    // Heuristik
    double heuristic(NodeId fromId, NodeId toId) {
      final fromNode = graph.getNodeById(fromId);
      final toNode = graph.getNodeById(toId);

      if (fromNode == null || toNode == null) return 0;

      final dx = toNode.x - fromNode.x;
      final dy = toNode.y - fromNode.y;
      return sqrt(dx * dx + dy * dy);
    }

    // Priority Queue
    final openSet = _ManualPriorityQueue<_QueueItem>(
      (a, b) => a.fScore.compareTo(b.fScore),
    );
    openSet.add(_QueueItem(startId, 0, heuristic(startId, endId)));

    final Map<NodeId, double> gScore = {startId: 0};
    final Map<NodeId, NodeId> cameFrom = {};
    final Set<NodeId> closedSet = {};

    buffer.writeln("=== ALGORITHMUS START ===");
    int iteration = 0;

    while (!openSet.isEmpty) {
      iteration++;
      final current = openSet.removeFirst().nodeId;
      final currentNode = graph.getNodeById(current);

      buffer.writeln("\n--- Iteration $iteration ---");
      buffer.writeln(
        "Aktueller Knoten: $current${_formatNodeInfo(currentNode)}",
      );

      // Ziel erreicht
      if (current == endId) {
        buffer.writeln("ZIEL ERREICHT!");
        final path = _reconstructPath(cameFrom, endId);
        buffer.writeln("\n=== FINALER PFAD ===");
        _visualizePath(path, graph, buffer);
        buffer.writeln("Total Cost: ${_calculateActualPathCost(path, graph)}");
        return;
      }

      closedSet.add(current);
      buffer.writeln(
        "Besuchte Knoten: ${closedSet.length} (${_formatNodeSet(closedSet)})",
      );

      if (currentNode == null) {
        buffer.writeln("Fehler: Knoten nicht gefunden!");
        continue;
      }

      // Nachbarn
      buffer.writeln("Nachbarn prüfen:");
      for (final entry in currentNode.weights.entries) {
        final neighborId = entry.key;
        final weight = entry.value;
        final neighbor = graph.getNodeById(neighborId);

        // Skip-Bedingungen
        String skipReason = "";
        if (closedSet.contains(neighborId)) {
          skipReason = "bereits besucht";
        } else if (neighbor == null) {
          skipReason = "nicht gefunden";
        }

        if (skipReason.isNotEmpty) {
          buffer.writeln("  Nachbar $neighborId → übersprungen ($skipReason)");
          continue;
        }

        // Gewichtung
        double weightMultiplier = 1.0;
        String weightInfo = "";

        if (neighbor!.isStaircase) {
          weightMultiplier = 2.0;
          weightInfo = "Treppe (×2)";
        } else if (neighbor.isElevator) {
          weightMultiplier = 3.0;
          weightInfo = "Aufzug (×3)";
        }

        if (neighbor.isStaircase && !neighbor.isAccessible) {
          weightMultiplier = 10.0;
          weightInfo = "Nicht barrierefreie Treppe (×10)";
        }

        final double tentativeGScore =
            gScore[current]! + (weight * weightMultiplier);

        String evalInfo = "neu";
        if (gScore.containsKey(neighborId)) {
          if (tentativeGScore >= gScore[neighborId]!) {
            buffer.writeln(
              "  Nachbar $neighborId${_formatNodeInfo(neighbor)} → teurer Pfad (${tentativeGScore.toStringAsFixed(2)} vs. ${gScore[neighborId]!.toStringAsFixed(2)})",
            );
            continue;
          }
          evalInfo = "besser als vorheriger";
        }

        // Pfad aktualisieren
        cameFrom[neighborId] = current;
        gScore[neighborId] = tentativeGScore;
        final hValue = heuristic(neighborId, endId);
        final fScore = tentativeGScore + hValue;

        buffer.writeln(
          "  Nachbar $neighborId${_formatNodeInfo(neighbor)} → $evalInfo "
          "g=${tentativeGScore.toStringAsFixed(2)}, "
          "h=${hValue.toStringAsFixed(2)}, "
          "f=${fScore.toStringAsFixed(2)} $weightInfo",
        );

        // Zur Queue hinzufügen, falls noch nicht enthalten
        bool inOpenSet = openSet.items.any((item) => item.nodeId == neighborId);
        if (!inOpenSet) {
          openSet.add(_QueueItem(neighborId, tentativeGScore, fScore));
        }
      }

      buffer.writeln("\nNoch zu prüfende Knoten: ${openSet.items.length}");
      if (openSet.items.isNotEmpty) {
        buffer.writeln("Queue (Top-5, nach f-Score sortiert):");
        final topItems = openSet.items.take(5).toList();
        for (int i = 0; i < topItems.length; i++) {
          final item = topItems[i];
          final node = graph.getNodeById(item.nodeId);
          buffer.writeln(
            "  ${i + 1}. ${item.nodeId}${_formatNodeInfo(node)} - "
            "f=${item.fScore.toStringAsFixed(2)}, "
            "g=${item.gScore.toStringAsFixed(2)}, "
            "h=${(item.fScore - item.gScore).toStringAsFixed(2)}",
          );
        }
      }
    }

    buffer.writeln("\nKEIN PFAD GEFUNDEN!");
  }

  /// Visualisiert einen Pfad mit Knotendetails
  void _visualizePath(
    List<NodeId> path,
    CampusGraph graph,
    StringBuffer buffer,
  ) {
    buffer.writeln("Pfadlänge: ${path.length} Knoten\n");

    for (int i = 0; i < path.length; i++) {
      final nodeId = path[i];
      final node = graph.getNodeById(nodeId);

      buffer.write("${i + 1}. $nodeId${_formatNodeInfo(node)}");

      if (i < path.length - 1) {
        final nextNode = graph.getNodeById(path[i + 1]);
        if (node != null && nextNode != null) {
          final weight = node.weights[path[i + 1]] ?? 0;
          final dx = nextNode.x - node.x;
          final dy = nextNode.y - node.y;
          final distance = sqrt(dx * dx + dy * dy);

          buffer.write(
            " → Entfernung: ${distance.toStringAsFixed(2)}, Gewicht: $weight",
          );

          if (node.floorCode != nextNode.floorCode) {
            buffer.write(
              " (ETAGENWECHSEL von ${node.floorCode} nach ${nextNode.floorCode})",
            );
          }
        }
        buffer.writeln();
      } else {
        buffer.writeln(" (ZIEL)");
      }
    }
  }

  /// Berechnet die tatsächlichen Kosten eines Pfades
  double _calculateActualPathCost(List<NodeId> path, CampusGraph graph) {
    double cost = 0;

    for (int i = 0; i < path.length - 1; i++) {
      final current = graph.getNodeById(path[i]);
      if (current == null) continue;

      final weight = current.weights[path[i + 1]] ?? 0;
      cost += weight;
    }

    return cost;
  }

  /// Formatiert einen NodeSet für die Ausgabe
  String _formatNodeSet(Set<NodeId> nodeSet) {
    if (nodeSet.isEmpty) return "leer";
    if (nodeSet.length <= 3) return nodeSet.join(", ");
    return "${nodeSet.take(3).join(", ")}, ...+${nodeSet.length - 3}";
  }

  /// Formatiert Knoteninfo für die Ausgabe
  String _formatNodeInfo(Node? node) {
    if (node == null) return " [NICHT GEFUNDEN]";
    return " [${node.x},${node.y}, F${node.floorCode}, ${_getNodeTypeName(node)}]";
  }

  /// Gibt den Typ des Knotens als String zurück
  String _getNodeTypeName(Node node) {
    if (node.isRoom) return "Raum";
    if (node.isCorridor) return "Flur";
    if (node.isStaircase) return "Treppe";
    if (node.isElevator) return "Aufzug";
    if (node.isDoor) return "Tür";
    if (node.isEmergencyExit) return "Notausgang";
    if (node.isToilet) return "WC";
    return "Unbekannt";
  }

  /// Berechnet die euklidische Distanz zwischen zwei Knoten
  double _euclideanDistance(Node node1, Node node2) {
    final dx = node2.x - node1.x;
    final dy = node2.y - node1.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Berechnet den kürzesten Pfad zwischen Start und Ziel mit optionalem Logging
  List<NodeId> calculatePath(Path path, CampusGraph graph) {
    final NodeId startId = path.$1;
    final NodeId endId = path.$2;

    if (enableLogging) {
      dev.log("Starte Pfadberechnung von $startId nach $endId");
    }

    final Node? start = graph.getNodeById(startId);
    final Node? end = graph.getNodeById(endId);

    // Prüfe, ob Knoten existieren
    if (start == null || end == null) {
      if (enableLogging) {
        dev.log("Fehler: Start- oder Zielknoten nicht gefunden");
      }
      return [];
    }

    // Prüfe, ob Start und Ziel valide sind (keine Flure, Treppen, Aufzüge)
    if (!_isValidEndpoint(start) || !_isValidEndpoint(end)) {
      return [];
    }

    // Wenn Start und Ziel identisch sind
    if (startId == endId) {
      return [startId];
    }

    // Prüfe, ob Start und Ziel im gleichen Gebäude und auf der gleichen Etage sind
    if (start.buildingCode != end.buildingCode ||
        start.floorCode != end.floorCode) {
      // Komplexere Logik für gebäude- oder etagenübergreifende Pfade
      return _findCrossFloorPath(start, end, graph);
    }

    // A* Pfadsuche innerhalb einer Etage - direkt auf dem Graph arbeiten
    final result = _findPathAStar(startId, endId, graph);

    if (enableLogging) {
      if (result.isEmpty) {
        dev.log("Kein Pfad gefunden!");
      } else {
        dev.log("Pfad gefunden mit ${result.length} Knoten");
      }
    }

    return result;
  }

  /// Prüft, ob ein Knoten als Start- oder Zielpunkt gültig ist
  bool _isValidEndpoint(Node node) {
    // Kein Flur, keine Treppe, kein Aufzug
    return !(node.isCorridor || node.isStaircase || node.isElevator);
  }

  /// A*-Algorithmus mit zusätzlichem Logging
  List<NodeId> _findPathAStar(NodeId startId, NodeId endId, CampusGraph graph) {
    if (enableLogging) {
      dev.log("A*-Suche gestartet von $startId nach $endId");
    }

    // Heuristik-Funktion (Euklidische Distanz)
    double heuristic(NodeId fromId, NodeId toId) {
      final Node? fromNode = graph.getNodeById(fromId);
      final Node? toNode = graph.getNodeById(toId);

      if (fromNode == null || toNode == null) return 0;

      // Euklidische Distanz berechnen
      final dx = toNode.x - fromNode.x;
      final dy = toNode.y - fromNode.y;
      return sqrt(dx * dx + dy * dy);
    }

    // Manuelle Priority Queue
    final openSet = _ManualPriorityQueue<_QueueItem>(
      (a, b) => a.fScore.compareTo(b.fScore),
    );
    openSet.add(_QueueItem(startId, 0, heuristic(startId, endId)));

    // Tracking von bereits besuchten Knoten und Kosten
    final Map<NodeId, double> gScore = {startId: 0};
    final Map<NodeId, NodeId> cameFrom = {};
    final Set<NodeId> closedSet = {};

    while (!openSet.isEmpty) {
      final current = openSet.removeFirst().nodeId;

      // Ziel erreicht
      if (current == endId) {
        final result = _reconstructPath(cameFrom, endId);
        if (enableLogging) {
          dev.log("A*-Suche abgeschlossen, Pfadlänge: ${result.length}");
        }
        return result;
      }

      closedSet.add(current);

      // Nachbarn durchlaufen - direkt auf dem Graphen
      final Node? currentNode = graph.getNodeById(current);
      if (currentNode == null) continue;

      // Alle Kantengewichte durchgehen
      for (final entry in currentNode.weights.entries) {
        final neighborId = entry.key;
        final weight = entry.value;

        // Bereits besuchte Knoten überspringen
        if (closedSet.contains(neighborId)) continue;

        // Nachbar abrufen
        final Node? neighbor = graph.getNodeById(neighborId);
        if (neighbor == null) continue;

        // Berechneter Aufschlag für verschiedene Knotentypen
        double weightMultiplier = 1.0;

        // Kantengewicht basierend auf Knotentyp anpassen
        if (neighbor.isStaircase) {
          weightMultiplier = 2.0; // Treppen sind teurer
        } else if (neighbor.isElevator) {
          weightMultiplier = 3.0; // Aufzüge sind noch teurer
        }

        // Barrierefreiheit berücksichtigen
        if (neighbor.isStaircase && !neighbor.isAccessible) {
          weightMultiplier = 10.0; // Nicht barrierefreie Treppen stark meiden
        }

        // Neue Kosten zum Nachbarn
        final double tentativeGScore =
            gScore[current]! + (weight * weightMultiplier);

        // Wenn dieser Weg teurer ist, überspringen
        if (gScore.containsKey(neighborId) &&
            tentativeGScore >= gScore[neighborId]!) {
          continue;
        }

        // Dieser Weg ist besser, aktualisieren
        cameFrom[neighborId] = current;
        gScore[neighborId] = tentativeGScore;
        final double fScore = tentativeGScore + heuristic(neighborId, endId);

        // Zur offenen Menge hinzufügen, falls noch nicht enthalten
        bool inOpenSet = false;
        for (final item in openSet.items) {
          if (item.nodeId == neighborId) {
            inOpenSet = true;
            break;
          }
        }

        if (!inOpenSet) {
          openSet.add(_QueueItem(neighborId, tentativeGScore, fScore));
        }
      }
    }

    // Kein Pfad gefunden
    return [];
  }

  /// Rekonstruiert den Pfad aus der Vorgänger-Map
  List<NodeId> _reconstructPath(Map<NodeId, NodeId> cameFrom, NodeId current) {
    final path = <NodeId>[current];

    while (cameFrom.containsKey(current)) {
      current = cameFrom[current]!;
      path.insert(0, current);
    }

    return path;
  }

  /// Findet einen Pfad zwischen Knoten auf verschiedenen Etagen oder in verschiedenen Gebäuden
  List<NodeId> _findCrossFloorPath(Node start, Node end, CampusGraph graph) {
    // Aufzüge und Treppen für Start- und Zieletage finden
    final List<Node> startFloorTransitions = _findTransitionNodes(
      graph,
      start.buildingCode,
      start.floorCode,
    );
    final List<Node> endFloorTransitions = _findTransitionNodes(
      graph,
      end.buildingCode,
      end.floorCode,
    );

    if (startFloorTransitions.isEmpty || endFloorTransitions.isEmpty) {
      return []; // Keine Übergangspunkte gefunden
    }

    // Alle möglichen Kombinationen durchprobieren
    double bestPathCost = double.infinity;
    List<NodeId> bestPath = [];

    for (final startTransition in startFloorTransitions) {
      final pathToTransition = calculatePath(
        (start.id, startTransition.id), // Tupel-Konvertierung
        graph,
      );
      if (pathToTransition.isEmpty) continue;

      for (final endTransition in endFloorTransitions) {
        // Prüfe, ob Übergänge verbunden sind (gleiche Treppe/Aufzug)
        if (_areConnectedTransitions(startTransition, endTransition)) {
          final pathFromTransition = calculatePath(
            (endTransition.id, end.id), // Tupel-Konvertierung
            graph,
          );
          if (pathFromTransition.isEmpty) continue;

          // Kombiniere Teilpfade
          final List<NodeId> completePath = [
            ...pathToTransition.sublist(0, pathToTransition.length - 1),
            startTransition.id,
            endTransition.id,
            ...pathFromTransition.sublist(1),
          ];

          // Kosten berechnen
          final double pathCost = _estimatePathCost(completePath, graph);

          if (pathCost < bestPathCost) {
            bestPathCost = pathCost;
            bestPath = completePath;
          }
        }
      }
    }

    return bestPath;
  }

  /// Findet alle Übergangsknoten (Treppen, Aufzüge) auf einer bestimmten Etage
  List<Node> _findTransitionNodes(
    CampusGraph graph,
    int buildingCode,
    int floorCode,
  ) {
    final List<Node> transitions = [];

    // Etwas optimiert durch direkte Filterung des Typs
    for (final nodeId in graph.allNodeIds) {
      final node = graph.getNodeById(nodeId);
      if (node != null &&
          node.buildingCode == buildingCode &&
          node.floorCode == floorCode) {
        // Nur wenn Treppe oder Aufzug
        if (node.isStaircase || node.isElevator) {
          transitions.add(node);
        }
      }
    }

    return transitions;
  }

  /// Prüft, ob zwei Übergangsknoten verbunden sind (gleicher Aufzug/Treppe)
  bool _areConnectedTransitions(Node transition1, Node transition2) {
    // Gleicher Typ (beide Treppen oder beide Aufzüge)
    if (transition1.type != transition2.type) return false;

    // Gleiches Gebäude
    if (transition1.buildingCode != transition2.buildingCode) return false;

    // Verschiedene Etagen
    if (transition1.floorCode == transition2.floorCode) return false;

    // Gleiche horizontale Position (x,y) mit Toleranz
    final int dx = (transition1.x - transition2.x).abs();
    final int dy = (transition1.y - transition2.y).abs();

    // Wenn die Knoten ungefähr übereinander liegen
    return dx < 5 && dy < 5;
  }

  /// Schätzt die Kosten eines Pfades
  double _estimatePathCost(List<NodeId> path, CampusGraph graph) {
    double cost = 0;

    for (int i = 0; i < path.length - 1; i++) {
      final Node? current = graph.getNodeById(path[i]);
      if (current == null) continue;

      // Direktes Gewicht aus den Kantengewichten
      final double edgeWeight = current.weights[path[i + 1]] ?? 10.0;

      // Zusätzliche Kosten für Etagenwechsel
      final Node? next = graph.getNodeById(path[i + 1]);
      if (next != null && current.floorCode != next.floorCode) {
        cost += 20.0; // Etagenwechsel ist teuer
      }

      cost += edgeWeight;
    }

    return cost;
  }
}

/// Manuelle Implementierung einer Priority Queue
class _ManualPriorityQueue<T> {
  final List<T> _items = [];
  final int Function(T a, T b) _compare;

  _ManualPriorityQueue(this._compare);

  void add(T item) {
    _items.add(item);
    _items.sort(_compare);
  }

  T removeFirst() {
    if (_items.isEmpty) {
      throw StateError("Queue is empty");
    }
    return _items.removeAt(0);
  }

  bool get isEmpty => _items.isEmpty;

  Iterable<T> get items => _items;
}

/// Hilfsklasse für die Prioritätswarteschlange
class _QueueItem {
  final NodeId nodeId;
  final double gScore;
  final double fScore;

  _QueueItem(this.nodeId, this.gScore, this.fScore);
}
