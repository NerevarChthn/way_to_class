import 'dart:math';
import 'dart:developer' as dev;
import 'package:way_to_class/constants/metadata_keys.dart';
import 'package:way_to_class/constants/segment.dart';
import 'package:way_to_class/constants/types.dart';
import 'package:way_to_class/core/models/campus_graph.dart';
import 'package:way_to_class/core/models/node.dart';
import 'package:way_to_class/core/models/route_segments.dart';

/// Generator für Wegsegmente aus Pfadknoten
class SegmentsGenerator {
  List<RouteSegment> convertPath(List<NodeId> path, CampusGraph graph) {
    if (path.isEmpty || path.length < 2) {
      return [];
    }

    // Erzeuge eine tiefe Kopie des Pfads, um Originaldaten nicht zu verändern
    path = List<NodeId>.from(path);
    dev.log("Verarbeite Pfad mit ${path.length} Knoten: ${path.join(', ')}");

    final List<RouteSegment> segments = [];

    // Spezialbehandlung für den Startpunkt (Ausgang aus einem Raum)
    if (path.length >= 3) {
      final startNode = graph.getNodeById(path[0]);
      if (startNode != null &&
          _determineSegmentType(path[0], graph) == SegmentType.room) {
        final List<NodeId> originNodes = [path[0], path[1], path[2]];
        segments.add(_createSegment(originNodes, SegmentType.origin, graph));
        // Entferne den Raum, damit er nicht doppelt auftaucht
        path.removeAt(0);
      }
    }

    // Ermittlung der Breakpoints (kritische Punkte im Pfad)
    final List<_PathBreakpoint> breakpoints = _findPathBreakpoints(path, graph);
    dev.log("Gefundene Breakpoints: ${breakpoints.length}");
    dev.log(breakpoints.toString());

    // Falls keine Breakpoints gefunden werden, den gesamten Pfad als ein Segment behandeln
    if (breakpoints.isEmpty) {
      final SegmentType pathType = _determineSegmentType(path[0], graph);
      segments.add(_createSegment(path, pathType, graph));
      return segments;
    }

    int startIndex = 0;
    NodeId lastProcessedNode = "";

    // Verarbeitung der Breakpoints
    for (int i = 0; i < breakpoints.length; i++) {
      final _PathBreakpoint bp = breakpoints[i];
      final int endIndex = bp.index;

      if (bp.type == BreakpointType.turn) {
        // Falls startIndex bereits ≥ endIndex ist, setzen wir startIndex auf (endIndex - 1), sofern möglich
        if (endIndex > 0 && startIndex >= endIndex) {
          startIndex = endIndex - 1;
        }
        // Nur verarbeiten, wenn auch mindestens ein Knoten nach dem Abbiegungsknoten existiert (für die Berechnung des Winkels)
        if (endIndex >= startIndex && endIndex + 1 < path.length) {
          final List<NodeId> segmentNodes = path.sublist(
            startIndex,
            endIndex + 1,
          );
          if (segmentNodes.length >= 2 &&
              segmentNodes.last != lastProcessedNode) {
            // Berechne Turn-Richtung anhand der drei relevanten Knoten: [vorher, Abbiegung, nachher]
            final String direction = _calculateTurnDirection([
              path[endIndex - 1],
              path[endIndex],
              path[endIndex + 1],
            ], graph);
            final RouteSegment seg = _createSegment(
              segmentNodes,
              _determineSegmentType(segmentNodes[0], graph),
              graph,
            );
            seg.metadata[MetadataKeys.direction] = direction;

            final String? landmarkName = graph.findNearestNonHallwayNode(
              path[endIndex],
            );

            if (landmarkName != null) {
              seg.metadata[MetadataKeys.landmark] = landmarkName;
            }

            segments.add(seg);
            lastProcessedNode = segmentNodes.last;
          }
        }
        // Setze startIndex so, dass der Abbiegungsknoten auch im nächsten Segment enthalten ist
        startIndex = endIndex;
      } else if (bp.type == BreakpointType.typeChange) {
        // Erzeuge Segment von startIndex bis kurz vor den Breakpoint
        if (endIndex > startIndex) {
          final List<NodeId> segmentNodes = path.sublist(startIndex, endIndex);
          if (segmentNodes.length >= 2 &&
              segmentNodes.last != lastProcessedNode) {
            segments.add(
              _createSegment(
                segmentNodes,
                _determineSegmentType(segmentNodes[0], graph),
                graph,
              ),
            );
            lastProcessedNode = segmentNodes.last;
          }
        }

        // Spezielle Behandlung für Typwechsel (z. B. Türen, Treppen, Aufzüge)
        final NodeId bpNode = path[endIndex];
        final SegmentType bpType = _determineSegmentType(bpNode, graph);
        if (bpType == SegmentType.door ||
            bpType == SegmentType.stairs ||
            bpType == SegmentType.elevator) {
          final List<NodeId> specialSegmentNodes = [];
          if (endIndex > 0 && path[endIndex - 1] != lastProcessedNode) {
            specialSegmentNodes.add(path[endIndex - 1]);
          }
          specialSegmentNodes.add(bpNode);
          if (endIndex + 1 < path.length) {
            specialSegmentNodes.add(path[endIndex + 1]);
          }
          if (specialSegmentNodes.length >= 2 || bpType == SegmentType.door) {
            segments.add(_createSegment(specialSegmentNodes, bpType, graph));
            lastProcessedNode = bpNode;
          }
        }
        // Wenn direkt nach diesem TypeChange ein Turn folgt, wollen wir den Abbiegungsknoten nicht verlieren.
        final bool nextIsTurn =
            (i + 1 < breakpoints.length &&
                breakpoints[i + 1].type == BreakpointType.turn);
        // Falls das Segment zwischen startIndex und dem Breakpoint weniger als 2 Knoten hat,
        // setzen wir startIndex so, dass der Knoten erhalten bleibt.
        if (!nextIsTurn && (endIndex - startIndex) < 2) {
          startIndex = endIndex;
        } else if (nextIsTurn) {
          startIndex = endIndex; // Knoten behalten für den nächsten Turn
        } else {
          startIndex = endIndex + 1;
        }
      }
    }

    // Verarbeitung des letzten Segments
    if (startIndex < path.length) {
      final List<NodeId> lastSegmentNodes = path.sublist(startIndex);
      // Falls nur ein einzelner Knoten übrig ist, füge den vorherigen hinzu, um mindestens zwei Knoten zu erhalten
      if (lastSegmentNodes.length == 1 && startIndex > 0) {
        lastSegmentNodes.insert(0, path[startIndex - 1]);
      }
      if (lastSegmentNodes.length >= 2) {
        final SegmentType lastNodeType = _determineSegmentType(
          lastSegmentNodes.last,
          graph,
        );
        if (lastNodeType == SegmentType.room ||
            lastNodeType == SegmentType.toilet ||
            lastNodeType == SegmentType.exit) {
          // Destination-Segment: Nutzt die letzten Knoten, um die Seite zu berechnen
          if (lastSegmentNodes.length >= 3) {
            final List<NodeId> destinationNodes = lastSegmentNodes.sublist(
              lastSegmentNodes.length - 3,
            );
            segments.add(
              _createSegment(destinationNodes, SegmentType.destination, graph),
            );
            if (lastSegmentNodes.length > 3) {
              final List<NodeId> hallwayNodes = lastSegmentNodes.sublist(
                0,
                lastSegmentNodes.length - 2,
              );
              if (hallwayNodes.length >= 2) {
                segments.add(
                  _createSegment(hallwayNodes, SegmentType.hallway, graph),
                );
              }
            }
          } else {
            segments.add(
              _createSegment(lastSegmentNodes, SegmentType.destination, graph),
            );
          }
        } else {
          segments.add(
            _createSegment(
              lastSegmentNodes,
              _determineSegmentType(lastSegmentNodes[0], graph),
              graph,
            ),
          );
        }
      } else if (lastSegmentNodes.length == 1 &&
          lastSegmentNodes[0] != lastProcessedNode) {
        final SegmentType nodeType = _determineSegmentType(
          lastSegmentNodes[0],
          graph,
        );
        if (nodeType != SegmentType.unknown) {
          segments.add(_createSegment(lastSegmentNodes, nodeType, graph));
        }
      }
    }

    // Zusammenführen von Hallway- und Door-Segmenten
    return _mergeSegments(segments);
  }

