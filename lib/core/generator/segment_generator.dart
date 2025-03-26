import 'dart:math';
import 'dart:developer' as dev;
import 'package:way_to_class/constants/metadata_keys.dart';
import 'package:way_to_class/constants/node_data.dart';
import 'package:way_to_class/constants/segment.dart';
import 'package:way_to_class/constants/types.dart';
import 'package:way_to_class/core/models/campus_graph.dart';
import 'package:way_to_class/core/models/node.dart';
import 'package:way_to_class/core/models/route_segments.dart';

// Typdefinition für Metadata-Builder Funktionen
typedef MetadataBuilder =
    void Function(
      Map<String, dynamic> metadata,
      List<NodeId> nodes,
      CampusGraph graph,
    );

/// Generator für Wegsegmente aus Pfadknoten
class SegmentsGenerator {
  late final Map<SegmentType, MetadataBuilder> _metadataBuilders;

  SegmentsGenerator() {
    _metadataBuilders = {
      SegmentType.hallway: _addHallwayMetadata,
      SegmentType.stairs: _addStairsMetadata,
      SegmentType.elevator: _addElevatorMetadata,
      SegmentType.room: _addRoomMetadata,
      SegmentType.exit: _addExitMetadata,
      SegmentType.toilet: _addToiletMetadata,
      SegmentType.door: _addDoorMetadata,
      SegmentType.origin: _addOriginMetadata,
      SegmentType.destination: _addDestinationMetadata,
    };
  }

