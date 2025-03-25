import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/services.dart' show rootBundle;
import 'package:way_to_class/constants/types.dart';
import 'package:way_to_class/core/generator/instruction_generator.dart';
import 'package:way_to_class/core/generator/path_generator.dart';
import 'package:way_to_class/core/generator/segment_generator.dart';
import 'package:way_to_class/core/models/campus_graph.dart';
import 'package:way_to_class/core/models/node.dart';
import 'package:way_to_class/core/models/route_segments.dart';
import 'package:way_to_class/core/utils/injection.dart';
import 'package:way_to_class/core/utils/load.dart';
import 'package:way_to_class/pages/home/home_page.dart';

/// Service für das Laden, Parsen und Verwalten des Campus-Graphen
class CampusGraphService {
  CampusGraph? currentGraph;

  // Routing-Generatoren
  final PathGenerator _pathGenerator = getIt<PathGenerator>();
  final SegmentsGenerator _segmentGenerator = getIt<SegmentsGenerator>();
  final InstructionGenerator _instructionGenerator =
      getIt<InstructionGenerator>();

  /// Verzeichnis der geladenen Gebäudedateien
  final List<String> _loadedFiles = [];

  /// Lädt alle verfügbaren JSON-Dateien aus dem Assets-Ordner und erstellt einen kombinierten Graphen
  Future<CampusGraph> loadGraph(String assetBasePath) async {
    if (currentGraph != null && _loadedFiles.isNotEmpty) {
      dev.log('Graph bereits geladen mit ${_loadedFiles.length} Dateien');
      return currentGraph!;
    }

    try {
      // Finde alle JSON-Dateien im Assets-Verzeichnis
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // Filtern der JSON-Dateien in den Assets
      final jsonFiles =
          manifestMap.keys
              .where(
                (String key) =>
                    key.startsWith('assets/') && key.endsWith('.json'),
              )
              .toList();

      dev.log('Gefundene JSON-Dateien: ${jsonFiles.length}');

      if (jsonFiles.isEmpty) {
        dev.log('Keine JSON-Dateien in den Assets gefunden!');
        // Fallback zur einzelnen Datei
        return _loadSingleGraph(assetBasePath);
      }

      // Kombinierter Graph mit allen Knoten
      final Map<NodeId, Node> allNodes = {};

      // Jede JSON-Datei laden und parsen
      for (final jsonFile in jsonFiles) {
        try {
          dev.log('Lade Graph aus: $jsonFile');
          final String jsonContent = await loadAsset(jsonFile);
          final nodes = _parseNodes(jsonContent);

          // Knoten zum Gesamtgraphen hinzufügen
          allNodes.addAll(nodes);
          _loadedFiles.add(jsonFile);

          dev.log('${nodes.length} Knoten aus $jsonFile geladen');
        } catch (e) {
          dev.log('Fehler beim Laden von $jsonFile: $e');
          // Fehler bei einer Datei überspringen und mit den anderen fortfahren
          continue;
        }
      }

      // Wenn keine gültigen Nodes geladen wurden, Fehler werfen
      if (allNodes.isEmpty) {
        throw Exception('Keine gültigen Knoten in den JSON-Dateien gefunden');
      }

      // Graphen mit allen kombinierten Knoten erstellen
      currentGraph = CampusGraph(allNodes);

      dev.log(
        'Kombinierter Campus-Graph mit ${currentGraph!.nodeCount} Knoten aus ${_loadedFiles.length} Dateien geladen',
      );
      return currentGraph!;
    } catch (e) {
      dev.log('Fehler beim Laden des kombinierten Graphen: $e');

      // Versuche es mit einer einzelnen Datei als Fallback
      return _loadSingleGraph(assetBasePath);
    }
  }

  /// Fallback-Methode: Lädt einen einzelnen Graphen aus dem angegebenen Pfad
  Future<CampusGraph> _loadSingleGraph(String assetPath) async {
    try {
      dev.log('Versuche Fallback-Laden aus: $assetPath');
      final String jsonStr = await loadAsset(assetPath);
      final Map<NodeId, Node> nodes = _parseNodes(jsonStr);

      if (nodes.isEmpty) {
        throw Exception('Keine gültigen Knoten in $assetPath gefunden');
      }

      currentGraph = CampusGraph(nodes);
      _loadedFiles.add(assetPath);

      dev.log(
        'Fallback-Graph mit ${currentGraph!.nodeCount} Knoten aus $assetPath geladen',
      );
      return currentGraph!;
    } catch (e) {
      dev.log('Auch Fallback-Laden fehlgeschlagen: $e');
      // Leeren Graphen zurückgeben als letzten Ausweg
      currentGraph = CampusGraph({});
      return currentGraph!;
    }
  }

