// NavigationHelper-Erweiterung für strukturiertes Caching
import 'dart:developer' show log;
import 'dart:math' show atan2, pi;

import 'package:way_to_class/constants/node_constants.dart';
import 'package:way_to_class/constants/segment_constants.dart';
import 'package:way_to_class/constants/template_constants.dart';
import 'package:way_to_class/core/components/directions.dart';
import 'package:way_to_class/core/models/node.dart';
import 'package:way_to_class/core/models/route_segment.dart';
import 'package:way_to_class/core/utils/injection.dart';
import 'package:way_to_class/core/utils/transition_manager.dart';

import 'graph.dart' show Graph;

class NavigationHelper {
  final _templateManager = getIt<TransitionTemplateManager>();

  // Neue Methode, die RouteSegments zurückgibt statt Strings
  List<RouteSegment> generateRouteStructure(Graph graph, List<String> path) {
    if (path.length < 2) return [];

    final List<RouteSegment> segments = [];
    final List<Node> currentPath =
        path.map((id) => graph.getNodeById(id)).whereType<Node>().toList();

    // Add destination info if applicable
    final Node? endNode = graph.getNodeById(path.last);
    if (endNode != null && endNode.isRoom) {
      segments.add(
        RouteSegment(segRoomEntry, {
          'nodeId': endNode.id,
          'nodeName': endNode.name,
          'buildingName': endNode.buildingName,
          'floorNumber': endNode.floorNumber,
        }),
      );
    }

    // Keep track of corridor segments for merging
    final List<Node> currentCorridorSegment = [];
    Node? lastProcessedNode;

    // Process all nodes in path
    for (int i = 0; i < path.length; i++) {
      final Node? current = graph.getNodeById(path[i]);
      if (current == null) continue;

      // Skip if it's the same as last processed node
      if (lastProcessedNode != null && current.id == lastProcessedNode.id) {
        continue;
      }

      // If we're in a corridor
      if (current.isCorridor) {
        currentCorridorSegment.add(current);

        // Check if this is the end of the path or next node is not a corridor
        if (i == path.length - 1 ||
            graph.getNodeById(path[i + 1])?.isCorridor == false) {
          // Process the corridor segment
          segments.addAll(
            _processCorridorSegmentToStructure(
              graph,
              currentCorridorSegment,
              path,
              i,
            ),
          );
          currentCorridorSegment.clear();
        }
      } else {
        // If there was a corridor segment before, process it
        if (currentCorridorSegment.isNotEmpty) {
          segments.addAll(
            _processCorridorSegmentToStructure(
              graph,
              currentCorridorSegment,
              path,
              i - 1,
            ),
          );
          currentCorridorSegment.clear();
        }

        // Process non-corridor node
        if (i < path.length - 1) {
          final Node? next = graph.getNodeById(path[i + 1]);
          if (next != null) {
            segments.add(
              _processNonCorridorNodeToStructure(current, next, currentPath, i),
            );
          }
        } else {
          // Final destination
          if (i > 0) {
            // Wir benötigen mindestens 2 Knoten vor dem Ziel, um die Annäherungsrichtung zu bestimmen
            if (i >= 2) {
              final Node twoNodesBack = currentPath[i - 2];
              final Node previousNode = currentPath[i - 1];
              final Node current = currentPath[i];

              // Verwende die Funktion zur Bestimmung der relativen Position
              final Direction position = _determineRelativePosition(
                twoNodesBack,
                previousNode,
                current,
              );

              final String positionText;
              switch (position) {
                case Direction.links:
                  positionText = "links von dir";
                  break;
                case Direction.rechts:
                  positionText = "rechts von dir";
                  break;
                case Direction.geradeaus:
                  positionText = "direkt vor dir";
                  break;
              }

              // Parameter für das Segment vorbereiten - jetzt mit direkter Bit-Typ-Übertragung
              final Map<String, dynamic> params = {
                'nodeTypeInt':
                    current.type, // Direkt den ganzen Integer speichern
                'nodeId': current.id,
                'nodeName': current.name,
                'position': positionText,
              };

              segments.add(RouteSegment(segDestination, params));
            } else {
              // Fall back to the simple vector approach if we don't have enough nodes
              final Node previousNode = currentPath[i - 1];
              final Node current = currentPath[i];

              // Die Bewegungsrichtung bestimmen - vereinfachte Version
              final int vx = current.x - previousNode.x;
              final int vy = current.y - previousNode.y; // Y-Achse umkehren

              final Direction position;
              if (vx.abs() > vy.abs()) {
                position = vx > 0 ? Direction.rechts : Direction.links;
              } else {
                position = vy > 0 ? Direction.geradeaus : Direction.links;
              }

              final String positionText = _getDirectionText(position);

              String nodeType;
              if (current.isRoom) {
                nodeType = "room";
              } else if (current.isStaircase) {
                nodeType = "staircase";
              } else if (current.isElevator) {
                nodeType = "elevator";
              } else if (current.id.contains('Notausgang')) {
                nodeType = "emergency";
              } else {
                nodeType = "other";
              }

              segments.add(
                RouteSegment(segDestination, {
                  'nodeId': current.id,
                  'nodeName': current.name,
                  'nodeType': nodeType,
                  'position': positionText,
                }),
              );
            }
          }
        }
      }

      lastProcessedNode = current;
    }

    return segments;
  }

