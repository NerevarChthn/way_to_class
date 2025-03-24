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

  // Cache-Struktur für Routen und Segmente
  final Map<String, List<NodeId>> _pathCache = {};
  final Map<String, List<RouteSegment>> _segmentCache = {};

  /// Cache für Node-Namen zu IDs für schnellere Suche
  final Map<String, NodeId> _nameToIdCache = {};

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
      _updateNameCache(allNodes);

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
      _updateNameCache(nodes);
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

  /// Aktualisiert den Namen-zu-ID-Cache
  void _updateNameCache(Map<NodeId, Node> nodes) {
    for (var node in nodes.values) {
      if (node.name.isNotEmpty) {
        _nameToIdCache[node.name] = node.id;
      }
    }
    dev.log(
      'Name-zu-ID-Cache mit ${_nameToIdCache.length} Einträgen aktualisiert',
    );
  }

  /// Holt einen Knoten anhand seines Namens, mit Cache-Nutzung
  NodeId? getNodeIdByName(String name) {
    // Zuerst im Cache nachsehen
    if (_nameToIdCache.containsKey(name)) {
      return _nameToIdCache[name];
    }

    // Falls nicht im Cache, im Graphen suchen
    final nodeId = currentGraph?.getNodeIdByName(name);

    // Wenn gefunden, zum Cache hinzufügen
    if (nodeId != null) {
      _nameToIdCache[name] = nodeId;
    }

    return nodeId;
  }

  /// Generiert einen Pfad zwischen Start und Ziel mit Caching
  Future<List<NodeId>> getPath(NodeId startId, NodeId endId) async {
    // Erzeuge eindeutigen Cache-Schlüssel für diese Route
    final String cacheKey = '$startId-$endId';

    // Prüfe Cache
    if (_pathCache.containsKey(cacheKey)) {
      dev.log('Verwende gecachten Pfad für $cacheKey');
      return List<NodeId>.from(_pathCache[cacheKey]!);
    }

    // Berechne neuen Pfad
    if (currentGraph == null) {
      throw Exception('Graph nicht geladen');
    }

    final List<NodeId> path = _pathGenerator.calculatePath((
      startId,
      endId,
    ), currentGraph!);

    // Cache aktualisieren
    _pathCache[cacheKey] = List<NodeId>.from(path);

    return path;
  }

  /// Generiert Routensegmente aus einem Pfad mit Caching
  Future<List<RouteSegment>> getRouteSegments(
    NodeId startId,
    NodeId endId,
  ) async {
    // Erzeuge eindeutigen Cache-Schlüssel für diese Route
    final String cacheKey = '$startId-$endId';

    // Prüfe Cache
    if (_segmentCache.containsKey(cacheKey)) {
      dev.log('Verwende gecachte Segmente für $cacheKey');
      return List<RouteSegment>.from(_segmentCache[cacheKey]!);
    }

    // Berechne neuen Pfad und konvertiere zu Segmenten
    final List<NodeId> path = await getPath(startId, endId);

    if (path.isEmpty) {
      return [];
    }

    final List<RouteSegment> segments = _segmentGenerator.convertPath(
      path,
      currentGraph!,
    );

    // Cache aktualisieren
    _segmentCache[cacheKey] = List<RouteSegment>.from(segments);

    return segments;
  }

  /// Generiert Anweisungen aus Routensegmenten
  List<String> getInstructionsFromSegments(List<RouteSegment> segments) {
    if (segments.isEmpty) {
      return [];
    }

    return _instructionGenerator.generateInstructions(segments);
  }

  /// Kombinierte Methode für den gesamten Prozess
  Future<List<String>> getNavigationInstructions(
    NodeId startId,
    NodeId endId,
  ) async {
    final segments = await getRouteSegments(startId, endId);
    return getInstructionsFromSegments(segments);
  }

  /// Findet den nächsten Punkt vom angegebenen Typ
  Future<String> findNearestPointOfInterest(
    NodeId startId,
    PointOfInterestType type,
  ) async {
    if (currentGraph == null) {
      throw Exception('Graph nicht geladen');
    }

    switch (type) {
      case PointOfInterestType.toilet:
        return currentGraph!.findNearestBathroomId(startId);
      case PointOfInterestType.exit:
        return currentGraph!.findNearestEmergencyExitId(startId);
      case PointOfInterestType.canteen:
        // Implementiere diese Methode im CampusGraph
        return currentGraph!.findNearestCanteenId(startId);
    }
  }

  /// Löscht alle Caches
  void clearCache() {
    _pathCache.clear();
    _segmentCache.clear();
    _nameToIdCache.clear();
    dev.log('Alle Caches gelöscht');
  }

  void setCacheEnabled(bool enabled) {
    // Nicht implementiert
  }

  Map<String, dynamic> getCacheStats() {
    return {};
  }

  Map<String, dynamic> inspectEncryptedCache() {
    return {};
  }

  void printCache() {
    dev.log('Cache-Statistik:');
  }

  Map<String, dynamic> validateAllRoutes() {
    return {};
  }

  /// Prüft, ob ein Graph geladen ist
  bool get hasGraph => currentGraph != null;

  /// Gibt Informationen über die geladenen Dateien zurück
  List<String> getLoadedFiles() {
    return List.from(_loadedFiles);
  }

  /// Löscht die Caches und erzwingt das Neuladen des Graphen
  Future<void> reloadGraph(String assetBasePath) async {
    clearCache();
    _loadedFiles.clear();
    currentGraph = null;
    await loadGraph(assetBasePath);
  }
}
