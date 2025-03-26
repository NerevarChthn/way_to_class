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

        // Prüfe auf Aufzug und ob Treppen verfügbar sind
        if (neighbor!.isElevator) {
          final bool stairsAvailable = _checkIfStairsAvailableInBuilding(
            graph,
            neighbor.buildingCode,
            currentNode.floorCode,
            neighbor.floorCode,
          );

          if (stairsAvailable) {
            skipReason = "Aufzug übersprungen (Treppen verfügbar)";
            buffer.writeln(
              "  Nachbar $neighborId${_formatNodeInfo(neighbor)} → übersprungen ($skipReason)",
            );
            continue;
          }
        }

        // Gewichtung
        double weightMultiplier = 1.0;
        String weightInfo = "";

        if (neighbor.isStaircase) {
          weightMultiplier =
              1.5; // Reduziert von 2.0 auf 1.5, um Treppen zu bevorzugen
          weightInfo = "Treppe (×1.5)";
        } else if (neighbor.isElevator) {
          weightMultiplier = 30.0; // Drastisch erhöht von 5.0 auf 30.0
          weightInfo = "Aufzug (×30)";
        }

        if (neighbor.isStaircase && !neighbor.isAccessible) {
          weightMultiplier = 10.0;
          weightInfo = "Nicht barrierefreie Treppe (×10)";
        }

        // Wenn ein Aufzug betrachtet wird, prüfen ob Treppen im Gebäude verfügbar sind
        if (neighbor.isElevator) {
          final bool stairsAvailable = _checkIfStairsAvailableInBuilding(
            graph,
            neighbor.buildingCode,
            currentNode.floorCode,
            neighbor.floorCode,
          );

          if (stairsAvailable) {
            weightMultiplier =
                100.0; // Extrem hoher Malus wenn Treppen verfügbar sind
            weightInfo = "Aufzug (×100, Treppen verfügbar)";
          }
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

  List<NodeId> calculatePath(Path path, CampusGraph graph) {
    final NodeId startId = path.$1;
    final NodeId endId = path.$2;

    if (enableLogging) {
      dev.log("Starte Pfadberechnung von $startId nach $endId");
    }

    final Node? start = graph.getNodeById(startId);
    final Node? end = graph.getNodeById(endId);

    if (enableLogging) {
      dev.log(
        "Knoten abgerufen: Start = ${start != null ? start.id : 'null'}, Ziel = ${end != null ? end.id : 'null'}",
      );
    }

    // Prüfe, ob Knoten existieren
    if (start == null || end == null) {
      if (enableLogging) {
        dev.log(
          "Fehler: Start- oder Zielknoten nicht gefunden. Start: $startId, Ziel: $endId",
        );
      }
      return [];
    }

    // Wenn Start und Ziel identisch sind
    if (startId == endId) {
      if (enableLogging) {
        dev.log("Start- und Zielknoten sind identisch: $startId");
      }
      return [startId];
    }

    // Prüfe, ob Start und Ziel im gleichen Gebäude und auf der gleichen Etage sind
    if (start.buildingCode != end.buildingCode ||
        start.floorCode != end.floorCode) {
      if (enableLogging) {
        dev.log(
          "Gebäude- oder Etagenwechsel erkannt. Start: Gebäude ${start.buildingCode}, Etage ${start.floorCode}; Ziel: Gebäude ${end.buildingCode}, Etage ${end.floorCode}",
        );
      }
      final crossFloorResult = _findCrossFloorPath(start, end, graph);
      if (enableLogging) {
        if (crossFloorResult.isEmpty) {
          dev.log("Kein Pfad über Gebäude-/Etagenwechsel gefunden!");
        } else {
          dev.log(
            "Pfad über Gebäude-/Etagenwechsel gefunden mit ${crossFloorResult.length} Knoten",
          );
        }
      }
      return crossFloorResult;
    }

    // A* Pfadsuche innerhalb einer Etage
    if (enableLogging) {
      dev.log(
        "Starte A* Pfadsuche innerhalb der Etage von $startId nach $endId",
      );
    }
    final result = _findPathAStar(startId, endId, graph);

    if (enableLogging) {
      if (result.isEmpty) {
        dev.log("A* Pfadsuche: Kein Pfad gefunden!");
      } else {
        dev.log(
          "A* Pfadsuche abgeschlossen. Pfad gefunden mit ${result.length} Knoten",
        );
      }
    }

    return result;
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

        // WICHTIG: Prüfe auf Aufzüge bei verfügbaren Treppen und überspringe sie komplett
        if (neighbor.isElevator) {
          final bool stairsAvailable = _checkIfStairsAvailableInBuilding(
            graph,
            neighbor.buildingCode,
            currentNode.floorCode,
            neighbor.floorCode,
          );

          if (stairsAvailable) {
            if (enableLogging) {
              dev.log(
                "Aufzug ${neighbor.id} wird übersprungen, da Treppen verfügbar sind (von ${currentNode.floorCode} nach ${neighbor.floorCode})",
              );
            }
            continue; // Wichtig: Node komplett überspringen
          }
        }

        // Berechneter Aufschlag für verschiedene Knotentypen
        double weightMultiplier = 1.0;

        // Kantengewicht basierend auf Knotentyp anpassen
        if (neighbor.isStaircase) {
          weightMultiplier = 1.5; // Reduziert, um Treppen stärker zu bevorzugen
        } else if (neighbor.isElevator) {
          weightMultiplier =
              30.0; // Aufzüge werden gemieden, aber nicht ausgeschlossen
        }

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

    // Priorisiere Treppenpfade über Aufzugspfade
    final List<Node> startFloorStairs =
        startFloorTransitions.where((node) => node.isStaircase).toList();
    final List<Node> endFloorStairs =
        endFloorTransitions.where((node) => node.isStaircase).toList();

    // Wenn es Treppen auf beiden Etagen gibt, bevorzuge diese
    final List<Node> startTransitionsToUse =
        startFloorStairs.isNotEmpty ? startFloorStairs : startFloorTransitions;
    final List<Node> endTransitionsToUse =
        endFloorStairs.isNotEmpty ? endFloorStairs : endFloorTransitions;

    for (final startTransition in startTransitionsToUse) {
      final pathToTransition = calculatePath(
        (start.id, startTransition.id), // Tupel-Konvertierung
        graph,
      );
      if (pathToTransition.isEmpty) continue;

      for (final endTransition in endTransitionsToUse) {
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

    // Wenn kein Treppenpfad gefunden wurde, probiere Aufzüge als Fallback
    if (bestPath.isEmpty &&
        startFloorStairs.isNotEmpty != startFloorTransitions.isNotEmpty) {
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
    // Debug-Ausgabe
    dev.log(
      "Prüfe Verbindung zwischen: ${transition1.id} (${transition1.name}, ${transition1.floorCode}) und ${transition2.id} (${transition2.name}, ${transition2.floorCode})",
    );

    // Gleicher Typ (beide Treppen oder beide Aufzüge)
    if (transition1.type != transition2.type) {
      dev.log(
        "→ Unterschiedlicher Typ: ${transition1.type} vs ${transition2.type}",
      );
      return false;
    }

    // Gleiches Gebäude
    if (transition1.buildingCode != transition2.buildingCode) {
      dev.log(
        "→ Unterschiedliches Gebäude: ${transition1.buildingCode} vs ${transition2.buildingCode}",
      );
      return false;
    }

    // Verschiedene Etagen
    if (transition1.floorCode == transition2.floorCode) {
      dev.log("→ Gleiche Etage: ${transition1.floorCode}");
      return false;
    }

    // VERBESSERT: Prüfe direkte Nachbarschaft in den Kantengewichten
    if (transition1.weights.containsKey(transition2.id)) {
      dev.log(
        "→ Direkte Verbindung gefunden: ${transition1.id} → ${transition2.id}",
      );
      return true;
    }
    if (transition2.weights.containsKey(transition1.id)) {
      dev.log(
        "→ Direkte Verbindung gefunden: ${transition2.id} → ${transition1.id}",
      );
      return true;
    }

    // Fallback: Prüfe auf ähnliche Namen (falls vorhanden)
    if (transition1.name.isNotEmpty && transition2.name.isNotEmpty) {
      final name1 = transition1.name.toLowerCase();
      final name2 = transition2.name.toLowerCase();

      // Wenn beide Namen Treppen- oder Aufzugsnummern enthalten
      if ((name1.contains("treppe") || name1.contains("aufzug")) &&
          (name2.contains("treppe") || name2.contains("aufzug"))) {
        // Extrahiere Nummern aus Namen
        final RegExp numPattern = RegExp(r'\d+');
        final num1Matches = numPattern.allMatches(name1);
        final num2Matches = numPattern.allMatches(name2);

        if (num1Matches.isNotEmpty && num2Matches.isNotEmpty) {
          final num1 = num1Matches.first.group(0);
          final num2 = num2Matches.first.group(0);

          if (num1 == num2) {
            dev.log("→ Verbindung gefunden durch gleiche Nummer: $num1");
            return true;
          }
        }
      }
    }

    // Keine Verbindung gefunden
    dev.log(
      "→ Keine Verbindung gefunden zwischen ${transition1.id} und ${transition2.id}",
    );
    return false;
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

  /// Verbesserte Prüfung ob Treppen zwischen zwei Etagen im selben Gebäude verfügbar sind
  bool _checkIfStairsAvailableInBuilding(
    CampusGraph graph,
    int buildingCode,
    int startFloorCode,
    int endFloorCode,
  ) {
    // Wenn auf der gleichen Etage, keine Treppen nötig
    if (startFloorCode == endFloorCode) {
      return false;
    }

    // Statischer Cache für bereits gefundene Treppenverbindungen
    final Map<String, bool> connectionCache = {};

    // Cache-Key erstellen
    final String cacheKey = '$buildingCode-$startFloorCode-$endFloorCode';

    // Wenn Ergebnis im Cache, dieses zurückgeben
    if (connectionCache.containsKey(cacheKey)) {
      return connectionCache[cacheKey]!;
    }

    // Direkter Check: Gibt es Treppen, die beide Etagen verbinden?
    final stairsOnStartFloor = <Node>[];
    final stairsOnEndFloor = <Node>[];

    // Sammel alle Treppennoten auf Start- und Zieletage
    for (final nodeId in graph.allNodeIds) {
      final node = graph.getNodeById(nodeId);
      if (node != null &&
          node.buildingCode == buildingCode &&
          node.isStaircase) {
        if (node.floorCode == startFloorCode) {
          stairsOnStartFloor.add(node);
        } else if (node.floorCode == endFloorCode) {
          stairsOnEndFloor.add(node);
        }
      }
    }

    // Wenn keine Treppen auf einer der Etagen gefunden wurden
    if (stairsOnStartFloor.isEmpty || stairsOnEndFloor.isEmpty) {
      connectionCache[cacheKey] = false;
      return false;
    }

    // Wir suchen nun explizit nach benutzbaren Treppen
    bool hasAccessibleStairs = false;

    // Prüfe alle möglichen Kombinationen von Treppen
    for (final startStair in stairsOnStartFloor) {
      for (final endStair in stairsOnEndFloor) {
        if (_areConnectedTransitions(startStair, endStair)) {
          // Treppen sind verbunden
          connectionCache[cacheKey] = true;

          // Prüfe auf Zugänglichkeit
          if (startStair.isAccessible && endStair.isAccessible) {
            hasAccessibleStairs = true;
          }

          // Wenn wir zugängliche Treppen gefunden haben, bevorzugen wir diese
          if (hasAccessibleStairs) {
            return true;
          }
        }
      }
    }

    // Wenn wir Treppen gefunden haben (auch nicht-zugängliche), geben wir true zurück
    if (connectionCache[cacheKey] == true) {
      return true;
    }

    // Überprüfe auch indirekte Verbindungen durch andere Etagen
    connectionCache[cacheKey] = _checkForIndirectStairConnections(
      graph,
      buildingCode,
      startFloorCode,
      endFloorCode,
      stairsOnStartFloor,
    );

    return connectionCache[cacheKey]!;
  }

  /// Prüft auf indirekte Treppenverbindungen über Zwischenetagen
  bool _checkForIndirectStairConnections(
    CampusGraph graph,
    int buildingCode,
    int startFloorCode,
    int endFloorCode,
    List<Node> startStairs,
  ) {
    // Sammle alle verfügbaren Etagen im Gebäude
    final Set<int> floors = {};

    for (final nodeId in graph.allNodeIds) {
      final node = graph.getNodeById(nodeId);
      if (node != null && node.buildingCode == buildingCode) {
        floors.add(node.floorCode);
      }
    }

    // Entferne Start- und Zieletage
    floors.remove(startFloorCode);
    floors.remove(endFloorCode);

    // Prüfe für jede Zwischenetage, ob es einen Pfad gibt
    for (final intermediateFloor in floors) {
      // Prüfe, ob es Treppen von der Startetage zur Zwischenetage gibt
      final hasConnectionToIntermediate = _checkIfStairsAvailableInBuilding(
        graph,
        buildingCode,
        startFloorCode,
        intermediateFloor,
      );

      // Prüfe, ob es Treppen von der Zwischenetage zur Zieletage gibt
      final hasConnectionFromIntermediate = _checkIfStairsAvailableInBuilding(
        graph,
        buildingCode,
        intermediateFloor,
        endFloorCode,
      );

      // Wenn beide Verbindungen existieren, gibt es einen indirekten Pfad
      if (hasConnectionToIntermediate && hasConnectionFromIntermediate) {
        return true;
      }
    }

    return false;
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
