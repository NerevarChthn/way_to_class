import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:developer' show log;
import 'dart:math' show min, pow, sqrt;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:way_to_class/core/components/navigation.dart';
import 'package:way_to_class/core/components/node.dart';
import 'package:way_to_class/core/components/route_segment.dart';
import 'package:way_to_class/service/security/security_manager.dart';
import 'package:way_to_class/utils/load.dart';

class Graph {
  final Map<String, Node> nodeMap;

  // Behalte wichtigen Pfad-Cache für Rückwege und häufige Strecken
  Map<String, List<String>> _pathCache = {};

  // Ersetze den Text-Cache durch einen strukturierten Cache
  Map<String, List<RouteSegment>> _routeStructureCache = {};

  final Map<String, String> nameToIdCache = {};

  int _cacheHits = 0;
  int _cacheMisses = 0;
  bool _enableCache = true;
  static const int _maxCacheSize = 200;

  static Future<Graph> load(String assetPath) async {
    final String jsonData = await loadAsset(assetPath);
    return parseGraph(jsonData);
  }

  Graph(this.nodeMap) {
    _loadCacheFromDisk(); // Lade den Cache beim Erstellen des Graphen
  }

  String? getNodeIdByName(String name) {
    if (nameToIdCache.containsKey(name)) {
      return nameToIdCache[name];
    }

    if (nodeMap.containsKey(name)) {
      return name;
    }

    for (var entry in nodeMap.entries) {
      if (entry.value.name == name) {
        nameToIdCache[name] = entry.key;
        return entry.key;
      }
    }

    return null;
  }

  // Ersetzte Methode zum Holen von Navigationsinstruktionen
  Future<List<String>> getNavigationInstructions(
    String startId,
    String endId,
  ) async {
    final navHelper = NavigationHelper();
    if (!_enableCache) {
      // Wenn Cache deaktiviert ist, berechne alles frisch
      final List<String> path = _calculatePath(startId, endId);
      if (path.length <= 1) return [];
      return navHelper.generateNavigationInstructions(this, path);
    }

    // Nur cachen, wenn Start und Ziel keine Flure sind
    final bool shouldCache = _shouldCachePath(startId, endId);

    // Cache-Key erstellen
    final String cacheKey = "$startId-$endId";
    final String reverseCacheKey = "$endId-$startId";

    // Prüfe, ob die Routenstruktur bereits im Cache ist
    if (shouldCache && _routeStructureCache.containsKey(cacheKey)) {
      _cacheHits++;
      log('Struktur-Cache-Hit für $startId nach $endId (Hits: $_cacheHits)');

      // Generiere für jeden Aufruf neue Texte aus der Struktur
      final List<RouteSegment> cachedStructure =
          _routeStructureCache[cacheKey]!;
      return cachedStructure.map((segment) => segment.generateText()).toList();
    }

    _cacheMisses++;

    // Pfad berechnen - zuerst im Cache suchen, falls das nicht klappt neu berechnen
    List<String> path;

    if (_pathCache.containsKey(cacheKey)) {
      // Pfad aus Cache verwenden
      path = List.from(_pathCache[cacheKey]!);
      log('Pfad-Cache-Hit für $startId nach $endId');
    } else if (_pathCache.containsKey(reverseCacheKey)) {
      // Rückweg ist im Cache - einfach umdrehen
      path = List.from(_pathCache[reverseCacheKey]!.reversed);
      log('Rückweg-Cache-Hit für $startId nach $endId');
    } else {
      // Komplett neuen Pfad berechnen
      path = _calculatePath(startId, endId);

      // Pfad im Cache speichern, wenn es kein Flur ist
      if (shouldCache && path.length > 1) {
        _pathCache[reverseCacheKey] = List.from(path.reversed);
        log('Wege im Cache gespeichert: $cacheKey und $reverseCacheKey');
      }
    }

    if (path.length <= 1) return [];

    // Anweisungen generieren - jetzt als strukturierte Segmente
    final List<RouteSegment> routeSegments = navHelper.generateRouteStructure(
      this,
      path,
    );

    // Strukturierte Anweisungen im Cache speichern
    if (shouldCache) {
      _routeStructureCache[cacheKey] = List.from(routeSegments);
      log('Neue Routenstruktur im Cache gespeichert: $cacheKey');
      if (_pathCache.containsKey(cacheKey)) {
        // Pfad-Cache löschen, wenn er nicht mehr benötigt wird
        _pathCache.remove(cacheKey);
        log('Pfad-Cache für $cacheKey gelöscht');
      }
    }

    // Wandle für den aktuellen Aufruf die Segmente in Text um
    final List<String> instructions =
        routeSegments
            .map((segment) => segment.generateTextWithErrorHandling())
            .toList();

    _saveCacheToDisk(); // Speichere den Cache nach jedem Aufruf

    return instructions;
  }