  List<RouteSegment> _mergeSegments(List<RouteSegment> segments) {
    final List<RouteSegment> merged = [];
    // Wir wollen nur hallway- und door-Segmente zusammenführen.
    final mergeGroupTypes = {SegmentType.hallway, SegmentType.door};

    for (int i = 0; i < segments.length; i++) {
      final RouteSegment current = segments[i];

      // Segmente, die nicht in die Merge-Gruppe gehören, werden direkt übernommen.
      if (!mergeGroupTypes.contains(current.type)) {
        merged.add(current);
        continue;
      }

      // Zunächst sammeln wir alle aufeinanderfolgenden Segmente, die in die Merge-Gruppe fallen
      // und dieselbe Umgebung (building, floor) haben.
      final List<RouteSegment> group = [current];
      while (i + 1 < segments.length &&
          mergeGroupTypes.contains(segments[i + 1].type)) {
        final RouteSegment nextSeg = segments[i + 1];
        if (nextSeg.metadata[MetadataKeys.building] ==
                current.metadata[MetadataKeys.building] &&
            nextSeg.metadata[MetadataKeys.floor] ==
                current.metadata[MetadataKeys.floor]) {
          group.add(nextSeg);
          i++;
        } else {
          break;
        }
      }

      // Nun teilen wir die Gruppe in Untergruppen auf:
      // Jedes Mal, wenn ein Segment mit einer Richtungsänderung (direction ≠ "geradeaus")
      // gefunden wird, schließen wir den aktuellen Merge-Block ab (einschließlich dieses Segments)
      // und starten einen neuen Block.
      final List<List<RouteSegment>> mergeBlocks = [];
      List<RouteSegment> currentBlock = [];
      for (final seg in group) {
        currentBlock.add(seg);
        // Wenn in den Metadaten eine Richtungsänderung (nicht "geradeaus") vorhanden ist,
        // schließen wir den aktuellen Block ab.
        if (seg.metadata.containsKey(MetadataKeys.direction) &&
            seg.metadata[MetadataKeys.direction] !=
                MetadataKeys.straightDirection) {
          mergeBlocks.add(List<RouteSegment>.from(currentBlock));
          currentBlock = [];
        }
      }
      if (currentBlock.isNotEmpty) {
        mergeBlocks.add(currentBlock);
      }

      // Für jeden Merge-Block führen wir das Zusammenführen durch:
      for (final block in mergeBlocks) {
        if (block.isEmpty) continue;
        if (block.length == 1) {
          merged.add(block.first);
        } else {
          final List<NodeId> mergedNodes = [];
          int totalDistance = 0;
          int doorCount = 0;
          // Übernehme als Basis die Metadaten des letzten Segments im Block.
          final Map<String, dynamic> commonMetadata = Map<String, dynamic>.from(
            block.last.metadata,
          );
          for (final seg in block) {
            // Knoten zusammenführen – Duplikate an den Übergängen vermeiden.
            if (mergedNodes.isEmpty) {
              mergedNodes.addAll(seg.nodes);
            } else {
              if (mergedNodes.last == seg.nodes.first) {
                mergedNodes.addAll(seg.nodes.sublist(1));
              } else {
                mergedNodes.addAll(seg.nodes);
              }
            }
            if (seg.metadata.containsKey(MetadataKeys.distance)) {
              totalDistance += seg.metadata[MetadataKeys.distance] as int;
            }
            if (seg.type == SegmentType.door) {
              doorCount++;
            }
            if (seg.metadata.containsKey(MetadataKeys.doorCount)) {
              doorCount += seg.metadata[MetadataKeys.doorCount] as int;
            }
          }
          commonMetadata[MetadataKeys.distance] = totalDistance;
          commonMetadata[MetadataKeys.doorCount] = doorCount;
          // Bestimme den Segmenttyp: Falls mindestens ein Segment als hallway markiert ist, wählen wir hallway.
          final bool hasHallway = block.any(
            (seg) => seg.type == SegmentType.hallway,
          );
          final SegmentType mergedType =
              hasHallway ? SegmentType.hallway : SegmentType.door;
          merged.add(
            RouteSegment(
              type: mergedType,
              nodes: mergedNodes,
              metadata: commonMetadata,
            ),
          );
        }
      }
    }

    return merged;
  }