  /// Parst JSON-Daten in eine Map von Knoten
  Map<NodeId, Node> _parseNodes(String jsonStr) {
    final Map<String, dynamic> json = jsonDecode(jsonStr);
    final Map<NodeId, Node> nodes = {};

    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        try {
          nodes[key] = Node.fromJson(key, value);
        } catch (e) {
          dev.log('Fehler beim Parsen von Knoten $key: $e');
          // Fehlerhaften Knoten überspringen
        }
      }
    });

    return nodes;
  }

  /// Holt einen Knoten anhand seines Namens
  NodeId? getNodeIdByName(String name) {
    return currentGraph?.getNodeIdByName(name);
  }

  /// Generiert einen Pfad zwischen Start und Ziel ohne Caching
  List<NodeId> getPath(NodeId startId, NodeId endId) {
    dev.log('Berechne Pfad von $startId zu $endId');

    // Berechne neuen Pfad
    if (currentGraph == null) {
      throw Exception('Graph nicht geladen');
    }

    final List<NodeId> path = _pathGenerator.calculatePath((
      startId,
      endId,
    ), currentGraph!);

    dev.log('Pfad gefunden mit ${path.length} Knoten: ${path.join(" -> ")}');
    return path;
  }

  /// Generiert Routensegmente aus einem Pfad ohne Caching
  List<RouteSegment> getRouteSegments(NodeId startId, NodeId endId) {
    dev.log('Generiere Routensegmente von $startId zu $endId');

    // Berechne neuen Pfad und konvertiere zu Segmenten
    final List<NodeId> path = getPath(startId, endId);

    if (path.isEmpty) {
      dev.log('Kein Pfad gefunden zwischen $startId und $endId');
      return [];
    }

    final List<RouteSegment> segments = _segmentGenerator.convertPath(
      path,
      currentGraph!,
    );

    // Ausführliche Logs für Debugging
    dev.log('${segments.length} Segmente generiert:');
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      dev.log(
        'Segment ${i + 1}: Typ=${segment.type}, Metadaten=${segment.metadata}',
      );

      // Besonders für Flursegmente mit Abbiegungen prüfen
      if (segment.type == SegmentType.hallway &&
          segment.metadata.containsKey('direction') &&
          segment.metadata['direction'] != 'geradeaus') {
        dev.log(
          'FLUR MIT ABBIEGUNG gefunden! Details: ${segment.metadata}',
          level: 800,
        );
      }
    }

    return segments;
  }

  /// Generiert Anweisungen aus Routensegmenten
  List<String> getInstructionsFromSegments(List<RouteSegment> segments) {
    if (segments.isEmpty) {
      dev.log('Keine Segmente für Anweisungen vorhanden');
      return [];
    }

    dev.log('Generiere Anweisungen für ${segments.length} Segmente');
    final instructions = _instructionGenerator.generateInstructions(segments);

    // Log der generierten Anweisungen
    for (int i = 0; i < instructions.length; i++) {
      dev.log('Anweisung ${i + 1}: ${instructions[i]}');
    }

    return instructions;
  }

  /// Kombinierte Methode für den gesamten Prozess
  List<String> getNavigationInstructions(NodeId startId, NodeId endId) {
    dev.log(
      'Generiere komplette Navigationsanweisungen von $startId zu $endId',
    );
    final segments = getRouteSegments(startId, endId);
    return getInstructionsFromSegments(segments);
  }

  /// Findet den nächsten Punkt vom angegebenen Typ
  String findNearestPointOfInterest(NodeId startId, PointOfInterestType type) {
    if (currentGraph == null) {
      throw Exception('Graph nicht geladen');
    }

    dev.log('Suche nächsten POI vom Typ $type ausgehend von $startId');

    String result = "";
    switch (type) {
      case PointOfInterestType.toilet:
        result = currentGraph!.findNearestBathroomId(startId);
        break;
      case PointOfInterestType.exit:
        result = currentGraph!.findNearestEmergencyExitId(startId);
        break;
      case PointOfInterestType.canteen:
        result = currentGraph!.findNearestCanteenId(startId);
        break;
    }

    dev.log('Gefundenes POI für $type: $result');
    return result;
  }

  /// Prüft, ob ein Graph geladen ist
  bool get hasGraph => currentGraph != null;

  /// Gibt Informationen über die geladenen Dateien zurück
  List<String> getLoadedFiles() {
    return List.from(_loadedFiles);
  }

  /// Löscht die Caches und erzwingt das Neuladen des Graphen
  Future<void> reloadGraph(String assetBasePath) async {
    _loadedFiles.clear();
    currentGraph = null;
    await loadGraph(assetBasePath);
  }
}