  // Konvertiert einen Flur-Abschnitt in Route-Segmente
  List<RouteSegment> _processCorridorSegmentToStructure(
    Graph graph,
    List<Node> corridorSegment,
    List<String> fullPath,
    int currentIndex,
  ) {
    if (corridorSegment.length < 2) return [];

    final List<RouteSegment> segmentStructure = [];

    // Detect turns within the corridor segment
    final List<(int, Direction)> turns = []; // (index, direction)

    // Kurven im Flur erkennen
    for (int i = 1; i < corridorSegment.length - 1; i++) {
      final Node a = corridorSegment[i - 1];
      final Node b = corridorSegment[i];
      final Node c = corridorSegment[i + 1];

      final Direction direction = _determineRelativePosition(a, b, c);

      // Only add turns that aren't "geradeaus"
      if (direction != Direction.geradeaus) {
        turns.add((i, direction));
      }
    }

    // Verhindere, dass die gleiche Landmarke für mehrere Turns verwendet wird
    final Set<String> usedLandmarks = {};

    // If no turns, just add one instruction for the whole segment
    if (turns.isEmpty) {
      final double distance = _calculatePathDistance(corridorSegment);
      final int steps = _convertDistanceToSteps(distance);

      // Check if we're reaching a destination
      String? destinationDesc;
      if (currentIndex + 1 < fullPath.length) {
        final Node? nextNode = graph.getNodeById(fullPath[currentIndex + 1]);
        if (nextNode != null && !nextNode.isCorridor) {
          destinationDesc = _getNodeDescription(nextNode, isDestination: true);
        }
      }

      // Verwende Bitoperationen für den SegmentType
      int segType = segCorridorStraight;
      // Füge Eigenschaft hinzu, wenn es das erste Segment ist
      if (currentIndex == 0 ||
          graph.getNodeById(fullPath[currentIndex - 1])?.isCorridor == false) {
        segType |= segPropFirst;
      }

      segmentStructure.add(
        RouteSegment(segType, {
          'steps': steps,
          'isFirstSegment':
              (segType & segPropFirst) != 0, // Für Abwärtskompatibilität
          'destinationDesc': destinationDesc,
        }),
      );

      return segmentStructure;
    }

    // Process segments between turns
    int lastSegmentStart = 0;

    for (int i = 0; i < turns.length; i++) {
      final (int turnIndex, Direction turnDirection) = turns[i];

      if (turnIndex > lastSegmentStart) {
        // Generate instruction for segment before turn
        final subSegment = corridorSegment.sublist(
          lastSegmentStart,
          turnIndex + 1,
        );
        final double distance = _calculatePathDistance(subSegment);
        final int steps = _convertDistanceToSteps(distance);

        // Find the nearest landmark at the turn point for better orientation
        final Node turnNode = corridorSegment[turnIndex];
        final Node? landmark = graph.findNearestRoomStairElevator(turnNode);
        String? landmarkText;

        if (landmark != null) {
          final double landmarkDistance = Graph.computeDistance(
            turnNode,
            landmark,
          );
          if (landmarkDistance < 10 && !usedLandmarks.contains(landmark.id)) {
            // Only use landmarks that are reasonably close
            landmarkText = " auf Höhe von ${_getNodeDescription(landmark)}";
            usedLandmarks.add(landmark.id); // Mark this landmark as used
          }
        }

        // Prüfen, ob direkt nach dieser Kurve eine weitere kommt
        bool hasFollowingTurn = false;
        String? nextDirection;
        if (i < turns.length - 1 && turns[i + 1].$1 == turnIndex + 1) {
          hasFollowingTurn = true;
          nextDirection = _getDirectionText(turns[i + 1].$2);
        }

        // Bitmasken für Eigenschaften verwenden
        int segType = segCorridorTurn;
        if (lastSegmentStart == 0) segType |= segPropFirst;
        if (hasFollowingTurn) segType |= segPropFollowing;
        if (landmarkText != null) segType |= segPropLandmark;
        if (steps < 3) segType |= segPropShort;

        segmentStructure.add(
          RouteSegment(segType, {
            'direction': _getDirectionText(turnDirection),
            'steps': steps,
            'landmarkText': landmarkText,
            'isFirstSegment':
                (segType & segPropFirst) != 0, // Für Abwärtskompatibilität
            'hasFollowingTurn': hasFollowingTurn,
            'nextDirection': nextDirection,
          }),
        );
      } else {
        // Direkt aufeinanderfolgende Kurven
        int segType = segCorridorTurn;
        if (i == 0) segType |= segPropFirst;

        segmentStructure.add(
          RouteSegment(segType, {
            'direction': _getDirectionText(turnDirection),
            'hasFollowingTurn': false,
          }),
        );
      }

      lastSegmentStart = turnIndex + 1;
    }

    // Add final segment after last turn
    if (lastSegmentStart < corridorSegment.length - 1) {
      final subSegment = corridorSegment.sublist(lastSegmentStart);
      final double distance = _calculatePathDistance(subSegment);
      final int steps = _convertDistanceToSteps(distance);

      // Check if we're reaching a destination
      String? destinationDesc;
      if (currentIndex + 1 < fullPath.length) {
        final Node? nextNode = graph.getNodeById(fullPath[currentIndex + 1]);
        if (nextNode != null && !nextNode.isCorridor) {
          destinationDesc = _getNodeDescription(nextNode, isDestination: true);
        }
      }

      segmentStructure.add(
        RouteSegment(segCorridorStraight, {
          'steps': steps,
          'isFirstSegment': false,
          'destinationDesc': destinationDesc,
        }),
      );
    }

    return segmentStructure;
  }