  /// Findet alle Breakpoints (kritische Punkte) im Pfad
  List<_PathBreakpoint> _findPathBreakpoints(
    List<NodeId> path,
    CampusGraph graph,
  ) {
    final List<_PathBreakpoint> breakpoints = [];

    // Analysiere jeden Knoten (außer Start und Ende) auf Typwechsel oder Richtungsänderungen
    for (int i = 1; i < path.length - 1; i++) {
      final NodeId prevId = path[i - 1];
      final NodeId currentId = path[i];
      final NodeId nextId = path[i + 1];

      // Knoten abrufen
      final prevNode = graph.getNodeById(prevId);
      final currentNode = graph.getNodeById(currentId);
      final nextNode = graph.getNodeById(nextId);

      if (prevNode == null || currentNode == null || nextNode == null) {
        continue;
      }

      // Typwechsel erkennen
      final SegmentType prevType = _determineSegmentType(prevId, graph);
      final SegmentType currentType = _determineSegmentType(currentId, graph);
      final SegmentType nextType = _determineSegmentType(nextId, graph);

      // ÄNDERUNG: Spezialbehandlung für Türen
      // Wenn der aktuelle Knoten eine Tür ist, aber der vorherige und nächste Flure sind,
      // behandeln wir die Tür nicht als Breakpoint
      if (currentType == SegmentType.door &&
          prevType == SegmentType.hallway &&
          nextType == SegmentType.hallway) {
        // Prüfen, ob die Tür eine gerade Fortsetzung des Flurs ist
        // Vektoren berechnen
        final dx1 = currentNode.x - prevNode.x;
        final dy1 = currentNode.y - prevNode.y;
        final dx2 = nextNode.x - currentNode.x;
        final dy2 = nextNode.y - currentNode.y;

        // Längen der Vektoren
        final length1 = sqrt(dx1 * dx1 + dy1 * dy1);
        final length2 = sqrt(dx2 * dx2 + dy2 * dy2);

        if (length1 > minSegmentLength && length2 > minSegmentLength) {
          // Normalisierte Vektoren
          final nx1 = dx1 / length1;
          final ny1 = dy1 / length1;
          final nx2 = dx2 / length2;
          final ny2 = dy2 / length2;

          // Skalarprodukt für den Winkel
          final dotProduct = nx1 * nx2 + ny1 * ny2;

          // Wenn die Vektoren nahezu parallel sind (dotProduct nahe 1), ist es eine gerade Linie
          // und wir betrachten die Tür als Teil des Flursegments
          if (dotProduct > parallelThreshold) {
            // Kein Breakpoint für diese Tür
            continue;
          }
        }
      }

      // Bei Typwechsel (z.B. Flur → Treppe) handelt es sich um einen Breakpoint
      if (prevType != currentType || currentType != nextType) {
        breakpoints.add(_PathBreakpoint(i, BreakpointType.typeChange));
        continue;
      }

      // WICHTIG: Erkennung von Richtungsänderungen im Flur
      // Dies wurde im vorherigen Code ausgelassen!
      if (((currentType == SegmentType.door) ||
              (currentType == SegmentType.hallway)) &&
          prevType == SegmentType.hallway &&
          ((nextType == SegmentType.door) ||
              (nextType == SegmentType.hallway))) {
        // Vektoren berechnen
        final dx1 = currentNode.x - prevNode.x;
        final dy1 = currentNode.y - prevNode.y;
        final dx2 = nextNode.x - currentNode.x;
        final dy2 = nextNode.y - currentNode.y;

        // Längen der Vektoren
        final length1 = sqrt(dx1 * dx1 + dy1 * dy1);
        final length2 = sqrt(dx2 * dx2 + dy2 * dy2);

        if (length1 > minSegmentLength && length2 > minSegmentLength) {
          // Normalisierte Vektoren
          final nx1 = dx1 / length1;
          final ny1 = dy1 / length1;
          final nx2 = dx2 / length2;
          final ny2 = dy2 / length2;

          // Skalarprodukt für den Winkel
          final dotProduct = nx1 * nx2 + ny1 * ny2;

          // Kreuzprodukt für die Richtung
          final crossProduct = nx1 * ny2 - ny1 * nx2;

          if (crossProduct == 0) {
            // Keine Richtungsänderung, da die Vektoren parallel sind
            continue;
          }

          // Winkel zwischen den Vektoren berechnen
          final angle = acos(dotProduct.clamp(-1.0, 1.0)) * 180 / pi;

          // Debug-Ausgabe
          final direction = crossProduct > 0 ? "links" : "rechts";
          dev.log(
            "Knoten $i ($currentId): Winkel $angle° nach $direction (Dot: $dotProduct)",
          );

          // Wenn der Winkel größer als 15° ist, handelt es sich um eine Abbiegung
          if (angle > turnAngleThreshold) {
            dev.log("Abbiegung erkannt bei $currentId");
            breakpoints.add(_PathBreakpoint(i, BreakpointType.turn));
          }
        }
      }
    }

    return breakpoints;
  }