  Future<void> _saveCacheToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Begrenze die Größe des zu speichernden Cache
      if (_routeStructureCache.length > _maxCacheSize) {
        _limitCacheSize(_maxCacheSize);
      }

      // Bereite die Daten vor
      final Map<String, List<Map<String, dynamic>>> jsonStructureCache = {};
      _routeStructureCache.forEach((key, segments) {
        jsonStructureCache[key] = segments.map((s) => s.toJson()).toList();
      });

      final String jsonCache = jsonEncode(jsonStructureCache);

      // Verschlüssele den Cache
      final encryptedCache = await SecurityManager.encryptData(jsonCache);
      await prefs.setString('route_structure_cache_encrypted', encryptedCache);

      // Speichere den Pfad-Cache separat (weniger Priorität, aber nützlich)
      final String jsonPathCache = jsonEncode(_pathCache);
      final encryptedPathCache = await SecurityManager.encryptData(
        jsonPathCache,
      );
      await prefs.setString('path_cache_encrypted', encryptedPathCache);

      // Statistik
      await prefs.setInt('cache_hits', _cacheHits);
      await prefs.setInt('cache_misses', _cacheMisses);

      log(
        'Verschlüsselter Cache gespeichert: ${_routeStructureCache.length} Routenstrukturen, ${_pathCache.length} Pfade',
      );
    } catch (e) {
      log('Fehler beim Speichern des verschlüsselten Cache: $e');
    }
  }

  Future<void> _loadCacheFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Lade Strukturen-Cache
      if (prefs.containsKey('route_structure_cache_encrypted')) {
        final encryptedCache =
            prefs.getString('route_structure_cache_encrypted')!;

        // Entschlüssele den Cache
        final decryptedJson = await SecurityManager.decryptData(encryptedCache);

        // Parse JSON
        final Map<String, dynamic> storedData = jsonDecode(decryptedJson);

        storedData.forEach((key, value) {
          if (value is List) {
            _routeStructureCache[key] =
                (value)
                    .map(
                      (item) =>
                          RouteSegment.fromJson(item as Map<String, dynamic>),
                    )
                    .toList();
          }
        });
      }

      // Lade Pfad-Cache
      if (prefs.containsKey('path_cache_encrypted')) {
        final encryptedPathCache = prefs.getString('path_cache_encrypted')!;

        // Entschlüssele den Pfad-Cache
        final decryptedPathJson = await SecurityManager.decryptData(
          encryptedPathCache,
        );

        // Parse JSON
        final Map<String, dynamic> storedData = jsonDecode(decryptedPathJson);

        storedData.forEach((key, value) {
          if (value is List) {
            _pathCache[key] = List<String>.from(value);
          }
        });
      }

      _cacheHits = prefs.getInt('cache_hits') ?? 0;
      _cacheMisses = prefs.getInt('cache_misses') ?? 0;

      log(
        'Verschlüsselter Cache geladen: ${_routeStructureCache.length} Routenstrukturen, ${_pathCache.length} Pfade',
      );
    } catch (e) {
      log('Fehler beim Laden des verschlüsselten Cache: $e');
      _routeStructureCache = {};
      _pathCache = {};
    }
  }

  // Begrenzt die Cache-Größe auf maxSize Einträge
  void _limitCacheSize(int maxSize) {
    // Begrenze Structure-Cache
    if (_routeStructureCache.length > maxSize) {
      final List<String> keysToRemove = _routeStructureCache.keys
          .toList()
          .sublist(0, _routeStructureCache.length - maxSize);
      for (var key in keysToRemove) {
        _routeStructureCache.remove(key);
      }
    }

    // Begrenze Path-Cache (wie bisher)
    final int maxPathCacheSize = maxSize * 2;
    if (_pathCache.length > maxPathCacheSize) {
      final List<String> keysToRemove = _pathCache.keys.toList().sublist(
        0,
        _pathCache.length - maxPathCacheSize,
      );
      for (var key in keysToRemove) {
        _pathCache.remove(key);
      }
    }
  }

  Future<void> clearCache() async {
    _routeStructureCache.clear();
    _pathCache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;

    // Auch auf der Festplatte löschen
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('route_structure_cache_encrypted');
      await prefs.remove('path_cache_encrypted');
      await prefs.remove('cache_hits');
      await prefs.remove('cache_misses');
      log('Verschlüsselter Cache gelöscht');
    } catch (e) {
      log('Fehler beim Löschen des Cache: $e');
    }
  }

  // In der Graph-Klasse
  // Verbesserte Methode zur Cache-Statistikerfassung
  Map<String, dynamic> getCacheStats() {
    return {
      'routeStructureCacheSize': _routeStructureCache.length,
      'pathCacheSize': _pathCache.length,
      'hits': _cacheHits,
      'misses': _cacheMisses,
      'hitRate': _cacheHits / (_cacheHits + _cacheMisses + 0.0001),
      'enabled': _enableCache,
      'estructureExamples':
          _routeStructureCache.isNotEmpty
              ? _routeStructureCache.keys.take(3).toList()
              : [],
      'pathExamples':
          _pathCache.isNotEmpty ? _pathCache.keys.take(3).toList() : [],
    };
  }

  Future<void> debugCacheItem(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('route_structure_cache_encrypted')) {
        final encryptedCache =
            prefs.getString('route_structure_cache_encrypted')!;
        final decryptedJson = await SecurityManager.decryptData(encryptedCache);
        final Map<String, dynamic> data = jsonDecode(decryptedJson);

        if (data.containsKey(cacheKey)) {
          log('Cache-Eintrag gefunden für $cacheKey');
          final segments = data[cacheKey];
          log('Gesamtanzahl Segmente: ${segments.length}');

          log('Segmente im Detail:');
          for (int i = 0; i < segments.length; i++) {
            final segment = segments[i];
            final type = segment['type'];
            final segmentData = segment['data'] as Map<String, dynamic>;

            log('  Segment ${i + 1}/${segments.length}: $type');

            // Geordnete Darstellung der Segment-Eigenschaften
            final orderedData = <String, dynamic>{};

            // Wichtigste Eigenschaften zuerst anzeigen
            final keyOrder = [
              'roomId',
              'nodeId',
              'targetId',
              'direction',
              'steps',
              'floors',
              'position',
              'nodeType',
              'targetType',
              'buildingName',
              'floorNumber',
            ];

            // Erst die wichtigen Schlüssel in der festgelegten Reihenfolge
            for (var key in keyOrder) {
              if (segmentData.containsKey(key)) {
                orderedData[key] = segmentData[key];
              }
            }

            // Dann alle anderen Schlüssel alphabetisch sortiert
            final remainingKeys =
                segmentData.keys
                    .where((key) => !keyOrder.contains(key))
                    .toList()
                  ..sort();

            for (var key in remainingKeys) {
              orderedData[key] = segmentData[key];
            }

            // Ausgabe der Daten
            orderedData.forEach((key, value) {
              log('    - $key: $value');
            });
          }
        } else {
          log('Kein Cache-Eintrag für $cacheKey gefunden.');
          log('Verfügbare Cache-Schlüssel:');
          for (var key in data.keys) {
            log('  - $key (${(data[key] as List).length} Segmente)');
          }
        }
      } else {
        log('Kein verschlüsselter Cache gefunden.');
      }
    } catch (e) {
      log('Debug-Fehler: $e');
    }
  }

  // Verbesserte Debug-Methode für den Cache
  void printCache() {
    log('--- CACHE-INHALT ÜBERSICHT ---');
    log('Struktur-Cache: ${_routeStructureCache.length} Einträge');
    log('Pfad-Cache: ${_pathCache.length} Einträge');
    log('Cache-Hits: $_cacheHits | Misses: $_cacheMisses');

    // Ausführlichere Informationen für jeden Cache-Eintrag
    if (_routeStructureCache.isNotEmpty) {
      log('Struktur-Cache Details:');
      for (var key in _routeStructureCache.keys) {
        final segments = _routeStructureCache[key]!;
        log('  $key: ${segments.length} Segmente');

        // Zeige die Segmenttypen in kompakter Form
        final segmentTypes =
            segments
                .map((s) => s.segmentType.toString().split('.').last)
                .toList();
        log('    Segmenttypen: ${segmentTypes.join(', ')}');

        // Zeige erstes und letztes Segment detaillierter
        if (segments.isNotEmpty) {
          log('    Erstes Segment (${segments.first.segmentType}):');
          _printSegmentDetails(segments.first.data);

          if (segments.length > 1) {
            log('    Letztes Segment (${segments.last.segmentType}):');
            _printSegmentDetails(segments.last.data);
          }
        }
      }
    } else {
      log('Struktur-Cache ist leer.');
    }

    if (_pathCache.isNotEmpty) {
      log('Pfad-Cache Details:');
      for (var key in _pathCache.keys) {
        final path = _pathCache[key]!;
        log('  $key: ${path.length} Knoten');

        // Zeige Start, Ziel und einige Zwischenpunkte
        if (path.length > 1) {
          if (path.length <= 5) {
            // Für kurze Pfade alle Knoten anzeigen
            log('    Kompletter Pfad: ${path.join(' → ')}');
          } else {
            // Für längere Pfade Start, Ziel und einige Zwischenpunkte
            final middleNodes =
                path.length > 6
                    ? [path[1], '...', path[path.length - 2]]
                    : path.sublist(1, path.length - 1);

            log(
              '    Start: ${path.first} → ${middleNodes.join(' → ')} → Ziel: ${path.last}',
            );
          }
        }
      }
    } else {
      log('Pfad-Cache ist leer.');
    }

    log('----------------------------');
  }

  // Hilfsmethode zum formatieren der Segment-Details
  void _printSegmentDetails(Map<String, dynamic> data) {
    // Wichtigste Eigenschaften zuerst anzeigen
    final keyOrder = [
      'roomId',
      'nodeId',
      'targetId',
      'direction',
      'steps',
      'floors',
      'position',
      'nodeType',
      'targetType',
      'buildingName',
      'floorNumber',
    ];

    // Erst die wichtigen Schlüssel in der festgelegten Reihenfolge
    for (var key in keyOrder) {
      if (data.containsKey(key)) {
        log('      - $key: ${data[key]}');
      }
    }

    // Zeige die Anzahl weiterer Eigenschaften an
    final remainingKeys =
        data.keys.where((key) => !keyOrder.contains(key)).toList();
    if (remainingKeys.isNotEmpty) {
      log('      - (${remainingKeys.length} weitere Eigenschaften)');
    }
  }

  // Verbesserte Methode zur Inspektion des verschlüsselten Cache
  Future<Map<String, dynamic>> inspectEncryptedCache() async {
    final results = <String, dynamic>{};

    try {
      final prefs = await SharedPreferences.getInstance();

      // Alle Schlüssel auflisten
      final keys = prefs.getKeys();
      results['allKeys'] = keys.toList();

      // Verschlüsselte Daten abrufen
      final String? encryptedStructureCache = prefs.getString(
        'route_structure_cache_encrypted',
      );
      final String? encryptedPathCache = prefs.getString(
        'path_cache_encrypted',
      );

      log('--- VERSCHLÜSSELTER CACHE INSPEKTION ---');

      if (encryptedStructureCache != null) {
        results['hasStructureCache'] = true;
        results['structureCacheLength'] = encryptedStructureCache.length;
        results['structureCacheFormat'] =
            encryptedStructureCache.contains(':') ? 'Valid IV:Data' : 'Invalid';

        log(
          'Strukturdaten (verschlüsselt): ${encryptedStructureCache.substring(0, min(100, encryptedStructureCache.length))}...',
        );
        log(
          'Länge der verschlüsselten Strukturdaten: ${encryptedStructureCache.length} Zeichen',
        );

        // Prüfe, ob der Text tatsächlich verschlüsselt aussieht
        if (encryptedStructureCache.contains(':')) {
          log('Format entspricht dem erwarteten IV:Daten Format ✓');

          // Versuch der Entschlüsselung zum Testen
          try {
            final decrypted = await SecurityManager.decryptData(
              encryptedStructureCache,
            );
            final preview =
                decrypted.length > 100
                    ? '${decrypted.substring(0, 100)}...'
                    : decrypted;
            log('Entschlüsselung erfolgreich! Vorschau: $preview');
            results['decryptionSuccess'] = true;
            results['decryptedPreview'] = preview;

            // Prüfe, ob die entschlüsselten Daten valides JSON sind
            try {
              final parsed = jsonDecode(decrypted);
              final int entryCount = parsed is Map ? parsed.length : 0;
              log('JSON-Parsing erfolgreich. $entryCount Einträge gefunden.');
              results['jsonValid'] = true;
              results['jsonEntryCount'] = entryCount;
            } catch (e) {
              log('Fehler beim JSON-Parsing: $e');
              results['jsonValid'] = false;
              results['jsonError'] = e.toString();
            }
          } catch (e) {
            log('Fehler bei der Entschlüsselung: $e');
            results['decryptionSuccess'] = false;
            results['decryptionError'] = e.toString();
          }
        } else {
          log('WARNUNG: Unerwartetes Datenformat! Sollte "IV:Daten" sein.');
          results['structureCacheFormatWarning'] = true;
        }
      } else {
        log('Keine verschlüsselten Strukturdaten gefunden.');
        results['hasStructureCache'] = false;
      }

      if (encryptedPathCache != null) {
        results['hasPathCache'] = true;
        results['pathCacheLength'] = encryptedPathCache.length;
        log(
          'Pfaddaten (verschlüsselt): ${encryptedPathCache.substring(0, min(100, encryptedPathCache.length))}...',
        );

        // Optional: Auch Pfad-Cache entschlüsseln und überprüfen
        try {
          final decrypted = await SecurityManager.decryptData(
            encryptedPathCache,
          );
          final int entryCount =
              jsonDecode(decrypted) is Map ? jsonDecode(decrypted).length : 0;
          log('Pfad-Cache entschlüsselt. $entryCount Einträge gefunden.');
          results['pathDecryptionSuccess'] = true;
          results['pathEntryCount'] = entryCount;
        } catch (e) {
          log('Fehler bei der Pfad-Cache Entschlüsselung: $e');
          results['pathDecryptionSuccess'] = false;
        }
      } else {
        log('Keine verschlüsselten Pfaddaten gefunden.');
        results['hasPathCache'] = false;
      }

      // Statistik-Daten überprüfen
      if (prefs.containsKey('cache_hits')) {
        final int hits = prefs.getInt('cache_hits') ?? 0;
        final int misses = prefs.getInt('cache_misses') ?? 0;
        log('Cache-Statistik: $hits Hits, $misses Misses');
        results['savedHits'] = hits;
        results['savedMisses'] = misses;
      }

      log('--------------------------------------');
    } catch (e) {
      log('Fehler bei der Cache-Inspektion: $e');
      results['inspectionError'] = e.toString();
    }

    return results;
  }

  // Füge diese Funktion zur Graph-Klasse hinzu
  Future<void> analyzeAllCacheSegments(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('route_structure_cache_encrypted')) {
        final encryptedCache =
            prefs.getString('route_structure_cache_encrypted')!;
        final decryptedJson = await SecurityManager.decryptData(encryptedCache);
        final Map<String, dynamic> data = jsonDecode(decryptedJson);

        if (data.containsKey(cacheKey)) {
          log('\n=== DETAILLIERTE SEGMENTANALYSE VON $cacheKey ===');
          final segments = data[cacheKey];
          log('Gesamtanzahl Segmente: ${segments.length}');

          for (int i = 0; i < segments.length; i++) {
            final segment = segments[i];
            final type = segment['type'] as int;
            final segmentData = segment['data'] as Map<String, dynamic>;

            log('\n--- SEGMENT ${i + 1}/${segments.length}: $type ---');
            log('Typ: $type');

            // Alle Daten für dieses Segment anzeigen
            log('Segment-Daten:');
            final sortedKeys = segmentData.keys.toList()..sort();
            for (var key in sortedKeys) {
              final value = segmentData[key];
              if (value == null) {
                log('  $key: null <-- MÖGLICHES PROBLEM');
              } else {
                log('  $key: $value (${value.runtimeType})');
              }
            }

            // Versuche, Text zu generieren (mit Fehlerbehandlung)
            try {
              final routeSegment = RouteSegment.fromJson(segment);
              final generatedText = routeSegment.generateText();
              log('Generierter Text: "$generatedText"');
            } catch (e) {
              log('!!! FEHLER BEI DER TEXTGENERIERUNG: $e');
              log('!!! Dieser Segment könnte das Problem verursachen.');
            }
          }
          log('\n=== ENDE DER ANALYSE ===');
        } else {
          log('Kein Cache-Eintrag für $cacheKey gefunden.');
          log('Verfügbare Cache-Schlüssel:');
          for (var key in data.keys) {
            log('  - $key (${(data[key] as List).length} Segmente)');
          }
        }
      } else {
        log('Kein verschlüsselter Cache gefunden.');
      }
    } catch (e) {
      log('Analyse-Fehler: $e');
    }
  }

  // In der Graph-Klasse: Verbessere die validateAllRoutes-Methode
  Future<Map<String, dynamic>> validateAllRoutes() async {
    final results = <String, dynamic>{};
    final List<String> errorPaths = [];
    final List<String> errorMessages = [];
    final stopwatch = Stopwatch()..start();

    // Cache temporär deaktivieren für den Test
    final bool originalCacheSetting = _enableCache;
    _enableCache = false;

    try {
      // Alle Nodes (außer Flure) sammeln
      final List<String> relevantNodeIds =
          nodeMap.entries
              .where(
                (entry) =>
                    !(entry.value.isCorridor ||
                        entry.value.isDoor ||
                        entry.value.isStaircase),
              )
              .map((entry) => entry.key)
              .toList();

      // Statistik vorbereiten
      final int totalTests = relevantNodeIds.length * relevantNodeIds.length;
      int successCount = 0;
      int failureCount = 0;
      int skippedCount = 0;
      int noPathCount = 0; // Separate Zählung für "Kein Pfad gefunden"

      log('\n=== START ROUTENVALIDIERUNGSTEST ===');
      log(
        'Teste ${relevantNodeIds.length} Knoten, insgesamt $totalTests mögliche Verbindungen',
      );

      // Fortschritt zur Verfolgung
      int progress = 0;
      int lastProgressPercent = -1;

      // Durch alle Kombinationen iterieren
      for (final startId in relevantNodeIds) {
        for (final targetId in relevantNodeIds) {
          progress++;
          final currentPercent = (progress / totalTests * 100).floor();
          if (currentPercent > lastProgressPercent) {
            lastProgressPercent = currentPercent;
            if (currentPercent % 10 == 0) {
              log('Fortschritt: $currentPercent% ($progress von $totalTests)');
            }
          }

          // Gleichen Knoten überspringen
          if (startId == targetId) {
            skippedCount++;
            continue;
          }

          try {
            // Pfadberechnung - kann Fehler werfen
            final List<String> path = _calculatePath(startId, targetId);

            if (path.length <= 1) {
              // Wichtige Änderung: Kein Pfad ist jetzt ein FEHLER, nicht übersprungen!
              noPathCount++;
              failureCount++;
              errorPaths.add('$startId → $targetId');

              // Detailliertere Fehlermeldung
              String errorReason;
              if (nodeMap[startId]?.weights.isEmpty == true) {
                errorReason =
                    'Startknoten $startId hat keine ausgehenden Verbindungen';
              } else if (nodeMap[targetId]?.weights.isEmpty == true) {
                errorReason =
                    'Zielknoten $targetId hat keine eingehenden Verbindungen';
              } else {
                errorReason = 'Graph ist nicht vollständig verbunden';
              }

              errorMessages.add(
                'Kein Pfad zwischen $startId und $targetId gefunden: $errorReason',
              );
              continue;
            }

            // NavigationHelper direkt verwenden
            final navHelper = NavigationHelper();

            // RouteSegments erzeugen - kann Fehler werfen
            List<RouteSegment> segments;
            try {
              segments = navHelper.generateRouteStructure(this, path);
            } catch (e) {
              // Fehler bei der Segmentgenerierung
              failureCount++;
              errorPaths.add('$startId → $targetId');
              errorMessages.add(
                'Fehler bei Segmentgenerierung für $startId → $targetId: $e',
              );
              continue;
            }

            // Jeden Segment-Text erzeugen - kann Fehler werfen
            bool hasTextError = false;
            for (int i = 0; i < segments.length; i++) {
              try {
                segments[i].generateText();
              } catch (e) {
                hasTextError = true;
                failureCount++;
                errorPaths.add('$startId → $targetId');
                errorMessages.add(
                  'Fehler bei Segment ${i + 1}/${segments.length} (${segments[i].segmentType}) für $startId → $targetId: $e',
                );
                break; // Einer reicht zum Fehlschlagen
              }
            }

            // Wenn kein Fehler bei der Textgenerierung auftrat, war der Test erfolgreich
            if (!hasTextError) {
              successCount++;
            }
          } catch (e) {
            failureCount++;
            errorPaths.add('$startId → $targetId');
            errorMessages.add('Fehler bei $startId → $targetId: $e');
          }
        }
      }

      final elapsedTime = stopwatch.elapsedMilliseconds / 1000;
      final averageTimePerRoute = totalTests > 0 ? elapsedTime / totalTests : 0;
      final double successRate =
          successCount + failureCount > 0
              ? successCount / (successCount + failureCount)
              : 0;

      log('\n=== TESTRESULTATE ===');
      log('Gesamte Testdauer: ${elapsedTime.toStringAsFixed(2)} Sekunden');
      log(
        'Durchschnittliche Zeit pro Route: ${averageTimePerRoute.toStringAsFixed(2)} Sekunden',
      );
      log('Erfolgreiche Tests: $successCount');
      log('Fehlgeschlagene Tests: $failureCount');
      log('  - davon "Kein Pfad gefunden": $noPathCount'); // Neue Statistik
      log('Übersprungene Tests: $skippedCount (gleicher Start- und Endknoten)');
      log('Erfolgsrate: ${(successRate * 100).toStringAsFixed(1)}%');

      if (errorPaths.isNotEmpty) {
        // Gruppiere Fehlerarten für bessere Übersicht
        final Map<String, int> errorTypeCount = {};
        for (var message in errorMessages) {
          final String errorType =
              message.contains('Kein Pfad')
                  ? 'Kein Pfad gefunden'
                  : message.contains('Segmentgenerierung')
                  ? 'Segmentgenerierung'
                  : message.contains('Segment')
                  ? 'Textgenerierung'
                  : 'Sonstiger Fehler';

          errorTypeCount[errorType] = (errorTypeCount[errorType] ?? 0) + 1;
        }

        log('\nFEHLERTYPEN:');
        errorTypeCount.forEach((type, count) {
          log(
            '  $type: $count (${(count / failureCount * 100).toStringAsFixed(1)}%)',
          );
        });

        log('\nERSTER FEHLER: ${errorMessages.first}');
        if (errorMessages.length > 1) {
          log('LETZTER FEHLER: ${errorMessages.last}');
        }

        // Eine Auswahl der Fehlermeldungen anzeigen
        final displayCount = min(10, errorMessages.length);
        log('\nDIE ERSTEN $displayCount FEHLER:');
        for (int i = 0; i < displayCount; i++) {
          log('${i + 1}. ${errorMessages[i]}');
        }
      }

      log('=== ENDE DES ROUTENVALIDIERUNGSTESTS ===\n');

      // Ergebnisse zusammenstellen
      results['totalTests'] = totalTests;
      results['successCount'] = successCount;
      results['failureCount'] = failureCount;
      results['noPathCount'] = noPathCount;
      results['skippedCount'] = skippedCount;
      results['elapsedTime'] = elapsedTime;
      results['averageTimePerRoute'] = averageTimePerRoute;
      results['successRate'] = successRate;
      results['errorPaths'] = errorPaths;
      results['errorMessages'] = errorMessages;
    } catch (e) {
      log('Kritischer Fehler im Validierungstest: $e');
      results['criticalError'] = e.toString();
    } finally {
      // Stelle den ursprünglichen Cache-Zustand wieder her
      _enableCache = originalCacheSetting;
    }

    return results;
  }

  // Der eigentliche A*-Algorithmus (ausgelagert aus shortestPath)
  List<String> _calculatePath(String startId, String endId) {
    final Node? startNode = nodeMap[startId];
    final Node? endNode = nodeMap[endId];

    if (startNode == null || endNode == null) {
      return [];
    }

    // A* Algorithmus
    final Set<String> openSet = {startId};
    final Map<String, String?> cameFrom = {};
    final Map<String, double> gScore = {
      for (var nodeId in nodeMap.keys) nodeId: double.infinity,
    };
    gScore[startId] = 0;

    final Map<String, double> fScore = {
      for (var nodeId in nodeMap.keys) nodeId: double.infinity,
    };
    fScore[startId] = _heuristic(startNode, endNode);

    while (openSet.isNotEmpty) {
      // Finde den Knoten mit dem niedrigsten f_score im offenen Set
      String? current;
      double lowestFScore = double.infinity;

      for (var nodeId in openSet) {
        if (fScore[nodeId]! < lowestFScore) {
          lowestFScore = fScore[nodeId]!;
          current = nodeId;
        }
      }

      if (current == null) break;

      // Wenn wir das Ziel erreicht haben, rekonstruiere den Pfad
      if (current == endId) {
        return _reconstructPath(cameFrom, current);
      }

      openSet.remove(current);
      final Node? currentNode = nodeMap[current];
      if (currentNode == null) continue;

      // Betrachte alle Nachbarn des aktuellen Knotens (über die weights)
      for (var neighborId in currentNode.weights.keys) {
        final Node? neighbor = nodeMap[neighborId];
        if (neighbor == null) continue;

        // Versuche diesen Weg und berechne den gScore
        final double weight =
            currentNode.weights[neighborId] ?? double.infinity;
        final double tentativeGscore = gScore[current]! + weight;

        // Dieser Pfad ist besser? Speichere ihn
        if (tentativeGscore < gScore[neighborId]!) {
          cameFrom[neighborId] = current;
          gScore[neighborId] = tentativeGscore;
          fScore[neighborId] =
              gScore[neighborId]! + _heuristic(neighbor, endNode);

          // Falls der Nachbar noch nicht untersucht wird, füge ihn hinzu
          if (!openSet.contains(neighborId)) {
            openSet.add(neighborId);
          }
        }
      }
    }

    // Kein Pfad gefunden
    return [];
  }

  // Hilfsmethode für A*: Heuristik (Luftlinie zwischen zwei Punkten)
  double _heuristic(Node a, Node b) {
    return computeDistance(a, b);
  }

  // Pfad rekonstruieren
  List<String> _reconstructPath(Map<String, String?> cameFrom, String current) {
    final List<String> path = [current];
    while (cameFrom.containsKey(current) && cameFrom[current] != null) {
      current = cameFrom[current]!;
      path.insert(0, current);
    }
    return path;
  }

  // Distanz-Helfer-Methoden
  static double computeDistance(Node a, Node b) =>
      sqrt(pow((b.x - a.x).toDouble(), 2) + pow((b.y - a.y).toDouble(), 2));

  // Verwende die Map für schnellen Zugriff
  Node? getNodeById(String id) => nodeMap[id];

  // Factory und Lookup Methode für die neue JSON-Struktur
  static Graph parseGraph(String jsonStr) {
    final Map<String, dynamic> jsonData = jsonDecode(jsonStr);
    final Map<String, Node> nodeMap = {};

    // Iteriere direkt über die Einträge im JSON-Objekt und erstelle Nodes
    jsonData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        // Erstelle Node aus dem Schlüssel und den Daten
        nodeMap[key] = Node.fromJson(key, value);
      }
    });

    return Graph(nodeMap);
  }

  // Knoten-Finder-Methoden
  Node? findNearestRoomStairElevator(Node current) {
    // Use BFS to find the nearest node by path distance
    final Set<String> visited = {current.id};
    final List<(String, double)> queue = []; // (nodeId, distanceSoFar)

    // Add neighbors of starting node to queue
    current.weights.forEach((neighborId, weight) {
      queue.add((neighborId, weight));
    });

    final double maxDist =
        12; // Increased a bit as path distance is usually longer than direct distance
    Node? nearest;
    double nearestDistance = double.infinity;

    while (queue.isNotEmpty) {
      final (String nodeId, double distanceSoFar) = queue.removeAt(
        0,
      ); // Remove from front (FIFO)

      // Skip if already visited or if distance exceeds maximum
      if (visited.contains(nodeId) || distanceSoFar > maxDist) continue;
      visited.add(nodeId);

      // Check if this node is a valid landmark
      final Node? node = nodeMap[nodeId];
      if (node == null) continue;

      // If we found a room, staircase, or elevator, this might be our nearest node
      if (node.isRoom || node.isStaircase || node.isElevator) {
        // Found a valid landmark
        if (nearest == null || distanceSoFar < nearestDistance) {
          nearest = node;
          nearestDistance = distanceSoFar;
          // Don't return immediately - we want the closest one
        }
      }

      // Add neighbors to queue
      node.weights.forEach((neighborId, weight) {
        if (!visited.contains(neighborId)) {
          queue.add((neighborId, distanceSoFar + weight));
        }
      });
    }

    return nearest;
  }

  String findNearestBathroomId(String currentId) {
    final Node current = nodeMap[currentId]!;

    Node? nearest;
    double minDist = double.infinity;

    for (var node in nodeMap.values) {
      if (node.isToilet) {
        final double dist = computeDistance(current, node);
        if (dist < minDist) {
          minDist = dist;
          nearest = node;
        }
      }
    }

    return nearest?.id ??
        nodeMap.values
            .firstWhere(
              (n) => n.id.contains('wc_'),
              orElse: () => throw Exception('Kein Badezimmer gefunden'),
            )
            .id;
  }

  String findNearestEmergencyExitId(String currentId) {
    final Node current = nodeMap[currentId]!;
    Node? nearest;
    double minDist = double.infinity;

    for (var node in nodeMap.values) {
      if (node.id.contains('exit_') ||
          node.name.toLowerCase().contains('notausgang')) {
        final double dist = computeDistance(current, node);
        if (dist < minDist) {
          minDist = dist;
          nearest = node;
        }
      }
    }

    return nearest?.id ??
        nodeMap.values
            .firstWhere(
              (n) => n.id.contains('exit_'),
              orElse: () => throw Exception('Kein Notausgang gefunden'),
            )
            .id;
  }

  // Hilfsmethode um zu prüfen, ob ein Pfad gecached werden soll
  bool _shouldCachePath(String startId, String endId) {
    // Prüfe, ob Start oder Ziel ein Flur ist
    final bool isStartCorridor = _isCorridorNode(startId);
    final bool isEndCorridor = _isCorridorNode(endId);

    // Wir wollen nur Pfade cachen, deren Start- und Endpunkte keine Flure sind
    return !isStartCorridor && !isEndCorridor;
  }

  // Prüft, ob eine Node-ID zu einem Flur gehört
  bool _isCorridorNode(String nodeId) {
    // Prüfe den Typ, falls die Node im Graph verfügbar ist
    final Node? node = nodeMap[nodeId];
    if (node != null) {
      return node.isCorridor;
    }

    return false;
  }
}