  // Process a non-corridor node to structure
  RouteSegment _processNonCorridorNodeToStructure(
    Node current,
    Node next,
    List<Node> currentPath,
    int currentIndex,
  ) {
    // Room to corridor with direction detection
    if (current.isRoom && next.isCorridor) {
      String direction = "geradeaus"; // Standard-Richtung als Fallback

      if (currentIndex + 2 < currentPath.length) {
        final Node corridorNode = next;
        final Node nextNode = currentPath[currentIndex + 2];

        // Direction bestimmen
        final Direction dirEnum = _determineRelativePosition(
          current,
          corridorNode,
          nextNode,
        );

        direction = _getDirectionText(dirEnum);
      }

      // Eigenschaften ergänzen
      int segType = segRoomExit;
      if (currentIndex == 0) segType |= segPropFirst;

      return RouteSegment(segType, {
        'roomId': current.id,
        'direction': direction, // Immer eine Richtung setzen
        'sourceType': current.type,
        'targetType': next.type,
      });
    }
    // Other room transitions
    else if (current.isRoom) {
      return RouteSegment(segRoomExit, {
        'roomId': current.id,
        'sourceType': current.type,
        'targetType': next.type,
        'targetDesc': _getNodeDescription(next, isDestination: true),
      });
    }
    // Door transitions
    else if (current.isDoor) {
      return RouteSegment(segDoorPass, {
        'sourceType': current.type,
        'targetType': next.type,
        'targetId': next.isRoom ? next.id : null,
        'targetDesc': _getNodeDescription(next, isDestination: true),
      });
    }
    // Staircase/Elevator transitions
    else if (current.isStaircase || current.isElevator) {
      if (next.type == current.type) {
        if (_isFloorTransition(current, next)) {
          final int currentFloor = current.floorNumber;
          final int nextFloor = next.floorNumber;
          final int floorDiff = nextFloor - currentFloor;
          final bool goingUp = floorDiff > 0;

          // Kombiniere Basis-, Untertyp- und Eigenschaften mit Bitoperationen
          int segType;
          if (current.isStaircase) {
            segType = goingUp ? segStairsUp : segStairsDown;
          } else {
            segType = goingUp ? segElevatorUp : segElevatorDown;
          }

          return RouteSegment(segType, {
            'floors': floorDiff.abs(),
            'startFloor': currentFloor,
            'endFloor': nextFloor,
            'sourceType': current.type,
            'targetType': next.type,
          });
        }
      }
    } else if ((current.isToilet || current.isStaircase) && next.isCorridor) {
      return RouteSegment(segFacilityExit, {
        'sourceType': current.type,
        'targetType': next.type,
        'targetDesc': _getNodeDescription(next, isDestination: true),
      });
    }

    // Default case
    return RouteSegment(segRoomExit, {
      'sourceType': current.type,
      'targetType': next.type,
      'targetDesc': _getNodeDescription(next, isDestination: true),
    });
  }

