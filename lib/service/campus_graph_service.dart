import 'dart:convert';
import 'dart:developer' show log;
import 'package:way_to_class/constants/types.dart';
import 'package:way_to_class/core/models/campus_graph.dart';
import 'package:way_to_class/core/models/node.dart';
import 'package:way_to_class/core/utils/load.dart';

/// Service für das Laden, Parsen und Verwalten des Campus-Graphen
class CampusGraphService {
  CampusGraph? _graph;

  /// Cache für Node-Namen zu IDs für schnellere Suche
  final Map<String, NodeId> _nameToIdCache = {};

  /// Initialisiert oder aktualisiert den Graphen aus einer Asset-Datei
  Future<CampusGraph> loadGraph(String assetPath) async {
    try {
      final String jsonStr = await loadAsset(assetPath);
      final Map<NodeId, Node> nodes = _parseNodes(jsonStr);
      _graph = CampusGraph(nodes);
      _updateNameCache(nodes);
      return _graph!;
    } catch (e) {
      log('Fehler beim Laden des Graphen: $e');
      // Leeren Graphen zurückgeben als Fallback
      _graph = CampusGraph({});
      return _graph!;
    }
  }

  /// Parst JSON-Daten in eine Map von Knoten
  Map<NodeId, Node> _parseNodes(String jsonStr) {
    final Map<String, dynamic> json = jsonDecode(jsonStr);
    final Map<NodeId, Node> nodes = {};

    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        nodes[key] = Node.fromJson(key, value);
      }
    });

    return nodes;
  }

  /// Aktualisiert den Namen-zu-ID-Cache
  void _updateNameCache(Map<NodeId, Node> nodes) {
    _nameToIdCache.clear();
    for (var node in nodes.values) {
      if (node.name.isNotEmpty) {
        _nameToIdCache[node.name] = node.id;
      }
    }
  }

  /// Holt einen Knoten anhand seines Namens, mit Cache-Nutzung
  NodeId? getNodeIdByName(String name) {
    // Zuerst im Cache nachsehen
    if (_nameToIdCache.containsKey(name)) {
      return _nameToIdCache[name];
    }

    // Falls nicht im Cache, im Graphen suchen
    final nodeId = _graph?.getNodeIdByName(name);

    // Wenn gefunden, zum Cache hinzufügen
    if (nodeId != null) {
      _nameToIdCache[name] = nodeId;
    }

    return nodeId;
  }

  /// Gibt den aktuellen Graphen zurück oder null, wenn keiner geladen ist
  CampusGraph? get currentGraph => _graph;

  /// Prüft, ob ein Graph geladen ist
  bool get hasGraph => _graph != null;
}