  /// Creates a segment based on type and nodes
  RouteSegment _createSegment(
    List<NodeId> nodes,
    SegmentType type,
    CampusGraph graph,
  ) {
    // Metadaten initialisieren
    final Map<String, dynamic> metadata = {};

    // Debug-Ausgabe
    dev.log(
      "Erstelle $type-Segment mit ${nodes.length} Knoten: ${nodes.join(', ')}",
    );

    // Metadaten basierend auf Segmenttyp hinzufügen
    switch (type) {
      case SegmentType.hallway:
        _addHallwayMetadata(metadata, nodes, graph);
        break;
      case SegmentType.stairs:
        _addStairsMetadata(metadata, nodes, graph);
        break;
      case SegmentType.elevator:
        _addElevatorMetadata(metadata, nodes, graph);
        break;
      case SegmentType.room:
        _addRoomMetadata(metadata, nodes, graph);
        break;
      case SegmentType.exit:
        _addExitMetadata(metadata, nodes, graph);
        break;
      case SegmentType.toilet:
        _addToiletMetadata(metadata, nodes, graph);
        break;
      case SegmentType.door:
        _addDoorMetadata(metadata, nodes, graph);
        break;
      case SegmentType.origin:
        _addOriginMetadata(metadata, nodes, graph);
        break;
      case SegmentType.destination:
        _addDestinationMetadata(metadata, nodes, graph);
        break;
      default:
        break;
    }

    // Building and floor
    final Node? startNode = graph.getNodeById(nodes.first);
    if (startNode != null) {
      metadata['building'] = startNode.buildingName;
      metadata['floor'] = startNode.floorNumber;
    }

    // Distanz berechnen
    if (type != SegmentType.destination && type != SegmentType.origin) {
      metadata[MetadataKeys.distance] = _calculatePathDistance(nodes, graph);
    }

    return RouteSegment(type: type, nodes: nodes, metadata: metadata);
  }