  // Process corridor segments and generate directions
  List<String> generateNavigationInstructions(Graph graph, List<String> path) {
    if (path.length < 2) return [];

    final List<String> instructions = [];
    final List<Node> currentPath =
        path.map((id) => graph.getNodeById(id)).whereType<Node>().toList();

    // If first node is a room, add starting instruction
    final Node? startNode = graph.getNodeById(path.first);
    if (startNode != null && startNode.isRoom) {
      // Wir haben die Startrauminfo auskommentiert
      //instructions.add('Starte in Raum ${startNode.id}.');
    }

    final Node? endNode = graph.getNodeById(path.last);
    log('Endknoten: ${endNode?.data}');
    if (endNode != null && endNode.isRoom) {
      int context = templateInfo;
      Map<String, dynamic> params = {
        'name': _templateManager.formatNameForNodeType(
          endNode.type,
          endNode.id,
        ),
        'building': endNode.buildingName,
        'floor': endNode.floorNumber,
      };

      final template = _templateManager.findBestTemplate(
        context,
        endNode.type,
        0,
      );
      instructions.add(template.apply(params));
    }

    // Keep track of corridor segments for merging
    final List<Node> currentCorridorSegment = [];
    Node? lastProcessedNode;

    // Process all nodes in path
    for (int i = 0; i < path.length; i++) {
      final Node? current = graph.getNodeById(path[i]);
      if (current == null) continue;

      // Skip if it's the same as last processed node
      if (lastProcessedNode != null && current.id == lastProcessedNode.id) {
        continue;
      }

      // If we're in a corridor
      if (current.isCorridor) {
        currentCorridorSegment.add(current);

        // Check if this is the end of the path or next node is not a corridor
        if (i == path.length - 1 ||
            graph.getNodeById(path[i + 1])?.isCorridor == false) {
          // Process the corridor segment
          instructions.addAll(
            _processCorridorSegment(graph, currentCorridorSegment, path, i),
          );
          currentCorridorSegment.clear();
        }
      } else {
        // If there was a corridor segment before, process it
        if (currentCorridorSegment.isNotEmpty) {
          instructions.addAll(
            _processCorridorSegment(graph, currentCorridorSegment, path, i - 1),
          );
          currentCorridorSegment.clear();
        }

        // Process non-corridor node
        if (i < path.length - 1) {
          final Node? next = graph.getNodeById(path[i + 1]);
          if (next != null) {
            instructions.add(
              _processNonCorridorNode(current, next, currentPath, i),
            );
          }
        } else {
          // Final destination
          if (i > 0) {
            // Wir benötigen mindestens 2 Knoten vor dem Ziel, um die Annäherungsrichtung zu bestimmen
            if (i >= 2) {
              final Node twoNodesBack = currentPath[i - 2];
              final Node previousNode = currentPath[i - 1];
              final Node current = currentPath[i];

              final Direction position = _determineRelativePosition(
                twoNodesBack,
                previousNode,
                current,
              );

              final String positionText =
                  position == Direction.links
                      ? "links von dir"
                      : (position == Direction.rechts
                          ? "rechts von dir"
                          : "direkt vor dir");

              // Destinationstemplate mit Bitmasken
              int context = templateDestination;
              int properties = 0;

              Map<String, dynamic> params = {
                'name': current.id,
                'position': positionText,
                'locationType': _templateManager.getArticleForNodeType(
                  current.type,
                  true,
                ),
              };

              final template = _templateManager.findBestTemplate(
                context,
                current.type,
                properties,
              );
              instructions.add(template.apply(params));
            } else {
              // Fallback für einfachere Positionsbestimmung
              final Node previousNode = currentPath[i - 1];
              final Node current = currentPath[i];

              // Bestimme Richtung mit einfachem Vektor
              final Direction position = _determineSimpleDirection(
                previousNode,
                current,
              );
              final String positionText =
                  position == Direction.links
                      ? "links von dir"
                      : (position == Direction.rechts
                          ? "rechts von dir"
                          : "direkt vor dir");

              // Ähnliches Template wie oben
              int context = templateDestination;
              int properties = 0;

              Map<String, dynamic> params = {
                'name': current.id,
                'position': positionText,
                'locationType': _templateManager.getArticleForNodeType(
                  current.type,
                  false,
                ),
              };

              final template = _templateManager.findBestTemplate(
                context,
                current.type,
                properties,
              );
              instructions.add(template.apply(params));
            }
          }
        }
      }

      lastProcessedNode = current;
    }

    return instructions;
  }

