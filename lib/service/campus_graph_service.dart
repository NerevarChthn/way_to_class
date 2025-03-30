import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:way_to_class/service/security/security_manager.dart';

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

  /// Cache für Routensegmente
  final Map<String, String> _routeSegmentsCache = {};

  /// SharedPreferences Key für gespeicherte Routen
  static const String _prefsKeyRouteCache = 'route_segments_cache';

  /// Toggle für Cache-Nutzung
  bool _isCacheEnabled = true;

  /// Cache-Hits und Misses für Statistiken
  int _cacheHits = 0;
  int _cacheMisses = 0;

  /// Initialisiert den Service und lädt den Routen-Cache aus den SharedPreferences
  Future<void> initialize() async {
    await _loadCacheFromPrefs();
  }

  /// Aktiviert oder deaktiviert den Cache
  void setCacheEnabled(bool enabled) {
    _isCacheEnabled = enabled;
    dev.log('Cache ${enabled ? "aktiviert" : "deaktiviert"}');
  }

  /// Gibt Statistiken über den Cache zurück
  Future<Map<String, dynamic>> getCacheStatistics() async {
    try {
      final entries = <Map<String, dynamic>>[];
      int totalSize = 0;

      // Cache-Einträge analysieren
      _routeSegmentsCache.forEach((key, encryptedValue) {
        try {
          final size = encryptedValue.length;
          totalSize += size;

          // Vorschau erstellen (entschlüsselt und gekürzt)
          String preview = "Nicht lesbar";
          try {
            final decrypted = SecurityManager.decryptData(encryptedValue);
            preview =
                decrypted.length > 200
                    ? '${decrypted.substring(0, 200)}...'
                    : decrypted;
          } catch (e) {
            dev.log('Fehler beim Entschlüsseln der Vorschau: $e');
          }

          entries.add({
            'key': key,
            'size': size,
            'timestamp':
                DateTime.now().millisecondsSinceEpoch, // Als Platzhalter
            'preview': preview,
          });
        } catch (e) {
          dev.log('Fehler beim Analysieren eines Cache-Eintrags: $e');
        }
      });

      return {
        'entries': entries,
        'hits': _cacheHits,
        'misses': _cacheMisses,
        'size': totalSize,
      };
    } catch (e) {
      dev.log('Fehler bei der Cache-Analyse: $e');
      return {'error': e.toString()};
    }
  }

  /// Testet die Verschlüsselung mit einem Text
  Future<Map<String, String>> testEncryption(String text) async {
    try {
      // Verschlüsseln
      final encrypted = SecurityManager.encryptData(text);

      // Entschlüsseln
      final decrypted = SecurityManager.decryptData(encrypted);

      return {'encrypted': encrypted, 'decrypted': decrypted};
    } catch (e) {
      dev.log('Fehler beim Verschlüsselungstest: $e');
      throw Exception('Fehler bei der Ver-/Entschlüsselung: $e');
    }
  }

  /// Validiert alle möglichen Routen im Graphen (Stream für UI-Updates)
  Stream<Map<String, dynamic>> validateRoutes(int maxRoutes) async* {
    if (currentGraph == null) {
      throw Exception('Graph nicht geladen');
    }

    final nodeIds = currentGraph!.allNodeIds; // Use the official getter
    final total = nodeIds.length * nodeIds.length;
    int tested = 0;
    int failed = 0;

    // Limit the number of routes to test to avoid performance issues
    final limitedTotal = total > maxRoutes ? maxRoutes : total;

    for (int i = 0; i < nodeIds.length && tested < limitedTotal; i++) {
      final startId = nodeIds[i];

      for (int j = 0; j < nodeIds.length && tested < limitedTotal; j++) {
        if (i == j) continue; // Skip same source and destination

        final targetId = nodeIds[j];
        tested++;

        try {
          // Try to find a path
          final segments = getRouteSegments(startId, targetId, useCache: false);

          if (segments.isEmpty) {
            failed++;
            yield {
              'total': limitedTotal,
              'tested': tested,
              'failed': failed,
              'result': {
                'startId': startId,
                'targetId': targetId,
                'success': false,
                'error': 'Kein Pfad gefunden',
                'path': [],
              },
            };
          } else {
            // Extract nodeIds from segments to show the path
            final path = <String>[];
            for (final segment in segments) {
              if (segment.nodes.isNotEmpty) {
                // Use nodes instead of nodeIds
                path.addAll(segment.nodes);
              }
            }

            yield {
              'total': limitedTotal,
              'tested': tested,
              'failed': failed,
              'result': {
                'startId': startId,
                'targetId': targetId,
                'success': true,
                'path': path.toSet().toList(), // Remove duplicates
              },
            };
          }
        } catch (e) {
          failed++;
          yield {
            'total': limitedTotal,
            'tested': tested,
            'failed': failed,
            'result': {
              'startId': startId,
              'targetId': targetId,
              'success': false,
              'error': e.toString(),
              'path': [],
            },
          };
        }

        // Small delay to allow UI updates
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
  }

  /// Lädt den Cache aus den SharedPreferences
  Future<void> _loadCacheFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_prefsKeyRouteCache);

      if (cachedData != null && cachedData.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(cachedData);

        // Konvertiere in ein String-zu-String Map
        decoded.forEach((key, value) {
          if (value is String) {
            _routeSegmentsCache[key] = value;
          }
        });

        dev.log(
          '${_routeSegmentsCache.length} Route(n) aus SharedPreferences geladen',
        );
      } else {
        dev.log('Kein Route-Cache in SharedPreferences gefunden');
      }
    } catch (e) {
      dev.log('Fehler beim Laden des Caches aus SharedPreferences: $e');
    }
  }

  /// Speichert den Cache in den SharedPreferences
  Future<void> _saveCacheToPrefs() async {
    try {
      if (_routeSegmentsCache.isEmpty) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(_routeSegmentsCache);
      await prefs.setString(_prefsKeyRouteCache, jsonData);
      dev.log(
        '${_routeSegmentsCache.length} Route(n) in SharedPreferences gespeichert',
      );
    } catch (e) {
      dev.log('Fehler beim Speichern des Caches in SharedPreferences: $e');
    }
  }

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

    final List<NodeId> path = _pathGenerator.calculatePath(
      (startId, endId),
      currentGraph!,
      visualize: false,
    );

    dev.log('Pfad gefunden mit ${path.length} Knoten: ${path.join(" -> ")}');
    return path;
  }

  /// Generiert Routensegmente aus einem Pfad mit optionalem Caching
  List<RouteSegment> getRouteSegments(
    NodeId startId,
    NodeId endId, {
    bool useCache = true,
  }) {
    dev.log(
      'Generiere Routensegmente von $startId zu $endId (Cache: $useCache)',
    );

    // Erstelle einen Cache-Key
    final String cacheKey = '${startId}_$endId';

    // Prüfe Cache, wenn Caching aktiviert ist
    if (_isCacheEnabled && useCache) {
      final cachedSegments = _getSegmentsFromCache(cacheKey);
      if (cachedSegments.isNotEmpty) {
        _cacheHits++; // Zähle Cache-Treffer
        dev.log('Routensegmente aus Cache geladen für $startId zu $endId');
        return cachedSegments;
      }
    }

    // Cache-Miss oder Cache deaktiviert
    _cacheMisses++; // Zähle Cache-Fehlschläge

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

    // Im Cache speichern, wenn Caching aktiviert ist
    if (_isCacheEnabled && useCache && segments.isNotEmpty) {
      _storeSegmentsInCache(cacheKey, segments);
      // Speichere den aktuellen Cache in SharedPreferences
      _saveCacheToPrefs();
    }

    return segments;
  }

  /// Holt Routensegmente aus dem Cache
  List<RouteSegment> _getSegmentsFromCache(String cacheKey) {
    try {
      if (_routeSegmentsCache.containsKey(cacheKey)) {
        // Daten aus dem Cache entschlüsseln
        final String encryptedData = _routeSegmentsCache[cacheKey]!;
        final String segmentsJson = SecurityManager.decryptData(encryptedData);

        // JSON zu RouteSegment-Liste konvertieren
        final List<dynamic> decoded = jsonDecode(segmentsJson);
        final List<RouteSegment> segments =
            decoded.map((item) => RouteSegment.fromJson(item)).toList();

        return segments;
      }
    } catch (e) {
      dev.log('Fehler beim Laden aus Cache: $e');
    }

    return [];
  }

  /// Speichert Routensegmente im Cache
  Future<void> _storeSegmentsInCache(
    String cacheKey,
    List<RouteSegment> segments,
  ) async {
    try {
      // RouteSegment-Liste zu JSON konvertieren
      final List<Map<String, dynamic>> segmentMaps =
          segments.map((segment) => segment.toJson()).toList();
      final String segmentsJson = jsonEncode(segmentMaps);

      // Daten für den Cache verschlüsseln
      final String encryptedData = SecurityManager.encryptData(segmentsJson);
      _routeSegmentsCache[cacheKey] = encryptedData;

      dev.log('Routensegmente im Cache gespeichert für Schlüssel: $cacheKey');
    } catch (e) {
      dev.log('Fehler beim Speichern im Cache: $e');
    }
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

  /// Kombinierte Methode für den gesamten Prozess mit optionalem Caching
  Future<List<String>> getNavigationInstructions(
    NodeId startId,
    NodeId endId, {
    bool useCache = false,
  }) async {
    dev.log(
      'Generiere komplette Navigationsanweisungen von $startId zu $endId (Cache: $useCache)',
    );
    final segments = getRouteSegments(startId, endId, useCache: useCache);
    return getInstructionsFromSegments(segments);
  }

  /// Leert den Cache für Routensegmente
  Future<void> clearRouteCache() async {
    _routeSegmentsCache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    dev.log('Routensegmente-Cache geleert');

    try {
      // Auch aus SharedPreferences entfernen
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyRouteCache);
      dev.log('Routen-Cache aus SharedPreferences entfernt');
    } catch (e) {
      dev.log('Fehler beim Löschen des Caches aus SharedPreferences: $e');
    }
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
    await clearRouteCache();
    currentGraph = null;
    await loadGraph(assetBasePath);
  }
}