  /// Adds metadata for a door segment
  void _addDoorMetadata(
    Map<String, dynamic> metadata,
    List<NodeId> nodes,
    CampusGraph graph,
  ) {
    final doorNode = graph.getNodeById(nodes.last);
    if (doorNode == null) return;

    // Füge den Namen der Tür hinzu, falls vorhanden
    if (doorNode.name.isNotEmpty) {
      metadata['name'] = doorNode.name;
    } else {
      // Fallback-Name basierend auf der ID
      metadata['name'] = 'Tür';
    }

    // Optional: Füge spezifische Türeigenschaften hinzu
    metadata['autoOpen'] = doorNode.hasProperty(
      0x80,
    ); // Beispiel für automatische Tür
    metadata['locked'] = doorNode.hasProperty(
      0x100,
    ); // Beispiel für abgeschlossene Tür
  }

  /// Adds metadata for a destination segment (hallway to room at end)
  void _addDestinationMetadata(
    Map<String, dynamic> metadata,
    List<NodeId> nodes,
    CampusGraph graph,
  ) {
    if (nodes.length < 2) {
      dev.log("WARNUNG: Destination-Segment mit zu wenigen Knoten");
      return;
    }

    // Rauminformationen
    final roomNode = graph.getNodeById(nodes.last);
    if (roomNode != null) {
      metadata['currentName'] = roomNode.name;
    }

    // Seite des Flurs (links/rechts)
    if (nodes.length >= 2) {
      final hallwayNode = graph.getNodeById(nodes[nodes.length - 2]);
      if (hallwayNode != null && roomNode != null) {
        metadata['side'] = _calculateSide(hallwayNode, roomNode);
      }
    }
  }

  /// Adds metadata for a hallway segment
  void _addHallwayMetadata(
    Map<String, dynamic> metadata,
    List<NodeId> nodes,
    CampusGraph graph,
  ) {
    if (nodes.length < 2) return;

    // Hallway name (if available)
    final Node? hallwayNode = graph.getNodeById(nodes.last);
    if (hallwayNode != null && hallwayNode.name.isNotEmpty) {
      metadata['currentName'] = hallwayNode.name;
    }
  }