  // Füge diese Methode zur NavigationHelper-Klasse hinzu:

  // Einfache Richtungsbestimmung basierend auf einem Vektor zwischen zwei Knoten
  Direction _determineSimpleDirection(Node start, Node end) {
    // Berechne den Vektor von start zu end
    final int vx = end.x - start.x;
    final int vy = end.y - start.y;

    // Bestimme die Hauptrichtung basierend auf dem größeren Wert
    if (vx.abs() > vy.abs()) {
      return vx > 0 ? Direction.rechts : Direction.links;
    } else {
      return vy > 0 ? Direction.geradeaus : Direction.links;
    }
  }

  // Process a corridor segment to identify turns
  List<String> _processCorridorSegment(
    Graph graph,
    List<Node> corridorSegment,
    List<String> fullPath,
    int currentIndex,
  ) {
    if (corridorSegment.length < 2) return [];

    final List<String> segmentInstructions = [];
    final List<(int, Direction)> turns = [];

    final Set<String> usedLandmarks = {};

    // Keine Kurven - einfacher Weg
    if (turns.isEmpty) {
      final double distance = _calculatePathDistance(corridorSegment);
      final int steps = _convertDistanceToSteps(distance);

      // Prüfe, ob wir ein Ziel erreichen
      String? destinationDesc;
      if (currentIndex + 1 < fullPath.length) {
        final Node? nextNode = graph.getNodeById(fullPath[currentIndex + 1]);
        if (nextNode != null && !nextNode.isCorridor) {
          destinationDesc = _getNodeDescription(nextNode, isDestination: true);
        }
      }

      final bool isFirstSegment =
          currentIndex == 0 ||
          graph.getNodeById(fullPath[currentIndex - 1])?.isCorridor == false;

      // Verwende das neue Template-System
      segmentInstructions.add(
        _templateManager.getCorridorTemplate(
          isFirstSegment: isFirstSegment,
          hasLandmark: false,
          hasFollowingTurn: false,
          hasTurn: false,
          hasDestination: destinationDesc != null,
          steps: steps,
          destinationDesc: destinationDesc,
        ),
      );

      return segmentInstructions;
    }

    // Mit Kurven - Code für Segmente zwischen Kurven
    int lastSegmentStart = 0;

    for (int i = 0; i < turns.length; i++) {
      final (int turnIndex, Direction turnDirection) = turns[i];

      if (turnIndex > lastSegmentStart) {
        // Segment vor der Kurve verarbeiten
        final subSegment = corridorSegment.sublist(
          lastSegmentStart,
          turnIndex + 1,
        );
        final int steps = _convertDistanceToSteps(
          _calculatePathDistance(subSegment),
        );

        // Landmark finden
        final Node turnNode = corridorSegment[turnIndex];
        String? landmarkText = _findLandmarkText(
          graph,
          turnNode,
          usedLandmarks,
        );

        final bool hasFollowingTurn =
            i < turns.length - 1 && turns[i + 1].$1 == turnIndex + 1;
        final bool isFirstSegment = lastSegmentStart == 0;

        segmentInstructions.add(
          _templateManager.getCorridorTemplate(
            isFirstSegment: isFirstSegment,
            hasLandmark: landmarkText != null,
            hasFollowingTurn: hasFollowingTurn,
            hasTurn: true,
            hasDestination: false,
            steps: steps,
            landmarkText: landmarkText,
            direction: _getDirectionText(turnDirection),
            nextDirection:
                hasFollowingTurn ? _getDirectionText(turns[i + 1].$2) : null,
          ),
        );
      } else if (i == 0) {
        // Einzelne Kurve ohne vorheriges Segment
        segmentInstructions.add(
          _templateManager.getCorridorTemplate(
            isFirstSegment: true,
            hasLandmark: false,
            hasFollowingTurn: false,
            hasTurn: true,
            hasDestination: false,
            steps: 0,
            direction: _getDirectionText(turnDirection),
          ),
        );
      }

      lastSegmentStart = turnIndex + 1;
    }

    // Segment nach der letzten Kurve
    if (lastSegmentStart < corridorSegment.length - 1) {
      final subSegment = corridorSegment.sublist(lastSegmentStart);
      final int steps = _convertDistanceToSteps(
        _calculatePathDistance(subSegment),
      );

      // Prüfe, ob wir ein Ziel erreichen
      String? destinationDesc;
      if (currentIndex + 1 < fullPath.length) {
        final Node? nextNode = graph.getNodeById(fullPath[currentIndex + 1]);
        if (nextNode != null && !nextNode.isCorridor) {
          destinationDesc = _getNodeDescription(nextNode, isDestination: true);
        }
      }

      segmentInstructions.add(
        _templateManager.getCorridorTemplate(
          isFirstSegment: false,
          hasLandmark: false,
          hasFollowingTurn: false,
          hasTurn: false,
          hasDestination: destinationDesc != null,
          steps: steps,
          destinationDesc: destinationDesc,
        ),
      );
    }

    return segmentInstructions;
  }