  List<RouteSegment> convertPath(List<NodeId> path, CampusGraph graph) {
    if (path.isEmpty || path.length < 2) {
      return [];
    }

    // Erzeuge eine Kopie des Pfads, um Originaldaten nicht zu verändern
    path = List<NodeId>.from(path);
    dev.log("Verarbeite Pfad mit ${path.length} Knoten: ${path.join(', ')}");

    final List<RouteSegment> segments = [];

    // Spezialbehandlung für Startpunkt (Origin)
    if (path.length >= 3) {
      final startNode = graph.getNodeById(path[0]);
      if (startNode != null &&
          _determineSegmentType(path[0], graph) == SegmentType.room) {
        final List<NodeId> originNodes = [path[0], path[1], path[2]];
        segments.add(_createSegment(originNodes, SegmentType.origin, graph));
        path.removeAt(0);
      }
    }

    // Spezialbehandlung für Endpunkt (Destination)
    final NodeId lastNodeId = path.last;
    final Node? lastNode = graph.getNodeById(lastNodeId);
    final SegmentType lastNodeType =
        lastNode != null
            ? _determineSegmentType(lastNodeId, graph)
            : SegmentType.unknown;
    final bool hasDestination =
        lastNode != null &&
        (lastNodeType == SegmentType.room ||
            lastNodeType == SegmentType.toilet ||
            lastNodeType == SegmentType.exit);
    List<NodeId> destinationNodes = [];
    if (hasDestination && path.length >= 2) {
      if (path.length >= 3) {
        destinationNodes = [
          path[path.length - 3],
          path[path.length - 2],
          path.last,
        ];
        path.removeLast();
        path.removeLast();
      } else {
        destinationNodes = [path.first, path.last];
        path.removeLast();
      }
    }

    // Ermittlung der Breakpoints (kritische Punkte)
    final List<_PathBreakpoint> breakpoints = _findPathBreakpoints(path, graph);
    dev.log("Gefundene Breakpoints: ${breakpoints.length}");

    if (breakpoints.isEmpty) {
      SegmentType pathType = _determineSegmentType(path[0], graph);
      if (pathType == SegmentType.door) pathType = SegmentType.hallway;
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
        if (endIndex > 0 && startIndex >= endIndex) {
          startIndex = endIndex - 1;
        }
        if (endIndex >= startIndex && endIndex + 1 < path.length) {
          final List<NodeId> segmentNodes = path.sublist(
            startIndex,
            endIndex + 1,
          );
          if (segmentNodes.length >= 2 &&
              segmentNodes.last != lastProcessedNode) {
            final String direction = _calculateTurnDirection([
              path[endIndex - 1],
              path[endIndex],
              path[endIndex + 1],
            ], graph);
            final int doorCount =
                segmentNodes
                    .map((nodeId) => graph.getNodeById(nodeId))
                    .where((node) => node?.isDoor ?? false)
                    .length;
            final RouteSegment seg = _createSegment(
              segmentNodes,
              SegmentType.hallway,
              graph,
            );
            seg.metadata[MetadataKeys.direction] = direction;
            if (doorCount > 0) {
              seg.metadata[MetadataKeys.doorCount] = doorCount;
            }
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
        startIndex = endIndex;
      } else if (bp.type == BreakpointType.typeChange ||
          bp.type == BreakpointType.specialDoor) {
        if (endIndex > startIndex) {
          final List<NodeId> segmentNodes = path.sublist(startIndex, endIndex);
          if (segmentNodes.length >= 2 &&
              segmentNodes.last != lastProcessedNode) {
            SegmentType segType = _determineSegmentType(segmentNodes[0], graph);
            if (segType == SegmentType.door) segType = SegmentType.hallway;
            segments.add(_createSegment(segmentNodes, segType, graph));
            lastProcessedNode = segmentNodes.last;
          }
        }
        final NodeId bpNode = path[endIndex];
        SegmentType bpType = _determineSegmentType(bpNode, graph);
        if (bp.type == BreakpointType.specialDoor) {
          final Node? exitNode = graph.getNodeById(bpNode);
          if (exitNode != null) {
            final List<NodeId> exitNodes = [];
            if (endIndex > 0 && path[endIndex - 1] != lastProcessedNode) {
              exitNodes.add(path[endIndex - 1]);
            }
            exitNodes.add(bpNode);
            if (endIndex + 1 < path.length) {
              exitNodes.add(path[endIndex + 1]);
            }
            segments.add(_createSegment(exitNodes, SegmentType.exit, graph));
            lastProcessedNode = bpNode;
          }
        } else if (bpType == SegmentType.stairs ||
            bpType == SegmentType.elevator) {
          final List<NodeId> specialSegmentNodes = [];
          if (endIndex > 0 && path[endIndex - 1] != lastProcessedNode) {
            specialSegmentNodes.add(path[endIndex - 1]);
          }
          specialSegmentNodes.add(bpNode);
          if (endIndex + 1 < path.length) {
            specialSegmentNodes.add(path[endIndex + 1]);
          }
          if (specialSegmentNodes.length >= 2) {
            segments.add(_createSegment(specialSegmentNodes, bpType, graph));
            lastProcessedNode = bpNode;
          }
        }
        final bool nextIsTurn =
            (i + 1 < breakpoints.length &&
                breakpoints[i + 1].type == BreakpointType.turn);
        if (!nextIsTurn && (endIndex - startIndex) < 2) {
          startIndex = endIndex;
        } else if (nextIsTurn) {
          startIndex = endIndex;
        } else {
          startIndex = endIndex + 1;
        }
      }
    }

    // Letztes Segment verarbeiten
    if (startIndex < path.length) {
      final List<NodeId> lastSegmentNodes = path.sublist(startIndex);
      if (lastSegmentNodes.length >= 2) {
        final SegmentType lastNodeType = _determineSegmentType(
          lastSegmentNodes.last,
          graph,
        );
        if (lastNodeType == SegmentType.room ||
            lastNodeType == SegmentType.toilet ||
            lastNodeType == SegmentType.exit) {
          if (lastSegmentNodes.length > 2) {
            final List<NodeId> hallwayNodes = lastSegmentNodes.sublist(
              0,
              lastSegmentNodes.length - 1,
            );
            if (hallwayNodes.length >= 2) {
              segments.add(
                _createSegment(hallwayNodes, SegmentType.hallway, graph),
              );
            }
          }
        } else {
          SegmentType segType = _determineSegmentType(
            lastSegmentNodes[0],
            graph,
          );
          if (segType == SegmentType.door) segType = SegmentType.hallway;
          segments.add(_createSegment(lastSegmentNodes, segType, graph));
        }
      }
    }

    if (destinationNodes.isNotEmpty) {
      segments.add(
        _createSegment(destinationNodes, SegmentType.destination, graph),
      );
    }

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

    // Ausführliche Debug-Information für den Pfad
    dev.log("Suche Breakpoints in folgendem Pfad: ${path.join(' -> ')}");

    // Zuerst nach Abbiegungen suchen, da diese höchste Priorität haben
    for (int i = 1; i < path.length - 1; i++) {
      final NodeId prevId = path[i - 1];
      final NodeId currentId = path[i];
      final NodeId nextId = path[i + 1];

      if (nextId == path.last) {
        dev.log(
          "Überspringe Abbiegungsprüfung bei $i ($currentId): Nächster Knoten ist das Ziel",
        );

        continue;
      }

      // Knoten abrufen
      final prevNode = graph.getNodeById(prevId);
      final currentNode = graph.getNodeById(currentId);
      final nextNode = graph.getNodeById(nextId);

      if (prevNode == null || currentNode == null || nextNode == null) {
        continue;
      }

      // Ignoriere Türen nicht mehr für die Abbiegungserkennung
      // Fokus liegt auf der Geometrie, nicht auf dem Typ

      // Vektoren berechnen
      final dx1 = currentNode.x - prevNode.x;
      final dy1 = currentNode.y - prevNode.y;
      final dx2 = nextNode.x - currentNode.x;
      final dy2 = nextNode.y - currentNode.y;

      // Längen der Vektoren
      final length1 = sqrt(dx1 * dx1 + dy1 * dy1);
      final length2 = sqrt(dx2 * dx2 + dy2 * dy2);

      // Debug-Log für Vektoren
      dev.log(
        "Vektoren bei $i ($currentId): V1=($dx1,$dy1) Länge=$length1, V2=($dx2,$dy2) Länge=$length2",
      );

      // Reduzierter Schwellenwert für bessere Erkennung
      if (length1 > 0.5 && length2 > 0.5) {
        // Normalisierte Vektoren
        final nx1 = dx1 / length1;
        final ny1 = dy1 / length1;
        final nx2 = dx2 / length2;
        final ny2 = dy2 / length2;

        // Skalarprodukt für den Winkel
        final dotProduct = nx1 * nx2 + ny1 * ny2;

        // Kreuzprodukt für die Richtung
        final crossProduct = nx1 * ny2 - ny1 * nx2;

        // Überprüfe auf echte Abbiegung
        if (crossProduct.abs() > 0.1) {
          // Winkel zwischen den Vektoren berechnen
          final angle = acos(dotProduct.clamp(-1.0, 1.0)) * 180 / pi;

          // Debug-Ausgabe
          final direction = crossProduct > 0 ? "links" : "rechts";
          dev.log(
            "Knoten $i ($currentId): Winkel $angle° nach $direction (Dot: $dotProduct, Cross: $crossProduct)",
          );

          // Reduzierter Schwellenwert für bessere Erkennung
          if (angle > 10) {
            dev.log(
              "ABBIEGUNG erkannt bei $i ($currentId) (${currentNode.name}): $angle°",
            );
            breakpoints.add(_PathBreakpoint(i, BreakpointType.turn));
          }
        }
      }
    }

    // Dann nach Typwechseln suchen (niedrigere Priorität)
    for (int i = 1; i < path.length - 1; i++) {
      // Wenn dieser Knoten bereits als Abbiegung markiert ist, überspringen
      if (breakpoints.any(
        (bp) => bp.index == i && bp.type == BreakpointType.turn,
      )) {
        continue;
      }

      final NodeId prevId = path[i - 1];
      final NodeId currentId = path[i];
      final NodeId nextId = path[i + 1];

      // Knoten abrufen
      final currentNode = graph.getNodeById(currentId);
      if (currentNode == null) continue;

      // Typwechsel erkennen (Türen jetzt ausgenommen!)
      final SegmentType prevType = _determineSegmentType(prevId, graph);
      final SegmentType currentType = _determineSegmentType(currentId, graph);
      final SegmentType nextType = _determineSegmentType(nextId, graph);

      // WICHTIG: Alle Türen werden jetzt als hallway behandelt
      final SegmentType effectivePrevType =
          prevType == SegmentType.door ? SegmentType.hallway : prevType;
      final SegmentType effectiveCurrentType =
          currentType == SegmentType.door ? SegmentType.hallway : currentType;
      final SegmentType effectiveNextType =
          nextType == SegmentType.door ? SegmentType.hallway : nextType;

      // Debug-Log für Knotentypen
      dev.log(
        "Knotentypen bei $i ($currentId): Prev=$effectivePrevType, Current=$effectiveCurrentType, Next=$effectiveNextType",
      );

      // Bei Typwechsel (z.B. Flur → Treppe) handelt es sich um einen Breakpoint
      // Ignoriere Typwechsel zwischen hallway und door
      if (effectivePrevType != effectiveCurrentType ||
          effectiveCurrentType != effectiveNextType) {
        // Spezialfall: Notausgang oder Haupteingang
        if (currentNode.isEmergencyExit ||
            currentNode.hasProperty(propEntranceExit)) {
          dev.log(
            "Spezialtür-Breakpoint bei $i ($currentId): ${currentNode.name}",
          );
          breakpoints.add(_PathBreakpoint(i, BreakpointType.specialDoor));
          continue;
        }

        // Normaler Typwechsel (außer Tür -> Flur oder Flur -> Tür)
        dev.log(
          "Typwechsel-Breakpoint bei $i ($currentId): $effectivePrevType -> $effectiveCurrentType -> $effectiveNextType",
        );
        breakpoints.add(_PathBreakpoint(i, BreakpointType.typeChange));
      }
    }

    // Sortiere die Breakpoints nach ihrem Index
    breakpoints.sort((a, b) => a.index.compareTo(b.index));

    // Logge alle gefundenen Breakpoints
    if (breakpoints.isNotEmpty) {
      dev.log("Gefundene Breakpoints: ${breakpoints.length}");
      for (int i = 0; i < breakpoints.length; i++) {
        final bp = breakpoints[i];
        final nodeId = path[bp.index];
        final node = graph.getNodeById(nodeId);
        dev.log(
          "  Breakpoint $i: Index=${bp.index}, Typ=${bp.type}, Knoten=$nodeId (${node?.name ?? 'unbekannt'})",
        );
      }
    } else {
      dev.log("Keine Breakpoints gefunden im Pfad");
    }

    return breakpoints;
  }

  /// Optimierte Segment-Erstellung mithilfe der Metadata-Registry
  RouteSegment _createSegment(
    List<NodeId> nodes,
    SegmentType type,
    CampusGraph graph,
  ) {
    final Map<String, dynamic> metadata = {};
    dev.log(
      "Erstelle $type-Segment mit ${nodes.length} Knoten: ${nodes.join(', ')}",
    );

    // Nutzt den entsprechenden Metadata-Builder, wenn vorhanden.
    if (_metadataBuilders.containsKey(type)) {
      _metadataBuilders[type]!(metadata, nodes, graph);
    }

    // Gemeinsame Metadaten (z. B. Gebäude, Etage, Distanz)
    final Node? startNode = graph.getNodeById(nodes.first);
    if (startNode != null) {
      metadata['building'] = startNode.buildingName;
      metadata['floor'] = startNode.floorNumber;
    }
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

    // Durchgang durch Türen zählen
    int doorCount = 0;
    for (final nodeId in nodes) {
      final node = graph.getNodeById(nodeId);
      if (node != null && node.isDoor) {
        doorCount++;

        // Bei speziellen Türen zusätzliche Metadaten hinzufügen
        if (node.isEmergencyExit) {
          metadata['containsEmergencyExit'] = true;
        }
        if (node.hasProperty(propEntranceExit)) {
          metadata['containsEntranceExit'] = true;
        }
        if (node.isLocked) {
          metadata['containsLockedDoor'] = true;
        }
      }
    }

    if (doorCount > 0) {
      metadata[MetadataKeys.doorCount] = doorCount;
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

    // Define ordered type checks for clearer priority hierarchy
    final typeChecks = <bool Function(Node), SegmentType>{
      (n) => n.isRoom: SegmentType.room,
      (n) => n.isCorridor: SegmentType.hallway,
      (n) => n.isStaircase: SegmentType.stairs,
      (n) => n.isElevator: SegmentType.elevator,
      (n) => n.isToilet: SegmentType.toilet,
      (n) => n.isDoor: SegmentType.hallway, // Doors treated as hallways
      (n) => n.isEmergencyExit: SegmentType.exit,
    };

    // Return the first matching type or unknown
    for (final entry in typeChecks.entries) {
      if (entry.key(node)) return entry.value;
    }

    return SegmentType.unknown;
  }

  /// Calculates the turn direction for a list of nodes
  String _calculateTurnDirection(List<NodeId> nodes, CampusGraph graph) {
    // Constants for better readability
    const String straight = 'geradeaus';
    const minNodeCount = 3;
    const double minDirectionAngle = 10.0;
    const double slightTurnThreshold = 30.0;
    const double sharpTurnThreshold = 110.0;

    // Early return for insufficient nodes
    if (nodes.length < minNodeCount) return straight;

    // Get the three nodes needed for direction calculation
    final nodeTriple = _getNodeTriple(nodes, graph);
    if (nodeTriple == null) return straight;

    final (node1, node2, node3) = nodeTriple;

    // Calculate vectors between nodes
    final vectors = _calculateVectors(node1, node2, node3);
    final (dx1, dy1, dx2, dy2, length1, length2) = vectors;

    // Skip calculation if segments are too short
    if (length1 < minSegmentLength || length2 < minSegmentLength) {
      return straight;
    }

    // Calculate normalized vectors
    final normalized = _normalizeVectors(dx1, dy1, dx2, dy2, length1, length2);
    final (nx1, ny1, nx2, ny2) = normalized;

    // Calculate dot product and cross product
    final dotProduct = nx1 * nx2 + ny1 * ny2;
    final crossProduct = nx1 * ny2 - ny1 * nx2;

    // Calculate angle in degrees with direction from cross product
    final angle = acos(dotProduct.clamp(-1.0, 1.0)) * 180 / pi;
    final signedAngle = crossProduct >= 0 ? angle : -angle;

    // Determine direction based on angle
    if (signedAngle.abs() < minDirectionAngle) {
      return straight;
    } else if (signedAngle > 0) {
      // Left turns
      if (signedAngle < slightTurnThreshold) return "leicht links";
      if (signedAngle < sharpTurnThreshold) return "links";
      return "links halten";
    } else {
      // Right turns
      if (signedAngle > -slightTurnThreshold) return "leicht rechts";
      if (signedAngle > -sharpTurnThreshold) return "rechts";
      return "rechts halten";
    }
  }

  /// Gets a triple of nodes from the node list if they exist
  (Node, Node, Node)? _getNodeTriple(List<NodeId> nodes, CampusGraph graph) {
    final node1 = graph.getNodeById(nodes[0]);
    final node2 = graph.getNodeById(nodes[1]);
    final node3 = graph.getNodeById(nodes[2]);

    if (node1 == null || node2 == null || node3 == null) {
      return null;
    }

    return (node1, node2, node3);
  }

  /// Calculates vectors between three nodes
  (int, int, int, int, double, double) _calculateVectors(
    Node node1,
    Node node2,
    Node node3,
  ) {
    final dx1 = node2.x - node1.x;
    final dy1 = node2.y - node1.y;
    final dx2 = node3.x - node2.x;
    final dy2 = node3.y - node2.y;

    final length1 = sqrt(dx1 * dx1 + dy1 * dy1);
    final length2 = sqrt(dx2 * dx2 + dy2 * dy2);

    return (dx1, dy1, dx2, dy2, length1, length2);
  }

  /// Normalizes vectors for direction calculation
  (double, double, double, double) _normalizeVectors(
    int dx1,
    int dy1,
    int dx2,
    int dy2,
    double length1,
    double length2,
  ) {
    final nx1 = dx1 / length1;
    final ny1 = dy1 / length1;
    final nx2 = dx2 / length2;
    final ny2 = dy2 / length2;

    return (nx1, ny1, nx2, ny2);
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
  specialDoor, // Spezielle Tür (Notausgang, Haupteingang)
}

/// Repräsentiert einen kritischen Punkt im Pfad
class _PathBreakpoint {
  final int index; // Position im Pfad
  final BreakpointType type; // Art des Breakpoints

  _PathBreakpoint(this.index, this.type);

  @override
  String toString() => "Breakpoint($index, $type)";
}