  /// Adds metadata for an origin segment (room to hallway at start)
  void _addOriginMetadata(
    Map<String, dynamic> metadata,
    List<NodeId> nodes,
    CampusGraph graph,
  ) {
    if (nodes.length < 3) {
      dev.log("WARNUNG: origin-Segment mit zu wenigen Knoten");
      return;
    }

    // Rauminformationen
    final roomNode = graph.getNodeById(nodes[0]);
    if (roomNode != null) {
      metadata['originName'] = roomNode.name;
    }

    // Richtungsinformationen beim Verlassen des Raums
    final direction = _calculateTurnDirection(nodes, graph);
    metadata[MetadataKeys.direction] = direction;

    // Flur-Informationen
    final hallwayNode = graph.getNodeById(nodes[2]);
    if (hallwayNode != null && hallwayNode.name.isNotEmpty) {
      metadata['currentName'] = hallwayNode.name;
    }
  }

  /// Adds metadata for a stairs segment
  void _addStairsMetadata(
    Map<String, dynamic> metadata,
    List<NodeId> nodes,
    CampusGraph graph,
  ) {
    if (nodes.length < 2) return;

    final startNode = graph.getNodeById(nodes.first);
    final endNode = graph.getNodeById(nodes.last);

    if (startNode != null && endNode != null) {
      // Direction (up/down)
      if (startNode.floorCode < endNode.floorCode) {
        metadata[MetadataKeys.direction] = 'hoch';
        metadata['floorChange'] = endNode.floorNumber - startNode.floorNumber;
        metadata['targetFloor'] = endNode.floorNumber;
      } else {
        metadata[MetadataKeys.direction] = 'runter';
        metadata['floorChange'] = startNode.floorNumber - endNode.floorNumber;
        metadata['targetFloor'] = endNode.floorNumber;
      }

      // Accessibility
      metadata['accessible'] = startNode.isAccessible;
    }
  }

  /// Adds metadata for an elevator segment
  void _addElevatorMetadata(
    Map<String, dynamic> metadata,
    List<NodeId> nodes,
    CampusGraph graph,
  ) {
    if (nodes.length < 2) return;

    final startNode = graph.getNodeById(nodes.first);
    final endNode = graph.getNodeById(nodes.last);

    if (startNode != null && endNode != null) {
      // Start and target floors
      metadata['startFloor'] = startNode.floorNumber;
      metadata['targetFloor'] = endNode.floorNumber;
      metadata['floorChange'] =
          (endNode.floorNumber - startNode.floorNumber).abs();

      // Direction
      metadata[MetadataKeys.direction] =
          startNode.floorNumber < endNode.floorNumber ? 'hoch' : 'runter';
    }
  }

  /// Adds metadata for a room segment
  void _addRoomMetadata(
    Map<String, dynamic> metadata,
    List<NodeId> nodes,
    CampusGraph graph,
  ) {
    final roomNode = graph.getNodeById(nodes.last);
    if (roomNode == null) return;

    metadata['currentName'] = roomNode.name;

    // Side of hallway (left/right)
    if (nodes.length >= 2) {
      final prevNode = graph.getNodeById(nodes[nodes.length - 2]);
      if (prevNode != null) {
        metadata['side'] = _calculateSide(prevNode, roomNode);
      }
    }
  }

  /// Adds metadata for an exit segment
  void _addExitMetadata(
    Map<String, dynamic> metadata,
    List<NodeId> nodes,
    CampusGraph graph,
  ) {
    final exitNode = graph.getNodeById(nodes.last);
    if (exitNode == null) return;

    metadata['currentName'] = exitNode.name;
    metadata['emergency'] = exitNode.isEmergencyExit;
  }

  /// Adds metadata for a toilet segment
  void _addToiletMetadata(
    Map<String, dynamic> metadata,
    List<NodeId> nodes,
    CampusGraph graph,
  ) {
    final toiletNode = graph.getNodeById(nodes.last);
    if (toiletNode == null) return;

    metadata['currentName'] = toiletNode.name;
    metadata['accessible'] = toiletNode.isAccessible;
  }

  /// Calculates the total distance of a path
  int _calculatePathDistance(List<NodeId> nodes, CampusGraph graph) {
    double distance = 0;

    for (int i = 0; i < nodes.length - 1; i++) {
      final node1 = graph.getNodeById(nodes[i]);
      final node2 = graph.getNodeById(nodes[i + 1]);

      if (node1 != null && node2 != null) {
        distance += _calculateDistance(node1, node2);
      }
    }

    return distance.round();
  }