  // Hilfsfunktion zum Finden eines Landmarks
  String? _findLandmarkText(
    Graph graph,
    Node turnNode,
    Set<String> usedLandmarks,
  ) {
    final Node? landmark = graph.findNearestRoomStairElevator(turnNode);
    if (landmark != null) {
      final double landmarkDistance = Graph.computeDistance(turnNode, landmark);
      if (landmarkDistance < 10 && !usedLandmarks.contains(landmark.id)) {
        usedLandmarks.add(landmark.id);
        return _getNodeDescription(landmark);
      }
    }
    return null;
  }

  // Convert distance into more realistic step counts (around 2/3 of the coordinate distance)
  int _convertDistanceToSteps(double distance) {
    // Assume 1 step is about 0.8 meters (meters are not entirely accurate)
    return (distance * 0.8).round();
  }

  // Calculate the total distance along a path of nodes
  double _calculatePathDistance(List<Node> nodes) {
    double totalDistance = 0;

    for (int i = 0; i < nodes.length - 1; i++) {
      totalDistance += Graph.computeDistance(nodes[i], nodes[i + 1]);
    }

    return totalDistance;
  }

  // Process a non-corridor node
  // return instruction
  String _processNonCorridorNode(
    Node current,
    Node next,
    List<Node> currentPath,
    int currentIndex,
  ) {
    // Direkter Zugriff auf die Typbitmaske für effizientere Vergleiche
    int currentType = current.type;
    int nextType = next.type;

    // Room to corridor with direction detection
    if ((currentType & typeMask) == typeRoom &&
        (nextType & typeMask) == typeCorridor) {
      int context = templateExit | templateForRoom | templateForCorridor;
      int properties = 0;
      Map<String, dynamic> params = {'name': current.id};

      if (currentIndex + 2 < currentPath.length) {
        final Node corridorNode = next;
        final Node nextNode = currentPath[currentIndex + 2];
        final Direction direction = _determineRelativePosition(
          current,
          corridorNode,
          nextNode,
        );

        params['direction'] = _getDirectionText(direction);
      }

      // Bestes Template finden basierend auf dem Kontext
      final template = _templateManager.findBestTemplate(
        context,
        currentType,
        properties,
      );
      return template.apply(params);
    }
    // Room to other destination
    else if ((currentType & typeMask) == typeRoom) {
      int context = templateExit | templateForRoom;
      int properties = 0;
      Map<String, dynamic> params = {
        'name': current.id,
        'nextAction':
            'gehe zu ${_getNodeDescription(next, isDestination: true)}',
      };

      final template = _templateManager.findBestTemplate(
        context,
        currentType,
        properties,
      );
      return template.apply(params);
    }
    // Door transitions
    else if ((currentType & typeMask) == typeDoor) {
      int context = templateEntry;
      int properties = 0;
      String targetDesc =
          (nextType & typeMask) == typeRoom
              ? next.id
              : _getNodeDescription(next, isDestination: true);

      Map<String, dynamic> params = {'name': targetDesc};

      final template = _templateManager.findBestTemplate(
        context,
        nextType,
        properties,
      );
      return template.apply(params);
    }
    // Staircase/Elevator transitions
    else if ((currentType & typeMask) == typeStaircase ||
        (currentType & typeMask) == typeElevator) {
      if (next.type == current.type) {
        if (_isFloorTransition(current, next)) {
          int context = templateTravel;
          int floorDiff = next.floorNumber - current.floorNumber;
          bool goingUp = floorDiff > 0;

          int properties =
              goingUp ? templateDirectionUp : templateDirectionDown;

          // Korrekte Art (Treppe oder Aufzug) wählen
          int nodeTypeBits =
              (currentType & typeMask) == typeStaircase
                  ? templateForStairs
                  : templateForElevator;

          Map<String, dynamic> params = {
            'floors':
                floorDiff.abs() == 1
                    ? "eine Etage"
                    : "${floorDiff.abs()} Etagen",
          };

          final template = _templateManager.findBestTemplate(
            context | nodeTypeBits,
            currentType,
            properties,
          );
          return template.apply(params);
        }
      }
      // Von Treppe/Aufzug zum Flur
      else if ((nextType & typeMask) == typeCorridor) {
        int context = templateExit;

        // Auswählen zwischen Treppe und Aufzug
        int sourceTypeBits =
            (currentType & typeMask) == typeStaircase
                ? templateForStairs
                : templateForElevator;

        String sourceName =
            (currentType & typeMask) == typeStaircase
                ? "die Treppe"
                : "den Aufzug";

        Map<String, dynamic> params = {
          'name': sourceName,
          'nextAction': 'gehe in den Flur',
        };

        final template = _templateManager.findBestTemplate(
          context | sourceTypeBits | templateForCorridor,
          currentType,
          0,
        );
        return template.apply(params);
      }
      // Von Treppe/Aufzug zu einem anderen Ziel
      else {
        int context = templateExit;
        int sourceTypeBits =
            (currentType & typeMask) == typeStaircase
                ? templateForStairs
                : templateForElevator;

        String sourceName =
            (currentType & typeMask) == typeStaircase
                ? "die Treppe"
                : "den Aufzug";

        Map<String, dynamic> params = {
          'name': sourceName,
          'nextAction':
              'gehe zu ${_getNodeDescription(next, isDestination: true)}',
        };

        final template = _templateManager.findBestTemplate(
          context | sourceTypeBits,
          currentType,
          0,
        );
        return template.apply(params);
      }
    }

    // Default: Go to target
    int context = templateExit;
    Map<String, dynamic> params = {
      'name': _getNodeDescription(current),
      'nextAction': 'gehe zu ${_getNodeDescription(next, isDestination: true)}',
    };

    final template = _templateManager.findBestTemplate(context, currentType, 0);
    return template.apply(params);
  }

  // Get description text for a node
  String _getNodeDescription(Node node, {bool isDestination = false}) {
    switch (node.type) {
      case typeRoom:
        return 'Raum ${node.id}';
      case typeStaircase:
        return isDestination ? 'zur Treppe' : 'der Treppe';
      case typeElevator:
        return isDestination ? 'zum Fahrstuhl' : 'dem Fahrstuhl';
      case typeDoor:
        return isDestination ? 'zur Tür' : 'der Tür';
      case typeCorridor:
        return 'dem Flur';
      default:
        return node.id;
    }
  }

  // Get text representation of a direction
  String _getDirectionText(Direction direction) {
    switch (direction) {
      case Direction.links:
        return 'links';
      case Direction.rechts:
        return 'rechts';
      case Direction.geradeaus:
        return 'geradeaus';
    }
  }

  // Check if there's a floor transition between two nodes
  bool _isFloorTransition(Node current, Node next) {
    if ((current.isStaircase && next.isStaircase) ||
        (current.isElevator && next.isElevator)) {
      return current.floorCode != next.floorCode;
    }
    return false;
  }

  // Diese Funktion soll die finale Position eines Raums relativ zur aktuellen Bewegungsrichtung feststellen
  Direction _determineRelativePosition(
    Node previous,
    Node current,
    Node target,
  ) {
    // Erst bestimmen wir den Bewegungsvektor des Nutzers (von wo er kommt und wohin er geht)
    final int dirX = current.x - previous.x;
    final int dirY = current.y - previous.y;

    // Dann den Vektor vom aktuellen Punkt zum Ziel
    final int targetX = target.x - current.x;
    final int targetY = target.y - current.y;

    //log('Bewegungsvektor: ($dirX, $dirY), Zielvektor: ($targetX, $targetY)');

    // Winkel zwischen den beiden Vektoren berechnen (in Rad)
    final double angle = atan2(
      dirX * targetY - dirY * targetX,
      dirX * targetX + dirY * targetY,
    );

    // Winkel in Grad umrechnen
    final double angleDeg = angle * 180 / pi;

    //log('Winkel zwischen Bewegungsrichtung und Ziel: $angleDeg Grad');

    // Winkelinterpretation:
    // Wenn der Winkel nahe 0 ist, liegt das Ziel geradeaus
    // Wenn er positiv ist, liegt das Ziel rechts
    // Wenn er negativ ist, liegt das Ziel links
    if (angleDeg.abs() < 20) {
      return Direction.geradeaus;
    } else if (angleDeg > 0) {
      return Direction.links;
    } else {
      return Direction.rechts;
    }
  }
}