  /// Calculates the Euclidean distance between two nodes
  double _calculateDistance(Node node1, Node node2) {
    final dx = node2.x - node1.x;
    final dy = node2.y - node1.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Determines the segment type for a node based on Node properties
  SegmentType _determineSegmentType(NodeId nodeId, CampusGraph graph) {
    final node = graph.getNodeById(nodeId);
    if (node == null) return SegmentType.unknown;

    if (node.isRoom) return SegmentType.room;
    if (node.isCorridor) return SegmentType.hallway;
    if (node.isStaircase) return SegmentType.stairs;
    if (node.isElevator) return SegmentType.elevator;
    if (node.isToilet) return SegmentType.toilet;
    if (node.isDoor) return SegmentType.door;
    if (node.isEmergencyExit) return SegmentType.exit;

    return SegmentType.unknown;
  }

  /// Calculates the turn direction for a list of nodes
  String _calculateTurnDirection(List<NodeId> nodes, CampusGraph graph) {
    final String straight = 'geradeaus';
    // Für die Berechnung der Richtung brauchen wir mindestens 3 Knoten
    if (nodes.length < 3) {
      return straight;
    }

    // Holen der relevanten Knoten für die Richtungsberechnung
    final node1 = graph.getNodeById(nodes[0]);
    final node2 = graph.getNodeById(nodes[1]);
    final node3 = graph.getNodeById(nodes[2]);

    if (node1 == null || node2 == null || node3 == null) {
      return straight;
    }

    // Vektoren berechnen
    final dx1 = node2.x - node1.x;
    final dy1 = node2.y - node1.y;
    final dx2 = node3.x - node2.x;
    final dy2 = node3.y - node2.y;

    // Längen berechnen
    final length1 = sqrt(dx1 * dx1 + dy1 * dy1);
    final length2 = sqrt(dx2 * dx2 + dy2 * dy2);

    if (length1 < minSegmentLength || length2 < minSegmentLength) {
      return straight;
    }

    // Normalisierte Vektoren
    final nx1 = dx1 / length1;
    final ny1 = dy1 / length1;
    final nx2 = dx2 / length2;
    final ny2 = dy2 / length2;

    // Skalarprodukt für Winkelgröße
    final dotProduct = nx1 * nx2 + ny1 * ny2;

    // Kreuzprodukt für Winkelrichtung (positiv = links, negativ = rechts)
    final crossProduct = nx1 * ny2 - ny1 * nx2;

    // Winkel berechnen und Vorzeichen vom Kreuzprodukt übernehmen
    final double angle = acos(dotProduct.clamp(-1.0, 1.0)) * 180 / pi;
    final double angleDegrees = crossProduct >= 0 ? angle : -angle;

    // Bestimme die Richtung basierend auf dem Winkel
    final String direction;
    if (angleDegrees.abs() < 10) {
      direction = straight;
    } else if (angleDegrees > 0) {
      // Linksabbiegung
      if (angleDegrees < 30) {
        direction = "leicht links";
      } else if (angleDegrees < 110) {
        direction = "links";
      } else {
        direction = "links halten";
      }
    } else {
      // Rechtsabbiegung
      if (angleDegrees > -30) {
        direction = "leicht rechts";
      } else if (angleDegrees > -110) {
        direction = "rechts";
      } else {
        direction = "rechts halten";
      }
    }

    return direction;
  }

  /// Calculates which side of a hallway a room is on
  String _calculateSide(Node corridorNode, Node roomNode) {
    final dx = roomNode.x - corridorNode.x;
    final dy = roomNode.y - corridorNode.y;

    // Simplified calculation: If corridor runs horizontally (larger dx)
    if (dx.abs() > dy.abs()) {
      return dy > 0 ? "rechts" : "links";
    } else {
      // If corridor runs vertically (larger dy)
      return dx > 0 ? "rechts" : "links";
    }
  }
}

/// Definition der Breakpoint-Typen im Pfad
enum BreakpointType {
  turn, // Abbiegung im Flur
  typeChange, // Änderung des Node-Typs (z.B. Flur → Treppe)
}

/// Repräsentiert einen kritischen Punkt im Pfad
class _PathBreakpoint {
  final int index; // Position im Pfad
  final BreakpointType type; // Art des Breakpoints

  _PathBreakpoint(this.index, this.type);

  @override
  String toString() => "Breakpoint($index, $type)";
}
